import '../models/models.dart';

/// A single monotonic clock over a queue of synthesized TTS audio chunks.
///
/// The player does not play one continuous file. It plays a *playlist* of one
/// WAV per sentence, appended as synthesis completes
/// (`TtsControllerService._synthesizeAndPlayPipeline`). Anything that needs a
/// position on a single axis — a lyric view, an LRC timestamp, a scrubber —
/// would otherwise have to track the playlist index and the in-track offset
/// separately and reconcile them everywhere it is used. This class reconciles
/// them once, here.
///
/// Every boundary it reports is *measured*, not estimated. The duration of a
/// chunk is the length of the samples the engine actually produced, and the
/// silence between sentences is baked into the file rather than applied by the
/// player (`TtsControllerService._gapForChunk`), so a chunk's recorded duration
/// already includes the pause that follows it. Cumulative sums of those
/// durations are therefore the real start time of each sentence — which is
/// more than a hand-authored LRC can usually promise.
///
/// The mapping is a running prefix sum with a binary search on the inverse, so
/// both directions are exact and cost no more than a search over a page's worth
/// of sentences.
///
/// This type is immutable, does no IO, and has no Flutter dependency. Build it
/// once per playback session from the durations recorded in
/// `TtsChapterCacheManifest`.
class TtsTimeline {
  /// Prefix sums in microseconds: `_starts[i]` is the offset at which chunk `i`
  /// begins, and `_starts.last` is the total.
  ///
  /// Microseconds rather than `Duration` because the inverse search compares
  /// many candidates and integer comparison on a hot path is cheaper than
  /// `Duration` construction. The public API still speaks `Duration`.
  final List<int> _starts;

  /// Number of chunks, i.e. the number of gaps between consecutive [_starts]
  /// entries.
  int get _length => _starts.length - 1;

  /// Builds a timeline over [durations].
  ///
  /// A duration of zero or less contributes nothing and collapses its chunk
  /// onto the following one, so degenerate input produces a usable timeline
  /// rather than a sequence of boundaries that all read the same instant.
  TtsTimeline(Iterable<Duration> durations) : _starts = _buildStarts(durations);

  /// Builds a timeline over [durations] given in seconds, as recorded in the
  /// chapter manifest.
  ///
  /// Rounding is to the nearest microsecond rather than truncating to
  /// milliseconds so that a long queue does not accumulate visible drift: a
  /// 500 ms chunk rounded down 100 times loses 50 ms of real time by the end.
  TtsTimeline.fromSeconds(Iterable<double> durations)
    : _starts = _buildStarts(
        durations.map((s) => Duration(microseconds: (s * 1000000).round())),
      );

  /// Builds a timeline over a single chunk of [duration].
  ///
  /// Useful where the manifest has exactly one recorded chunk, which is the
  /// common case for a short page that was synthesized in one pass.
  TtsTimeline.single(Duration duration) : _starts = _buildStarts([duration]);

  /// Whether this timeline has no chunks.
  bool get isEmpty => _length == 0;

  /// Whether this timeline has at least one chunk.
  bool get isNotEmpty => _length != 0;

  /// Number of chunks on the timeline.
  int get length => _length;

  /// Total duration of every chunk, including the silence baked into them.
  Duration get total => Duration(microseconds: _starts[_length]);

  /// Start time of the chunk at [index].
  ///
  /// Clamps rather than throws, because a caller holding a stale chunk index
  /// after a queue change is an ordinary race rather than a programming error,
  /// and a position at the end of the timeline is the honest answer for one.
  Duration startOf(int index) {
    if (index <= 0) return Duration.zero;
    if (index >= _length) return total;
    return Duration(microseconds: _starts[index]);
  }

  /// Duration of the chunk at [index], including its trailing gap.
  ///
  /// The final chunk carries no gap, so this is the audio alone.
  Duration durationOf(int index) {
    if (index < 0 || index >= _length) return Duration.zero;
    return Duration(microseconds: _starts[index + 1] - _starts[index]);
  }

