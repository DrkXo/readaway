import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/core/services/tts/stream/wav_encoder.dart';

void main() {
  group('encodeWavFromPcm', () {
    test('produces a valid 16-bit mono WAV header', () {
      const sampleRate = 22050;
      final samples = Float32List.fromList([0.0, 0.5, -0.5, 1.0, -1.0]);
      final wav = encodeWavFromPcm(samples, sampleRate);

      // RIFF/WAVE magic
      expect(_ascii(wav, 0, 4), 'RIFF');
      expect(_ascii(wav, 8, 4), 'WAVE');
      expect(_ascii(wav, 12, 4), 'fmt ');
      expect(_ascii(wav, 36, 4), 'data');

      // File size = 36 + data size
      final dataSize = samples.length * 2;
      final fileSize = _u32(wav, 4);
      expect(fileSize, 36 + dataSize);

      // fmt fields
      expect(_u16(wav, 20), 1); // PCM
      expect(_u16(wav, 22), 1); // mono
      expect(_u32(wav, 24), sampleRate);
      expect(_u16(wav, 32), 2); // block align
      expect(_u16(wav, 34), 16); // bits per sample

      // data size
      expect(_u32(wav, 40), dataSize);

      // Total length
      expect(wav.length, 44 + dataSize);
    });

    test('encodes float samples as 16-bit little-endian PCM', () {
      final samples = Float32List.fromList([1.0, -1.0, 0.0]);
      final wav = encodeWavFromPcm(samples, 8000);

      // 1.0 → 32767 (0x7FFF), -1.0 → -32767, 0.0 → 0
      expect(_i16(wav, 44), 32767);
      expect(_i16(wav, 46), -32767);
      expect(_i16(wav, 48), 0);
    });

    test('clamps out-of-range samples', () {
      final samples = Float32List.fromList([2.0, -2.0]);
      final wav = encodeWavFromPcm(samples, 8000);
      expect(_i16(wav, 44), 32767);
      expect(_i16(wav, 46), -32767);
    });
  });

  group('encodeConcatenatedWav', () {
    test('concatenates buffers with baked gap silence', () {
      const sampleRate = 8000;
      final a = Float32List.fromList([1.0]);
      final b = Float32List.fromList([-1.0]);
      // 1 sample gap between a and b
      final wav = encodeConcatenatedWav(
        buffers: [a, b],
        gapSamples: [1],
        sampleRate: sampleRate,
      );

      // data = a(1) + gap(1) + b(1) = 3 samples = 6 bytes
      expect(_u32(wav, 40), 6);
      expect(_i16(wav, 44), 32767); // a
      expect(_i16(wav, 46), 0); // gap silence
      expect(_i16(wav, 48), -32767); // b
    });

    test('no trailing gap after the final buffer', () {
      const sampleRate = 8000;
      final a = Float32List.fromList([1.0]);
      final b = Float32List.fromList([-1.0]);
      final wav = encodeConcatenatedWav(
        buffers: [a, b],
        gapSamples: [5],
        sampleRate: sampleRate,
      );
      // data = a(1) + gap(5) + b(1) = 7 samples = 14 bytes
      expect(_u32(wav, 40), 14);
    });
  });
}

String _ascii(Uint8List b, int offset, int length) =>
    String.fromCharCodes(b.sublist(offset, offset + length));

int _u16(Uint8List b, int offset) => b[offset] | (b[offset + 1] << 8);

int _u32(Uint8List b, int offset) =>
    b[offset] |
    (b[offset + 1] << 8) |
    (b[offset + 2] << 16) |
    (b[offset + 3] << 24);

int _i16(Uint8List b, int offset) {
  final u = _u16(b, offset);
  return u >= 0x8000 ? u - 0x10000 : u;
}
