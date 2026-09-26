import 'package:flutter_test/flutter_test.dart';
import 'package:readaway_core/readaway_core.dart';

void main() {
  group('TtsCachedChunk and TtsChapterCacheManifest', () {
    test('chunk creation and json serialization round-trip', () {
      const chunk = TtsCachedChunk(
        chunkIndex: 0,
        fileName: 'chunk_0000.wav',
        startOffset: 0,
        endOffset: 45,
        durationSec: 2.5,
        waveform: [0.1, 0.5, 0.9, 0.3],
        gapSec: 0.35,
      );

      final json = chunk.toJson();
      final fromJson = TtsCachedChunk.fromJson(json);

      expect(fromJson.chunkIndex, 0);
      expect(fromJson.fileName, 'chunk_0000.wav');
      expect(fromJson.startOffset, 0);
      expect(fromJson.endOffset, 45);
      expect(fromJson.durationSec, 2.5);
      expect(fromJson.waveform, [0.1, 0.5, 0.9, 0.3]);
      expect(fromJson.gapSec, 0.35);
    });

    test('manifest creation, chunk addition, and json round-trip', () {
      final now = DateTime.now();
      var manifest = TtsChapterCacheManifest(
        chapterIndex: 2,
        textHash: 'hash12345',
        voiceId: 'vits-piper-en_US-amy-low',
        speakerId: 0,
        configHash: 'cfg-abc',
        sampleRate: 22050,
        createdAt: now,
        lastAccessedAt: now,
      );

      expect(manifest.chapterIndex, 2);
      expect(manifest.chunks, isEmpty);
      expect(manifest.isComplete, false);
      expect(manifest.totalDurationSec, 0.0);

      const chunk0 = TtsCachedChunk(
        chunkIndex: 0,
        fileName: 'chunk_0000.wav',
        startOffset: 0,
        endOffset: 50,
        durationSec: 3.0,
      );
      const chunk1 = TtsCachedChunk(
        chunkIndex: 1,
        fileName: 'chunk_0001.wav',
        startOffset: 51,
        endOffset: 120,
        durationSec: 4.5,
      );

      manifest = manifest.withChunk(chunk0).withChunk(chunk1);

      expect(manifest.chunks.length, 2);
      expect(manifest.totalDurationSec, 7.5);
      expect(manifest.hasChunk(0), true);
      expect(manifest.hasChunk(1), true);
      expect(manifest.hasChunk(2), false);
      expect(manifest.getChunk(1)?.fileName, 'chunk_0001.wav');

      final json = manifest.toJson();
      final fromJson = TtsChapterCacheManifest.fromJson(json);

      expect(fromJson.chapterIndex, 2);
      expect(fromJson.textHash, 'hash12345');
      expect(fromJson.voiceId, 'vits-piper-en_US-amy-low');
      expect(fromJson.chunks.length, 2);
      expect(fromJson.chunks[0].durationSec, 3.0);
      expect(fromJson.chunks[1].durationSec, 4.5);
      expect(fromJson.totalDurationSec, 7.5);
    });

    test('manifest withChunk updates existing chunk without duplicating', () {
      final now = DateTime.now();
      var manifest = TtsChapterCacheManifest(
        chapterIndex: 0,
        textHash: 'hash',
        voiceId: 'v1',
        createdAt: now,
        lastAccessedAt: now,
      );

      manifest = manifest.withChunk(
        const TtsCachedChunk(
          chunkIndex: 0,
          fileName: 'chunk_0.wav',
          startOffset: 0,
          endOffset: 10,
          durationSec: 1.0,
        ),
      );
      expect(manifest.chunks.length, 1);
      expect(manifest.totalDurationSec, 1.0);

      manifest = manifest.withChunk(
        const TtsCachedChunk(
          chunkIndex: 0,
          fileName: 'chunk_0.wav',
          startOffset: 0,
          endOffset: 10,
          durationSec: 2.0,
        ),
      );
      expect(manifest.chunks.length, 1);
      expect(manifest.totalDurationSec, 2.0);
    });
  });
}
