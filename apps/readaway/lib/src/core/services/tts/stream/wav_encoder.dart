import 'dart:math' as math;
import 'dart:typed_data';

/// Encodes mono 32-bit float PCM [samples] into a standard 16-bit PCM WAV byte
/// buffer at the given [sampleRate].
///
/// The encoder is intentionally self-contained (no sherpa dependency) so it can
/// run on the main isolate or a worker isolate without pulling in native libs.
Uint8List encodeWavFromPcm(Float32List samples, int sampleRate) {
  const int bitsPerSample = 16;
  const int numChannels = 1;
  final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
  const int blockAlign = numChannels * bitsPerSample ~/ 8;
  final int dataSize = samples.length * (bitsPerSample ~/ 8);
  final int fileSize = 36 + dataSize;

  final ByteData header = ByteData(44);

  // RIFF header
  _writeAscii(header, 0, 'RIFF');
  header.setUint32(4, fileSize, Endian.little);
  _writeAscii(header, 8, 'WAVE');

  // fmt sub-chunk
  _writeAscii(header, 12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // sub-chunk size
  header.setUint16(20, 1, Endian.little); // PCM format
  header.setUint16(22, numChannels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  // data sub-chunk
  _writeAscii(header, 36, 'data');
  header.setUint32(40, dataSize, Endian.little);

  // Interleave float → 16-bit signed PCM
  final Uint8List wav = Uint8List(44 + dataSize);
  wav.setRange(0, 44, header.buffer.asUint8List(header.offsetInBytes, 44));

  final int maxVal = (math.pow(2, 15) - 1).toInt();
  for (var i = 0; i < samples.length; i++) {
    final double clamped = samples[i].clamp(-1.0, 1.0);
    final int sample = (clamped * maxVal).round();
    // 16-bit little-endian signed
    wav[44 + i * 2] = sample & 0xFF;
    wav[44 + i * 2 + 1] = (sample >> 8) & 0xFF;
  }

  return wav;
}

/// Concatenates multiple PCM float buffers with inter-chunk gap silence
/// baked between them, then encodes the result as WAV.
///
/// [gapSamples] must have exactly `buffers.length - 1` entries — one gap
/// between each consecutive pair of buffers. The final buffer receives no
/// trailing gap.
Uint8List encodeConcatenatedWav({
  required List<Float32List> buffers,
  required List<int> gapSamples,
  required int sampleRate,
}) {
  assert(buffers.length - 1 == gapSamples.length);

  // Calculate total length
  var totalSamples = 0;
  for (var i = 0; i < buffers.length; i++) {
    totalSamples += buffers[i].length;
    if (i < buffers.length - 1) {
      totalSamples += gapSamples[i];
    }
  }

  // Merge into one buffer
  final merged = Float32List(totalSamples);
  var offset = 0;
  for (var i = 0; i < buffers.length; i++) {
    merged.setAll(offset, buffers[i]);
    offset += buffers[i].length;
    if (i < buffers.length - 1 && gapSamples[i] > 0) {
      // Gap is already silence (zero-filled) in Float32List — just advance
      offset += gapSamples[i];
    }
  }

  return encodeWavFromPcm(merged, sampleRate);
}

void _writeAscii(ByteData data, int offset, String s) {
  for (var i = 0; i < s.length; i++) {
    data.setUint8(offset + i, s.codeUnitAt(i));
  }
}
