// ignore_for_file: prefer_initializing_formals
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../logging_service.dart';
import '../../path_service.dart';
import '../extractor/tts_archive_extractor.dart';
import '../tts_model_store.dart';
import '../tts_models.dart';

class CustomModelInspectionResult {
  const CustomModelInspectionResult({
    required this.directory,
    required this.detectedType,
    required this.suggestedDisplayName,
    required this.suggestedLanguageCode,
    required this.suggestedLanguageLabel,
    required this.onnxFiles,
    required this.hasTokens,
    required this.hasVoicesBin,
    required this.approxSizeMb,
    required this.isArchiveSource,
    this.tempArchiveDir,
  });

  final Directory directory;
  final SherpaTtsModelType detectedType;
  final String suggestedDisplayName;
  final String suggestedLanguageCode;
  final String suggestedLanguageLabel;
  final List<String> onnxFiles;
  final bool hasTokens;
  final bool hasVoicesBin;
  final double approxSizeMb;
  final bool isArchiveSource;
  final Directory? tempArchiveDir;
}

@lazySingleton
class CustomTtsModelImporterService {
  CustomTtsModelImporterService({
    required TtsArchiveExtractor archiveExtractor,
    required AppPathService pathService,
    required TtsModelStore store,
  }) : _archiveExtractor = archiveExtractor,
       _pathService = pathService,
       _store = store;

  final TtsArchiveExtractor _archiveExtractor;
  final AppPathService _pathService;
  final TtsModelStore _store;

