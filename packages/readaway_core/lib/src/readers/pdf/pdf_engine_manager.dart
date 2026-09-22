import 'package:pdfrx/pdfrx.dart';

/// Manages the lifecycle of active PDF document instances.
///
/// Ensures zero startup overhead by lazily managing PDFium resources only when
/// PDF documents are active, and releasing resources when all PDFs are closed.
class PdfEngineManager {
  static int _activeDocumentCount = 0;
  static bool _isInitialized = false;
  static Future<void>? _initFuture;

  const PdfEngineManager._();

  /// Lazily initializes pdfrx if not already initialized, incrementing the active PDF count.
  static Future<void> acquire() async {
    _activeDocumentCount++;
    if (_isInitialized) return;

    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    _initFuture = () async {
      try {
        await pdfrxFlutterInitialize();
      } catch (_) {}
      _isInitialized = true;
    }();

    await _initFuture;
  }

  /// Releases a reference to the PDF engine, cleaning up reference count.
  static void release() {
    if (_activeDocumentCount > 0) {
      _activeDocumentCount--;
    }
  }

  /// Current number of active PDF readers.
  static int get activeCount => _activeDocumentCount;

  /// Whether the PDF engine is currently active.
  static bool get isInitialized => _isInitialized;
}
