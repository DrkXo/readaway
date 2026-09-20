// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../isolate_service.dart';
import '../../logging_service.dart';
import '../../path_service.dart';
import '../../settings_service.dart';
import '../tts_model_store.dart';
import '../tts_models.dart';
import 'sherpa_isolate_worker_service.dart';
import 'sherpa_model_catalog.dart';
import 'sherpa_tts_model_downloader.dart';

@lazySingleton
class SherpaOnnxTtsService {
  SherpaOnnxTtsService({
    required SherpaTtsModelDownloaderService downloader,
    required SherpaTtsModelCatalogService sherpaTtsModelCatalog,
    required IsolateService isolateService,
    required AppPathService pathService,
    required TtsModelStore store,
    required SettingsService settingsService,
  }) : _downloader = downloader,
       _sherpaTtsModelCatalog = sherpaTtsModelCatalog,
       _isolateService = isolateService,
       _pathService = pathService,
       _store = store,
       _settingsService = settingsService;

  final SherpaTtsModelDownloaderService _downloader;
  final SherpaTtsModelCatalogService _sherpaTtsModelCatalog;
  final IsolateService _isolateService;
  final AppPathService _pathService;
  final TtsModelStore _store;
  final SettingsService _settingsService;

  SherpaTtsModelInfo? _activeModel;
  Directory? _modelsRootDir;
  int? _sampleRate;
  int? _speakerCount;
  String? _loadedNarrationStyle;

  /// Whether the loaded model needs to be reloaded to apply changed style/noise settings.
  bool get needsModelReload {
    if (_activeModel == null) return false;
    final gvs = _settingsService.settings.globalViewSettings;
    return _loadedNarrationStyle != null &&
        _loadedNarrationStyle != gvs.ttsNarrationStyle;
  }