  /// Inspects an archive file or directory to detect model type, valid files, and default metadata.
  Future<CustomModelInspectionResult> inspectSource(String sourcePath) async {
    final file = File(sourcePath);
    final dir = Directory(sourcePath);

    final bool isArchive = await file.exists();
    final bool isDir = await dir.exists();

    if (!isArchive && !isDir) {
      throw const SherpaTtsException('Selected file or folder does not exist.');
    }

    Directory targetDir;
    Directory? tempExtractDir;

    if (isArchive) {
      final tmpRoot = await _pathService.tempDirectory;
      final sessionDir = Directory(
        p.join(
          tmpRoot.path,
          'custom_tts_inspect_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await sessionDir.create(recursive: true);
      tempExtractDir = sessionDir;
      targetDir = sessionDir;

      await _archiveExtractor.extractModelArchive(
        archiveFile: file,
        destDir: sessionDir,
      );
    } else {
      targetDir = dir;
    }

    final onnxFiles = <String>[];
    bool hasTokens = false;
    bool hasVoicesBin = false;
    int totalBytes = 0;

    final entries = await targetDir.list(recursive: true).toList();
    for (final e in entries) {
      if (e is File) {
        totalBytes += await e.length();
        final baseName = p.basename(e.path).toLowerCase();
        if (baseName.endsWith('.onnx')) {
          onnxFiles.add(p.basename(e.path));
        } else if (baseName == 'tokens.txt') {
          hasTokens = true;
        } else if (baseName.endsWith('.bin') && baseName.contains('voices')) {
          hasVoicesBin = true;
        }
      }
    }

    if (!hasTokens) {
      if (tempExtractDir != null && await tempExtractDir.exists()) {
        await tempExtractDir.delete(recursive: true);
      }
      throw const SherpaTtsException(
        'Invalid model: tokens.txt was not found in the selected archive/folder.',
      );
    }

    if (onnxFiles.isEmpty) {
      if (tempExtractDir != null && await tempExtractDir.exists()) {
        await tempExtractDir.delete(recursive: true);
      }
      throw const SherpaTtsException(
        'Invalid model: No .onnx model files found in the selected archive/folder.',
      );
    }

    final rawName = p.basenameWithoutExtension(sourcePath);
    final cleanName = rawName
        .replaceAll(RegExp(r'[_\-\.]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Infer model type
    SherpaTtsModelType detectedType = SherpaTtsModelType.vits;
    if (hasVoicesBin || rawName.toLowerCase().contains('kokoro')) {
      detectedType = SherpaTtsModelType.kokoro;
    } else if (onnxFiles.length > 1 ||
        rawName.toLowerCase().contains('matcha') ||
        onnxFiles.any((f) => f.contains('vocos') || f.contains('hifigan'))) {
      detectedType = SherpaTtsModelType.matcha;
    }

    final approxMb = totalBytes / 1024 / 1024;

    return CustomModelInspectionResult(
      directory: targetDir,
      detectedType: detectedType,
      suggestedDisplayName: cleanName.isNotEmpty ? cleanName : 'Custom Voice',
      suggestedLanguageCode: 'en-US',
      suggestedLanguageLabel: 'English',
      onnxFiles: onnxFiles,
      hasTokens: hasTokens,
      hasVoicesBin: hasVoicesBin,
      approxSizeMb: double.parse(approxMb.toStringAsFixed(2)),
      isArchiveSource: isArchive,
      tempArchiveDir: tempExtractDir,
    );
  }

  /// Installs inspected files into the app's TTS models directory and persists its metadata.
  Future<SherpaTtsModelInfo> importModel({
    required CustomModelInspectionResult inspection,
    required String displayName,
    required String languageCode,
    required String languageLabel,
    SherpaTtsModelType? typeOverride,
    int speakerCount = 0,
    int sampleRate = 22050,
  }) async {
    final type = typeOverride ?? inspection.detectedType;
    final sanitizedName = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final modelId =
        'custom_${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}';

    final modelsRoot = await _pathService.getTtsModelsDirectory();
    final destDir = Directory(p.join(modelsRoot.path, modelId));
    await destDir.create(recursive: true);

    try {
      // Copy all files from inspection directory to target model dir
      final entries = await inspection.directory.list(recursive: true).toList();
      for (final e in entries) {
        if (e is File) {
          final relPath = p.relative(e.path, from: inspection.directory.path);
          final destFile = File(p.join(destDir.path, relPath));
          await destFile.parent.create(recursive: true);
          await e.copy(destFile.path);
        }
      }

      final modelInfo = SherpaTtsModelInfo(
        id: modelId,
        displayName: displayName.trim().isNotEmpty ? displayName.trim() : 'Custom Voice',
        languageCode: languageCode,
        languageLabel: languageLabel,
        type: type,
        downloadUrl: '',
        approxSizeMb: inspection.approxSizeMb,
        isMultiSpeaker: speakerCount > 1,
        speakerCount: speakerCount,
        description: 'User-imported custom model',
        sampleRateHint: type == SherpaTtsModelType.kokoro ? 24000 : sampleRate,
        isCustom: true,
        customModelPath: destDir.path,
        installedSizeBytes: (inspection.approxSizeMb * 1024 * 1024).round(),
        installedAt: DateTime.now().millisecondsSinceEpoch,
        needsEspeakData: type == SherpaTtsModelType.kokoro ||
            type == SherpaTtsModelType.matcha ||
            modelId.contains('piper'),
      );

      await _store.saveInstalledModel(modelInfo);
      return modelInfo;
    } catch (e, st) {
      logger.e('Failed to import custom TTS model $modelId', e, st);
      if (await destDir.exists()) {
        await destDir.delete(recursive: true);
      }
      throw SherpaTtsException('Failed to import custom model: $e');
    } finally {
      if (inspection.tempArchiveDir != null &&
          await inspection.tempArchiveDir!.exists()) {
        await inspection.tempArchiveDir!.delete(recursive: true);
      }
    }
  }

  /// Cancels inspection session and cleans up temporary extraction folder.
  Future<void> cleanupInspection(CustomModelInspectionResult inspection) async {
    if (inspection.tempArchiveDir != null &&
        await inspection.tempArchiveDir!.exists()) {
      await inspection.tempArchiveDir!.delete(recursive: true);
    }
  }
}
