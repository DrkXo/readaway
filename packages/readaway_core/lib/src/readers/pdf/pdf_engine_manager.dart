import 'package:pdfrx/pdfrx.dart';

import '../../logger/app_logger.dart';

/// Manages the lifecycle of active PDF document instances.
///
/// Ensures zero startup overhead by lazily managing PDFium resources only when
/// PDF documents are active, and releasing resources when all PDFs are closed.
class PdfEngineManager {
  static final _log = AppLogger.instance.scope('PdfEngineManager');

  static int _activeDocumentCount = 0;
  static bool _isInitialized = false;
  static Future<void>? _initFuture;

  const PdfEngineManager._();

  /// Lazily initializes pdfrx if not already initialized, incrementing the active PDF count.
  static Future<void> acquire() async {
    while (_initFuture != null) {
      await _initFuture;
    }

    if (_isInitialized) {
      _activeDocumentCount++;
      _log.d('Acquired PDF engine (active count: $_activeDocumentCount)');
      return;
    }

    final future = () async {
      _log.i('Initializing pdfrx engine...');
      try {
        await pdfrxFlutterInitialize();
        _log.i('pdfrx engine successfully initialized');
      } catch (e, st) {
        _log.e('Failed to initialize pdfrx engine', error: e, stackTrace: st);
      }
      _isInitialized = true;
    }();

    _initFuture = future;
    try {
      await future;
      _activeDocumentCount++;
      _log.d('Acquired PDF engine (active count: $_activeDocumentCount)');
    } finally {
      if (_initFuture == future) {
        _initFuture = null;
      }
    }
  }

  /// Releases a reference to the PDF engine, cleaning up reference count.
  /// When no PDF documents are active, stops the background pdfrx worker isolate.
  static Future<void> release() async {
    if (_activeDocumentCount > 0) {
      _activeDocumentCount--;
      _log.d('Released PDF engine (remaining active: $_activeDocumentCount)');
    }
    if (_activeDocumentCount == 0 && _isInitialized) {
      _isInitialized = false;
      _log.i('No active PDF documents remaining. Tearing down pdfrx engine...');
      final teardownFuture = _teardown();
      _initFuture = teardownFuture;
      try {
        await teardownFuture;
      } finally {
        if (_initFuture == teardownFuture) {
          _initFuture = null;
        }
      }
    }
  }

  static Future<void> _teardown() async {
    try {
      await PdfrxEntryFunctions.instance.stopBackgroundWorker();
      _log.d('Stopped pdfrx background worker');
    } catch (e, st) {
      _log.w('Failed to stop pdfrx background worker cleanly', error: e, stackTrace: st);
    }
  }

  /// Resets internal state for test isolation.
  static void reset() {
    _activeDocumentCount = 0;
    _isInitialized = false;
    _initFuture = null;
  }

  /// Current number of active PDF readers.
  static int get activeCount => _activeDocumentCount;

  /// Whether the PDF engine is currently active.
  static bool get isInitialized => _isInitialized;
}
