import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/tts/extractor/tts_archive_extractor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tts_archive_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test(
    'model extraction ignores entries that escape the destination',
    () async {
      final archive = Archive()
        ..add(ArchiveFile.string('model/../outside.txt', 'unsafe'))
        ..add(ArchiveFile.string('model/../../outside.txt', 'unsafe'))
        ..add(ArchiveFile.string(r'model/C:\outside.txt', 'unsafe'))
        ..add(ArchiveFile.string('model/tokens.txt', 'safe'));
      final archiveFile = File('${tempDir.path}/model.zip')
        ..writeAsBytesSync(ZipEncoder().encode(archive));
      final destination = Directory('${tempDir.path}/model');
      await destination.create();

      await TtsArchiveExtractor().extractModelArchive(
        archiveFile: archiveFile,
        destDir: destination,
      );

      expect(
        await File('${destination.path}/tokens.txt').readAsString(),
        'safe',
      );
      expect(await File('${tempDir.path}/outside.txt').exists(), isFalse);
    },
  );

  test(
    'espeak extraction ignores entries that escape the destination',
    () async {
      final archive = Archive()
        ..add(ArchiveFile.string('espeak-ng-data/../../outside.txt', 'unsafe'))
        ..add(ArchiveFile.string('espeak-ng-data/voices/en', 'safe'));
      final archiveFile = File('${tempDir.path}/espeak.zip')
        ..writeAsBytesSync(ZipEncoder().encode(archive));
      final targetDir = Directory('${tempDir.path}/target');
      final espeakDir = Directory('${targetDir.path}/espeak-ng-data');
      await targetDir.create(recursive: true);

      await TtsArchiveExtractor().extractEspeakArchive(
        archiveFile: archiveFile,
        targetDir: targetDir,
        espeakDir: espeakDir,
      );

      expect(
        await File('${targetDir.path}/espeak-ng-data/voices/en').readAsString(),
        'safe',
      );
      expect(await File('${tempDir.path}/outside.txt').exists(), isFalse);
    },
  );
}