  int _commandId = 0;
  String _nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_commandId++}';

  bool _bindingsInitialized = false;

  Future<void> init() async {
    _modelsRootDir ??= await _resolveModelsRootDir();
  }

  /// Lazily initializes native C FFI bindings and spawns the background worker isolate on demand.
  Future<void> ensureInitialized() async {
    if (!_bindingsInitialized) {
      sherpa.initBindings();
      _bindingsInitialized = true;
    }
    _modelsRootDir ??= await _resolveModelsRootDir();
    if (_sherpaTtsModelCatalog.models.isEmpty) {
      await _sherpaTtsModelCatalog.load();
    }
    if (!_isolateService.isSpawned(sherpaTtsIsolateName)) {
      await _isolateService.spawn(
        name: sherpaTtsIsolateName,
        entryPoint: sherpaTtsIsolateEntryPoint,
      );
    }
  }

  Future<Directory> _resolveModelsRootDir() async {
    return _pathService.getTtsModelsDirectory();
  }

  /// Terminates the worker isolate and releases native ONNX model memory.
  Future<void> releaseIsolate() async {
    if (_isolateService.isSpawned(sherpaTtsIsolateName)) {
      try {
        if (_activeModel != null) {
          await _isolateService.sendCommand<bool>(sherpaTtsIsolateName, {
            'id': _nextId(),
            'type': 'unload',
          });
        }
      } catch (e) {
        logger.w('Error unloading model during releaseIsolate: $e');
      }
      await _isolateService.disposeIsolate(sherpaTtsIsolateName);
    }
    _activeModel = null;
    _loadedNarrationStyle = null;
    _sampleRate = null;
    _speakerCount = null;
  }

  @disposeMethod
  Future<void> dispose() async {
    await releaseIsolate();
  }

  List<SherpaTtsModelInfo> get availableModels => _sherpaTtsModelCatalog.models;

  Future<Directory> _modelDir(String modelId) async {
    final root = _modelsRootDir ?? await _resolveModelsRootDir();
    _modelsRootDir = root;
    return Directory(p.join(root.path, modelId));
  }

  Future<bool> isModelDownloaded(String modelId) async {
    final dir = await _modelDir(modelId);
    if (!await dir.exists()) return false;

    final model = _sherpaTtsModelCatalog.byId(modelId);
    if (model == null) return false;

    try {
      final files = await _indexModelFiles(dir);

      final bool structurallyComplete;
      switch (model.type) {
        case SherpaTtsModelType.vits:
          structurallyComplete = files.onnxPrimary != null;
          break;
        case SherpaTtsModelType.kokoro:
          structurallyComplete =
              files.onnxPrimary != null && files.voicesBin != null;
          break;
        case SherpaTtsModelType.matcha:
          structurallyComplete =
              files.onnxPrimary != null && files.onnxSecondary != null;
          break;
      }
      if (!structurallyComplete) return false;

      if (model.needsEspeakData && files.espeakDataDir == null) return false;

      return true;
    } on SherpaTtsException {
      return false;
    }
  }

  Future<List<SherpaTtsModelInfo>> getDownloadedModels() async {
    if (_sherpaTtsModelCatalog.models.isEmpty) {
      await _sherpaTtsModelCatalog.load();
    }
    await reconcilePendingDownloads();

    // Fast path: only structurally-check models the store says are
    // downloaded, instead of scanning every model directory.
    final downloadedIds = _store.loadDownloadedIds();
    final result = <SherpaTtsModelInfo>[];
    final stale = <String>[];
    for (final m in availableModels) {
      if (!downloadedIds.contains(m.id)) continue;
      if (await isModelDownloaded(m.id)) {
        result.add(m);
      } else {
        stale.add(m.id);
      }
    }

    // One-time migration: if the store has no entries but models exist on
    // disk (installs predating the store), discover and persist them.
    if (downloadedIds.isEmpty) {
      for (final m in availableModels) {
        if (await isModelDownloaded(m.id)) {
          result.add(m);
          await _store.markDownloaded(m.id);
        }
      }
    }

    // Drop stale entries so the store stays accurate.
    for (final id in stale) {
      await _store.unmarkDownloaded(id);
    }
    return result;
  }

  /// Finishes any model downloads that were interrupted after the archive
  /// transfer completed but before extraction ran (e.g. the app was killed
  /// mid-download). Scans each model directory for `.done` markers written
  /// by [SherpaTtsModelDownloaderService.ttsModelTaskFinished], then runs
  /// the checksum/extract/vocoder/espeak pipeline. Idempotent — markers are
  /// consumed once.
  Future<void> reconcilePendingDownloads() async {
    final root = _modelsRootDir ?? await _resolveModelsRootDir();
    _modelsRootDir = root;
    if (!await root.exists()) return;

    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final modelId = p.basename(entity.path);
      final model = _sherpaTtsModelCatalog.byId(modelId);
      if (model == null) continue;

      final markers = <File>[];
      await for (final e in entity.list()) {
        if (e is File && e.path.endsWith('.done')) markers.add(e);
      }
      if (markers.isEmpty) continue;

      try {
        await _downloader.reconcileModel(model, entity);
        for (final marker in markers) {
          await marker.delete();
        }
        logger.d('Reconciled interrupted TTS download for $modelId');
      } catch (e, st) {
        logger.e('Failed to reconcile TTS download for $modelId', e, st);
      }
    }
  }

  Future<void> deleteModel(String modelId) async {
    if (_activeModel?.id == modelId) {
      await _isolateService.sendCommand<bool>(sherpaTtsIsolateName, {
        'id': _nextId(),
        'type': 'unload',
      });
      _activeModel = null;
      _sampleRate = null;
      _speakerCount = null;
    }
    final dir = await _modelDir(modelId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await _store.unmarkDownloaded(modelId);
  }

  Stream<ModelDownloadProgress> downloadModel(SherpaTtsModelInfo model) async* {
    final dir = await _modelDir(model.id);
    yield* _downloader.downloadModel(model, dir);
  }

  Future<void> pauseDownload(String modelId) =>
      _downloader.pauseDownload(modelId);

  Future<void> resumeDownload(String modelId) =>
      _downloader.resumeDownload(modelId);

  Future<void> cancelDownload(String modelId) =>
      _downloader.cancelDownload(modelId);

  SherpaTtsModelInfo? get activeModel => _activeModel;
  bool get hasLoadedModel => _sampleRate != null;

  Future<void> loadModel(
    String modelId, {
    int numThreads = 2,
    bool debugLogging = false,
    double? noiseScale,
    double? noiseScaleW,
    double? lengthScale,
    double? silenceScale,
  }) async {
    await ensureInitialized();
    final model = _sherpaTtsModelCatalog.byId(modelId);
    if (model == null) {
      throw SherpaTtsException('Unknown model id: $modelId');
    }
    final dir = await _modelDir(modelId);
    if (!await dir.exists()) {
      throw SherpaTtsException('Model $modelId is not downloaded yet.');
    }

    var files = await _indexModelFiles(dir);
    if (model.needsEspeakData && files.espeakDataDir == null) {
      final rootDir = _modelsRootDir ?? await _resolveModelsRootDir();
      await _downloader.ensureSharedEspeakData(rootDir);
      files = await _indexModelFiles(dir);
    }

    final gvs = _settingsService.settings.globalViewSettings;
    final effectiveSilenceScale = silenceScale ?? gvs.ttsSilenceScale;

    // Map narration style to VITS / Piper noise parameters
    double styleNoiseScale = 0.667;
    double styleNoiseScaleW = 0.80;
    switch (gvs.ttsNarrationStyle) {
      case 'audiobook':
        styleNoiseScale = 0.33;
        styleNoiseScaleW = 0.50;
        break;
      case 'expressive':
        styleNoiseScale = 0.85;
        styleNoiseScaleW = 0.90;
        break;
      case 'balanced':
      default:
        styleNoiseScale = 0.667;
        styleNoiseScaleW = 0.80;
        break;
    }

    final effectiveNoiseScale = noiseScale ??
        (gvs.ttsNoiseScale != 0.667 ? gvs.ttsNoiseScale : styleNoiseScale);
    final effectiveNoiseScaleW = noiseScaleW ??
        (gvs.ttsNoiseScaleW != 0.80 ? gvs.ttsNoiseScaleW : styleNoiseScaleW);
    final effectiveLengthScale = lengthScale ?? gvs.ttsLengthScale;

    final message = _buildLoadModelMessage(
      model,
      files,
      numThreads: numThreads,
      debug: debugLogging,
      noiseScale: effectiveNoiseScale,
      noiseScaleW: effectiveNoiseScaleW,
      lengthScale: effectiveLengthScale,
      silenceScale: effectiveSilenceScale,
    );

    final result = await _isolateService.sendCommand<Map>(
      sherpaTtsIsolateName,
      message,
    );

    _activeModel = model;
    _loadedNarrationStyle = gvs.ttsNarrationStyle;
    _sampleRate = result['sampleRate'] as int;
    _speakerCount = result['speakerCount'] as int;
  }

  Future<_ModelFiles> _indexModelFiles(Directory dir) async {
    final onnxFiles = <String>[];
    String? tokens, voicesBin, dataDir, dictDir;

    final lexiconFiles = <String>[];
    final ruleFstFiles = <String>[];
    final ruleFarFiles = <String>[];
    final entries = await dir.list(recursive: true).toList();

    for (final e in entries) {
      final name = p.basename(e.path);
      if (e is File && name.endsWith('.onnx')) {
        onnxFiles.add(e.path);
      } else if (e is File && name == 'tokens.txt') {
        tokens = e.path;
      } else if (e is File &&
          name.startsWith('lexicon') &&
          name.endsWith('.txt')) {
        lexiconFiles.add(e.path);
      } else if (e is File && name.endsWith('.fst')) {
        ruleFstFiles.add(e.path);
      } else if (e is File && name.endsWith('.far')) {
        ruleFarFiles.add(e.path);
      } else if (e is File &&
          (name.endsWith('.bin') && name.contains('voices'))) {
        voicesBin = e.path;
      } else if (e is Directory && name.contains('espeak-ng-data')) {
        dataDir = e.path;
      } else if (e is Directory && name.contains('dict')) {
        dictDir = e.path;
      }
    }

    if (dataDir == null && _modelsRootDir != null) {
      final shared = Directory(p.join(_modelsRootDir!.path, 'espeak-ng-data'));
      if (await shared.exists()) {
        dataDir = shared.path;
      }
    }

    if (tokens == null) {
      throw SherpaTtsException(
        'tokens.txt not found in ${dir.path} — is this a valid sherpa-onnx TTS model?',
      );
    }

    lexiconFiles.sort();
    ruleFstFiles.sort();
    ruleFarFiles.sort();
    onnxFiles.sort();

    return _ModelFiles(
      onnxFiles: onnxFiles,
      tokens: tokens,
      lexicon: lexiconFiles.isEmpty ? null : lexiconFiles.join(','),
      ruleFsts: ruleFstFiles.isEmpty ? null : ruleFstFiles.join(','),
      ruleFars: ruleFarFiles.isEmpty ? null : ruleFarFiles.join(','),
      voicesBin: voicesBin,
      espeakDataDir: dataDir,
      dictDir: dictDir,
    );
  }

  Map<String, dynamic> _buildLoadModelMessage(
    SherpaTtsModelInfo model,
    _ModelFiles files, {
    required int numThreads,
    required bool debug,
    double noiseScale = 0.667,
    double noiseScaleW = 0.8,
    double lengthScale = 1.0,
    double silenceScale = 0.2,
  }) {
    final base = <String, dynamic>{
      'id': _nextId(),
      'type': 'loadModel',
      'numThreads': numThreads,
      'debug': debug,
      'tokens': files.tokens,
      'lexicon': files.lexicon ?? '',
      'ruleFsts': files.ruleFsts ?? '',
      'ruleFars': files.ruleFars ?? '',
      'silenceScale': silenceScale,
      'dataDir': files.espeakDataDir ?? '',
      'dictDir': files.dictDir ?? '',
      'noiseScale': noiseScale,
      'noiseScaleW': noiseScaleW,
      'lengthScale': lengthScale,
    };

    switch (model.type) {
      case SherpaTtsModelType.vits:
        if (files.onnxFiles.isEmpty) {
          throw SherpaTtsException(
            'No .onnx file found for VITS model ${model.id}',
          );
        }
        return {
          ...base,
          'modelType': 'vits',
          'modelPath': files.onnxFiles.first,
        };

      case SherpaTtsModelType.kokoro:
        if (files.onnxFiles.isEmpty || files.voicesBin == null) {
          throw SherpaTtsException(
            'Kokoro model ${model.id} needs both a .onnx file and a voices .bin file.',
          );
        }

        final isMultiLingual = model.languageCode == 'multi';
        if (isMultiLingual &&
            (files.lexicon == null || files.lexicon!.isEmpty)) {
          throw SherpaTtsException(
            'Kokoro model ${model.id} is multi-lingual but no lexicon*.txt '
            'files were found — re-download the model, the archive is '
            'likely incomplete.',
          );
        }
        return {
          ...base,
          'modelType': 'kokoro',
          'modelPath': files.onnxFiles.first,
          'voicesPath': files.voicesBin,
          'lang': isMultiLingual ? '' : model.languageCode,
        };

      case SherpaTtsModelType.matcha:
        final vocoderName = model.vocoderFileName;
        String? acoustic, vocoder;
        for (final f in files.onnxFiles) {
          final baseName = p.basename(f).toLowerCase();
          if ((vocoderName != null && p.basename(f) == vocoderName) ||
              baseName.contains('vocos') ||
              baseName.contains('hifigan') ||
              baseName.contains('vocoder')) {
            vocoder = f;
          } else {
            acoustic = f;
          }
        }
        if (acoustic == null || vocoder == null) {
          throw SherpaTtsException(
            'Matcha model ${model.id} needs an acoustic model and a vocoder .onnx.',
          );
        }
        return {
          ...base,
          'modelType': 'matcha',
          'acousticPath': acoustic,
          'vocoderPath': vocoder,
        };
    }
  }

  int get sampleRate {
    final rate = _sampleRate;
    if (rate == null) throw SherpaTtsException('No model loaded.');
    return rate;
  }

  int get speakerCount {
    final count = _speakerCount;
    if (count == null) throw SherpaTtsException('No model loaded.');
    return count;
  }

  List<SherpaTtsSpeaker> get speakers {
    final count = speakerCount;
    return List.generate(
      count,
      (i) => SherpaTtsSpeaker(id: i, label: 'Speaker $i'),
    );
  }

  Future<TtsAudio> generate({
    required String text,
    int speakerId = 0,
    double speed = 1.0,
    double? silenceScale,
    int? numSteps,
  }) async {
    if (!hasLoadedModel) {
      throw SherpaTtsException('No model loaded. Call loadModel() first.');
    }
    final gvs = _settingsService.settings.globalViewSettings;
    final effectiveSilenceScale = silenceScale ?? gvs.ttsSilenceScale;
    final effectiveNumSteps = numSteps ?? gvs.ttsNumSteps;

    final result = await _isolateService.sendCommand<Map>(
      sherpaTtsIsolateName,
      {
        'id': _nextId(),
        'type': 'generate',
        'text': text,
        'speakerId': speakerId,
        'speed': speed,
        'silenceScale': effectiveSilenceScale,
        'numSteps': effectiveNumSteps,
      },
    );
    return TtsAudio(
      samples: result['samples'] as Float32List,
      sampleRate: result['sampleRate'] as int,
    );
  }

  /// Synthesizes text directly to a WAV file inside the worker isolate.
  Future<({File file, double duration, List<double> waveform})> generateToFile({
    required String text,
    required String outputPath,
    int speakerId = 0,
    double speed = 1.0,
    double gapSec = 0.0,
    double? silenceScale,
    int? numSteps,
  }) async {
    if (!hasLoadedModel) {
      throw const TtsModelNotLoadedException();
    }
    final gvs = _settingsService.settings.globalViewSettings;
    final effectiveSentenceGap = gvs.ttsSentenceGap;
    final effectiveSilenceScale = silenceScale ?? gvs.ttsSilenceScale;
    final effectiveNumSteps = numSteps ?? gvs.ttsNumSteps;

    try {
      final result = await _isolateService.sendCommand<Map>(
        sherpaTtsIsolateName,
        {
          'id': _nextId(),
          'type': 'generateToFile',
          'text': text,
          'outputPath': outputPath,
          'speakerId': speakerId,
          'speed': speed,
          'gapSec': gapSec,
          'sentenceGapMs': effectiveSentenceGap,
          'silenceScale': effectiveSilenceScale,
          'numSteps': effectiveNumSteps,
        },
      );
      final rawWaveform = result['waveform'] as List<dynamic>?;
      final waveform =
          rawWaveform
              ?.map((e) => (e as num).toDouble())
              .toList(growable: false) ??
          const <double>[];

      return (
        file: File(result['outputPath'] as String),
        duration: (result['duration'] as num).toDouble(),
        waveform: waveform,
      );
    } catch (e, st) {
      logger.e('Failed to generate WAV file with Sherpa ONNX', e, st);
      if (e is TtsException) rethrow;
      throw TtsSynthesisException('Synthesis to file failed: $e', e);
    }
  }

  /// Synthesizes text to an in-memory WAV byte buffer inside the worker
  /// isolate, avoiding disk I/O. The returned bytes are ready to be served by
  /// a [ParagraphStreamAudioSource].
  Future<
    ({
      Uint8List wavBytes,
      double duration,
      int sampleRate,
      List<double> waveform,
    })
  >
  generateToBytes({
    required String text,
    int speakerId = 0,
    double speed = 1.0,
    double gapSec = 0.0,
    double? silenceScale,
    int? numSteps,
  }) async {
    if (!hasLoadedModel) {
      throw const TtsModelNotLoadedException();
    }
    final gvs = _settingsService.settings.globalViewSettings;
    final effectiveSentenceGap = gvs.ttsSentenceGap;
    final effectiveSilenceScale = silenceScale ?? gvs.ttsSilenceScale;
    final effectiveNumSteps = numSteps ?? gvs.ttsNumSteps;

    try {
      final result = await _isolateService.sendCommand<Map>(
        sherpaTtsIsolateName,
        {
          'id': _nextId(),
          'type': 'generateToBytes',
          'text': text,
          'speakerId': speakerId,
          'speed': speed,
          'gapSec': gapSec,
          'sentenceGapMs': effectiveSentenceGap,
          'silenceScale': effectiveSilenceScale,
          'numSteps': effectiveNumSteps,
        },
      );
      final rawWaveform = result['waveform'] as List<dynamic>?;
      final waveform =
          rawWaveform
              ?.map((e) => (e as num).toDouble())
              .toList(growable: false) ??
          const <double>[];

      return (
        wavBytes: result['wavBytes'] as Uint8List,
        duration: (result['duration'] as num).toDouble(),
        sampleRate: (result['sampleRate'] as num).toInt(),
        waveform: waveform,
      );
    } catch (e, st) {
      logger.e('Failed to generate WAV bytes with Sherpa ONNX', e, st);
      if (e is TtsException) rethrow;
      throw TtsSynthesisException('Synthesis to bytes failed: $e', e);
    }
  }

  Stream<Float32List> generateStreaming({
    required String text,
    int speakerId = 0,
    double speed = 1.0,
    double? silenceScale,
    int? numSteps,
  }) {
    if (!hasLoadedModel) {
      throw SherpaTtsException('No model loaded. Call loadModel() first.');
    }
    final gvs = _settingsService.settings.globalViewSettings;
    final effectiveSilenceScale = silenceScale ?? gvs.ttsSilenceScale;
    final effectiveNumSteps = numSteps ?? gvs.ttsNumSteps;

    return _isolateService.sendStreamCommand<Float32List>(
      sherpaTtsIsolateName,
      {
        'id': _nextId(),
        'type': 'generateStream',
        'text': text,
        'speakerId': speakerId,
        'speed': speed,
        'silenceScale': effectiveSilenceScale,
        'numSteps': effectiveNumSteps,
      },
    );
  }

  Future<File> synthesizeToFile({
    required String text,
    required String outputPath,
    int speakerId = 0,
    double speed = 1.0,
    double? silenceScale,
    int? numSteps,
  }) async {
    final audio = await generate(
      text: text,
      speakerId: speakerId,
      speed: speed,
      silenceScale: silenceScale,
      numSteps: numSteps,
    );
    final ok = sherpa.writeWave(
      filename: outputPath,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );
    if (!ok) {
      throw SherpaTtsException('Failed to write WAV to $outputPath');
    }
    return File(outputPath);
  }
}

class _ModelFiles {
  _ModelFiles({
    required this.onnxFiles,
    required this.tokens,
    this.lexicon,
    this.ruleFsts,
    this.ruleFars,
    this.voicesBin,
    this.espeakDataDir,
    this.dictDir,
  });

  final List<String> onnxFiles;
  final String tokens;
  final String? lexicon;
  final String? ruleFsts;
  final String? ruleFars;
  final String? voicesBin;
  final String? espeakDataDir;
  final String? dictDir;

  String? get onnxPrimary => onnxFiles.isNotEmpty ? onnxFiles.first : null;
  String? get onnxSecondary => onnxFiles.length > 1 ? onnxFiles[1] : null;
}
