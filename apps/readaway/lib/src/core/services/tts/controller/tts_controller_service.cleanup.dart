part of 'tts_controller_service.dart';

/// Playback-state reset and session temp-file cleanup.
extension _TtsSessionCleanup on TtsControllerService {
  void _resetPlaybackState() {
    _currentIndex = -1;
    _currentPageIndex = null;
    if (!_pageIndexController.isClosed) {
      _pageIndexController.add(null);
    }
    if (!_stateController.isClosed) {
      _stateController.add(const TtsPlaybackEvent(TtsPlaybackState.stopped));
    }
  }

  Future<void> _cleanTempFiles() async {
    final files = List<File>.from(_sessionTempFiles);
    _sessionTempFiles.clear();
    _chunkWaveforms.clear();
    if (!_waveformController.isClosed) {
      _waveformController.add(const []);
    }
    for (final f in files) {
      await _deleteFileSafe(f);
    }
  }

  Future<void> _deleteFileSafe(File f) async {
    try {
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }
}