  /// Index of the chunk containing [position].
  ///
  /// A position exactly on a boundary belongs to the chunk that starts there,
  /// which is what a lyric view needs: the highlight should advance when the
  /// audio for the new sentence begins, not when the previous one is over.
  ///
  /// Positions past the end return the last index rather than throwing, so a
  /// position that runs ahead of a queue still being appended to resolves to
  /// the newest sentence instead of going out of range.
  int indexAt(Duration position) {
    if (position <= Duration.zero) return 0;
    final micros = position.inMicroseconds;
    if (micros >= _starts[_length]) return _length - 1;

    // Largest i with _starts[i] <= micros.
    var low = 0;
    var high = _length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_starts[mid + 1] <= micros) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  /// Whether [position] lies within the chunk at [index], inclusive of its
  /// start and exclusive of its end.
  bool contains(int index, Duration position) {
    if (index < 0 || index >= _length) return false;
    final micros = position.inMicroseconds;
    return micros >= _starts[index] && micros < _starts[index + 1];
  }

  /// Offset of [position] within the chunk that contains it.
  ///
  /// Equivalent to `position - startOf(indexAt(position))`, clamped to the
  /// containing chunk's own bounds so that a position past the end reports the
  /// final chunk's length rather than a negative or overflowing offset.
  Duration offsetIn(Duration position) {
    if (isEmpty) return Duration.zero;
    final index = indexAt(position);
    final micros = position.inMicroseconds - _starts[index];
    final span = _starts[index + 1] - _starts[index];
    return Duration(
      microseconds: micros < 0 ? 0 : (micros > span ? span : micros),
    );
  }

  /// Fraction of the timeline elapsed at [position], in `0.0..1.0`.
  ///
  /// Returns 0 for an empty timeline rather than dividing by zero.
  double progressAt(Duration position) {
    final totalMicros = _starts[_length];
    if (totalMicros <= 0) return 0;
    final micros = position.inMicroseconds;
    if (micros <= 0) return 0;
    if (micros >= totalMicros) return 1;
    return micros / totalMicros;
  }

  @override
  String toString() =>
      'TtsTimeline(length: $_length, total: ${total.inMilliseconds}ms)';
}

List<int> _buildStarts(Iterable<Duration> durations) {
  final starts = <int>[0];
  var acc = 0;
  for (final d in durations) {
    // A non-positive duration would make the boundaries non-increasing, which
    // would break the invariant the binary search relies on. Skipping it keeps
    // the prefix sum strictly ordered.
    if (d.inMicroseconds > 0) acc += d.inMicroseconds;
    starts.add(acc);
  }
  return starts;
}

/// Builds a timeline over the leading run of chunks in [manifest] that have a
/// measured duration, up to [chunkCount] chunks.
///
/// Returns null when nothing has been measured yet, which is the normal state
/// for the first moments of a page: the pipeline synthesizes in the background
/// and does not know how long a sentence will take until it has been spoken.
///
/// Stops at the first unmeasured chunk rather than skipping it. A hole would
/// shift every later boundary by an unknown amount, and a timeline whose
/// timestamps are quietly wrong is worse than one that honestly stops short.
/// Chunks do go unmeasured mid-page — an empty utterance is never synthesized,
/// and a synthesis failure is caught and skipped by the pipeline.
///
/// [chunkCount] bounds the scan to the chunks that are actually part of the
/// current page. A manifest left over from a longer previous queue would
/// otherwise contribute durations for chunks that no longer exist, and the
/// extra entries would silently stretch the total.
TtsTimeline? timelineFromManifest(
  TtsChapterCacheManifest manifest, {
  required int chunkCount,
}) {
  if (chunkCount <= 0) return null;

  final durations = <double>[];
  for (var i = 0; i < chunkCount; i++) {
    final seconds = manifest.getChunk(i)?.durationSec ?? 0.0;
    if (seconds <= 0) break;
    durations.add(seconds);
  }

  if (durations.isEmpty) return null;
  return TtsTimeline.fromSeconds(durations);
}
