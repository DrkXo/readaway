import 'dart:typed_data';

import '../audio/pcm.dart' as pcm;
import '../models/models.dart';
import '../readers/plain_text_document_reader.dart';

/// Fluent byte extensions for character encoding detection and text decoding.
extension ReadAwayBytesEncodingX on Uint8List {
  /// Detects the character encoding of these bytes using BOM checks, UTF-8 validity heuristics,
  /// and CJK multibyte statistics.
  DetectedEncoding detectEncoding() => EncodingDetector.detect(this);

  /// Decodes these bytes to a Dart [String] using the detected (or explicitly specified) encoding.
  String decodeText({DetectedEncoding? detected}) =>
      EncodingDetector.decode(this, detected: detected);
}

/// Fluent extensions on float PCM audio samples for speech boundary detection and edge fading.
extension ReadAwayFloatPcmX on Float32List {
  /// Locates the voiced speech interval (ignoring leading and trailing silence).
  pcm.SpeechBounds findSpeechBounds(
    int sampleRate, {
    double threshold = pcm.kDefaultSilenceThreshold,
  }) => pcm.findSpeechBounds(this, sampleRate, threshold: threshold);

  /// Ramps the outer samples linearly to zero in-place to avoid clicks.
  void applyEdgeFade(
    int sampleRate, {
    double fadeSec = pcm.kEdgeFadeSeconds,
  }) => pcm.applyEdgeFade(this, sampleRate, fadeSec: fadeSec);
}
