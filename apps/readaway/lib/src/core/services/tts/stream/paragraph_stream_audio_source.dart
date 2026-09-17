import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

// ignore_for_file: experimental_member_use, overridden_fields

/// An [AudioSource] that serves a complete paragraph's audio from an in-memory
/// WAV buffer via just_audio's local HTTP proxy.
///
/// This eliminates per-sentence item transitions in the playlist: all sentences
/// within a paragraph (including baked-in gap silence) live in a single
/// [Uint8List] and are served as one continuous stream. libmpv opens the proxy
/// URI as a normal HTTP stream, so range requests are handled transparently.
///
/// ## Memory model
///
/// The [wavBytes] are held for the lifetime of the source. Once the player
/// finishes this item the reference is released and GC can reclaim the buffer.
/// Typical paragraph size: 130–260 KB (3–6 s at 22 050 Hz mono 16-bit).
class ParagraphStreamAudioSource extends StreamAudioSource {
  /// Raw 16-bit PCM WAV bytes for the entire paragraph.
  final Uint8List wavBytes;

  /// Total wall-clock duration of the audio (including trailing gap).
  @override
  final Duration duration;

  /// Index of this paragraph within the document.
  final int paragraphIndex;

  ParagraphStreamAudioSource({
    required this.wavBytes,
    required this.duration,
    required this.paragraphIndex,
    super.tag,
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final int actualStart = start ?? 0;
    final int actualEnd = math.min(end ?? wavBytes.length, wavBytes.length);
    final int contentLen = actualEnd - actualStart;

    return StreamAudioResponse(
      rangeRequestsSupported: true,
      sourceLength: wavBytes.length,
      contentLength: contentLen,
      offset: start,
      contentType: 'audio/wav',
      stream: Stream.value(wavBytes.sublist(actualStart, actualEnd)),
    );
  }

  @override
  String toString() =>
      'ParagraphStreamAudioSource(paragraph=$paragraphIndex, '
      '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s, '
      '${wavBytes.length} bytes)';
}
