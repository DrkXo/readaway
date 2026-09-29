part of 'tts_controller_service.dart';

/// Maintains the page-wide timing axis ([TtsTimeline]) as synthesis discovers
/// each chunk's real duration.
///
/// The axis is derived, never stored twice: [_currentChapterManifest] is the
/// single source of truth for how long each chunk actually played, and this
/// extension only projects it into cumulative offsets.
extension TtsTimelineAxis on TtsControllerService {
  /// Recomputes [_timeline] from the manifest and publishes it if it changed.
  ///
  /// Called whenever the manifest gains a chunk, so the axis grows one sentence
  /// at a time as the lookahead pipeline runs. Emitting only on a real change
  /// matters: an identical republish would make a lyric view rebuild and scroll
  /// back to the top mid-sentence for no reason.
  void _refreshTimeline() {
    final next = _buildTimeline();
    final current = _timeline;
    final unchanged = switch ((current, next)) {
      (null, null) => true,
      (final c?, final n?) => c.length == n.length && c.total == n.total,
      _ => false,
    };
    if (unchanged) return;

    _timeline = next;
    if (!_timelineController.isClosed) _timelineController.add(next);
  }

  /// Builds the axis over the chunks measured so far.
  ///
  /// The prefix rule itself lives in [timelineFromManifest], where it is unit
  /// tested; this only supplies the page's chunk count.
  TtsTimeline? _buildTimeline() {
    final manifest = _currentChapterManifest;
    if (manifest == null) return null;
    return timelineFromManifest(manifest, chunkCount: _masterQueue.length);
  }

  /// Drops the axis, for use when the page changes.
  ///
  /// Called on the way into [playText] rather than waiting for the pipeline to
  /// load the new manifest. The gap in between is where a stale axis would be
  /// paired with a fresh [_masterQueue], which is a mismatch no amount of later
  /// correction would fix in the viewer's memory.
  void _clearTimeline() {
    _currentChapterManifest = null;
    _timeline = null;
    if (!_timelineController.isClosed) _timelineController.add(null);
  }
}
