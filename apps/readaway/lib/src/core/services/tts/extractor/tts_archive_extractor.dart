import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../tts_models.dart';

@singleton
class TtsArchiveExtractor {
  const TtsArchiveExtractor();

  /// Decompresses an archive file ([.tar.bz2], [.tar.gz], [.zip]) into [destDir].
  /// Strips the top-level directory if the archive wraps all contents in one folder.
  Future<void> extractModelArchive({
    required File archiveFile,
    required Directory destDir,
  }) async {
    final bytes = await archiveFile.readAsBytes();
    await compute(extractModelArchiveWorker, (
      bytes: bytes,
      archivePath: archiveFile.path,
      destPath: destDir.path,
    ));
  }

  /// Extracts espeak-ng-data archive preserving directory structure.
  Future<void> extractEspeakArchive({
    required File archiveFile,
    required Directory targetDir,
    required Directory espeakDir,
  }) async {
    final bytes = await archiveFile.readAsBytes();
    await compute(extractEspeakArchiveWorker, (
      bytes: bytes,
      archivePath: archiveFile.path,
      modelDirPath: targetDir.path,
      espeakDirPath: espeakDir.path,
    ));
  }

  static Archive decodeArchive(Uint8List bytes, String path) {
    if (path.endsWith('.tar.bz2') || path.endsWith('.tbz2')) {
      final tarBytes = BZip2Decoder().decodeBytes(bytes);
      return TarDecoder().decodeBytes(tarBytes);
    } else if (path.endsWith('.tar.gz') || path.endsWith('.tgz')) {
      final tarBytes = GZipDecoder().decodeBytes(bytes);
      return TarDecoder().decodeBytes(tarBytes);
    } else if (path.endsWith('.zip')) {
      return ZipDecoder().decodeBytes(bytes);
    }
    throw SherpaTtsException('Unsupported archive format: $path');
  }

  static String stripTopLevelDir(String entryName) {
    final normalized = entryName.replaceAll('\\', '/');
    final firstSlash = normalized.indexOf('/');
    if (firstSlash == -1) return normalized;
    return normalized.substring(firstSlash + 1);
  }
}

Future<void> extractModelArchiveWorker(
  ({Uint8List bytes, String archivePath, String destPath}) args,
) async {
  final archive = TtsArchiveExtractor.decodeArchive(
    args.bytes,
    args.archivePath,
  );
  for (final entry in archive.files) {
    if (!entry.isFile) continue;
    final relative = TtsArchiveExtractor.stripTopLevelDir(entry.name);
    if (relative.isEmpty) continue;
    final outFile = File(p.join(args.destPath, relative));
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(entry.content as List<int>);
  }
}

Future<void> extractEspeakArchiveWorker(
  ({
    Uint8List bytes,
    String archivePath,
    String modelDirPath,
    String espeakDirPath,
  })
  args,
) async {
  final archive = TtsArchiveExtractor.decodeArchive(
    args.bytes,
    args.archivePath,
  );
  final files = archive.files.where((e) => e.isFile).toList();
  final hasTopLevelDir = files.any(
    (e) => e.name.replaceAll('\\', '/').startsWith('espeak-ng-data/'),
  );
  final basePath = hasTopLevelDir ? args.modelDirPath : args.espeakDirPath;
  for (final entry in files) {
    final outFile = File(p.join(basePath, entry.name));
    await outFile.parent.create(recursive: true);
    await outFile.writeAsBytes(entry.content as List<int>);
  }
}
