import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../errors/document_exception.dart';
import '../lifecycle/disposable.dart';
import '../logger/app_logger.dart';
import '../models/models.dart';
import 'document_isolate_messages.dart';
import 'document_isolate_worker.dart';
import 'document_session.dart';

/// Client proxy managing an active document session inside a dedicated background isolate.
class IsolateDocumentSession with DisposableMixin implements DocumentSession {
  static final _log = AppLogger.instance.scope('IsolateDocumentSession');

  final Isolate _isolate;
  final SendPort _workerSendPort;
  final ReceivePort _hostReceivePort;
  final StreamSubscription<dynamic> _subscription;
  final Map<int, Completer<DocumentResponse>> _pending;
  int _nextRequestId;

  @override
  final String filePath;
  @override
  final String? title;
  @override
  final DocumentMetadata? metadata;
  @override
  final List<OutlineItem> outline;
  @override
  final int sectionCount;
  @override
  final int pageCount;
  @override
  final String? coverImagePath;
  @override
  final bool isReflowable;
  @override
  final String format;

  IsolateDocumentSession._({
    required this._isolate,
    required this._workerSendPort,
    required this._hostReceivePort,
    required this._subscription,
    required this._pending,
    required this._nextRequestId,
    required this.filePath,
    required this.title,
    required this.metadata,
    required this.outline,
    required this.sectionCount,
    required this.pageCount,
    required this.coverImagePath,
    required this.isReflowable,
    required this.format,
  });

  /// Spawns a dedicated background isolate and opens the document at [filePath].
  ///
  /// [password] may be supplied for password-protected / encrypted documents.
  static Future<IsolateDocumentSession> open(
    String filePath, {
    String? password,
  }) async {
    _log.i('Spawning isolate session for document: $filePath');
    final hostReceivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      documentIsolateEntryPoint,
      hostReceivePort.sendPort,
      debugName: 'DocumentIsolate-$filePath',
    );

    final workerSendPortCompleter = Completer<SendPort>();
    final pending = <int, Completer<DocumentResponse>>{};
    var nextId = 1;

    late final StreamSubscription<dynamic> subscription;
    subscription = hostReceivePort.listen((message) {
      if (message is SendPort) {
        if (!workerSendPortCompleter.isCompleted) {
          workerSendPortCompleter.complete(message);
        }
      } else if (message is DocumentResponse) {
        final completer = pending.remove(message.id);
        if (completer != null && !completer.isCompleted) {
          message.when(
            error: (id, msg, stack) {
              final ex =
                  (msg.contains('DocumentOpenException') ||
                      msg.contains('not found') ||
                      msg.contains('No handler supports'))
                  ? DocumentOpenException(msg)
                  : DocumentParseException(msg);
              completer.completeError(
                ex,
                stack != null ? StackTrace.fromString(stack) : null,
              );
            },
            encryptedError: (id, msg, isInvalid) {
              completer.completeError(
                DocumentEncryptedException(msg, isInvalidPassword: isInvalid),
              );
            },
            opened: (_, _, _, _, _, _, _, _, _) => completer.complete(message),
            sectionHtml: (_, _) => completer.complete(message),
            sectionText: (_, _) => completer.complete(message),
            sectionSpeechText: (_, _) => completer.complete(message),
            footnoteResolved: (_, _) => completer.complete(message),
            assetLoaded: (_, _) => completer.complete(message),
            pageImageLoaded: (_, _) => completer.complete(message),
            pageSizeLoaded: (_, _) => completer.complete(message),
            sectionIndexResolved: (_, _) => completer.complete(message),
            assetPathResolved: (_, _) => completer.complete(message),
            disposed: (_) => completer.complete(message),
          );
        }
      }
    });

    final SendPort workerSendPort;
    try {
      workerSendPort = await workerSendPortCompleter.future.timeout(
        const Duration(seconds: 10),
      );
      _log.d('Isolate handshake completed for $filePath');
    } catch (e, st) {
      _log.e('Failed to establish isolate handshake for $filePath', error: e, stackTrace: st);
      await subscription.cancel();
      hostReceivePort.close();
      isolate.kill(priority: Isolate.immediate);
      throw DocumentOpenException('Failed to establish isolate handshake: $e');
    }

    final openCompleter = Completer<DocumentResponse>();
    final openId = nextId++;
    pending[openId] = openCompleter;

    workerSendPort.send(
      DocumentRequest.open(id: openId, filePath: filePath, password: password),
    );

    final DocumentResponse openResponse;
    try {
      openResponse = await openCompleter.future;
    } catch (e, st) {
      _log.e('Failed to open document in isolate: $filePath', error: e, stackTrace: st);
      await subscription.cancel();
      hostReceivePort.close();
      isolate.kill(priority: Isolate.immediate);
      if (e is DocumentException) rethrow;
      throw DocumentOpenException('Failed to open document in isolate: $e');
    }

    return openResponse.when(
      opened:
          (
            id,
            title,
            metadata,
            outline,
            sectionCount,
            pageCount,
            coverImagePath,
            isReflowable,
            format,
          ) {
            _log.i('Document session opened in isolate: $filePath (format: $format, title: "$title")');
            return IsolateDocumentSession._(
              isolate: isolate,
              workerSendPort: workerSendPort,
              hostReceivePort: hostReceivePort,
              subscription: subscription,
              pending: pending,
              nextRequestId: nextId,
              filePath: filePath,
              title: title,
              metadata: metadata,
              outline: outline,
              sectionCount: sectionCount,
              pageCount: pageCount,
              coverImagePath: coverImagePath,
              isReflowable: isReflowable,
              format: format,
            );
          },
      encryptedError: (id, message, isInvalidPassword) {
        _log.w('Document encrypted in isolate: $filePath (invalidPassword: $isInvalidPassword)');
        subscription.cancel();
        hostReceivePort.close();
        isolate.kill(priority: Isolate.immediate);
        throw DocumentEncryptedException(
          message,
          isInvalidPassword: isInvalidPassword,
        );
      },
      error: (id, message, stackTrace) {
        _log.e('Isolate returned error while opening $filePath: $message');
        subscription.cancel();
        hostReceivePort.close();
        isolate.kill(priority: Isolate.immediate);
        throw DocumentOpenException(
          'Failed to open document in isolate: $message',
        );
      },
      sectionHtml: (_, _) => throw StateError('Unexpected response'),
      sectionText: (_, _) => throw StateError('Unexpected response'),
      sectionSpeechText: (_, _) => throw StateError('Unexpected response'),
      footnoteResolved: (_, _) => throw StateError('Unexpected response'),
      assetLoaded: (_, _) => throw StateError('Unexpected response'),
      pageImageLoaded: (_, _) => throw StateError('Unexpected response'),
      pageSizeLoaded: (_, _) => throw StateError('Unexpected response'),
      sectionIndexResolved: (_, _) => throw StateError('Unexpected response'),
      assetPathResolved: (_, _) => throw StateError('Unexpected response'),
      disposed: (_) => throw StateError('Unexpected response'),
    );
  }

  Future<DocumentResponse> _send(
    DocumentRequest Function(int id) requestBuilder,
  ) {
    if (isDisposed) {
      throw StateError('IsolateDocumentSession has been disposed');
    }

    final id = _nextRequestId++;
    final completer = Completer<DocumentResponse>();
    _pending[id] = completer;
    final request = requestBuilder(id);
    _workerSendPort.send(request);
    return completer.future;
  }

  /// Loads HTML for the reflowable section at [sectionIndex].
  @override
  Future<String> loadSectionHtml(int sectionIndex) async {
    final res = await _send(
      (id) =>
          DocumentRequest.loadSectionHtml(id: id, sectionIndex: sectionIndex),
    );
    return res.maybeWhen(
      sectionHtml: (_, html) => html,
      orElse: () => throw DocumentParseException('Failed to load section HTML'),
    );
  }

  /// Extracts plain text for the section at [sectionIndex].
  @override
  Future<String> extractSectionText(int sectionIndex) async {
    final res = await _send(
      (id) => DocumentRequest.extractSectionText(
        id: id,
        sectionIndex: sectionIndex,
      ),
    );
    return res.maybeWhen(
      sectionText: (_, text) => text,
      orElse: () =>
          throw DocumentParseException('Failed to extract section text'),
    );
  }

  /// Extracts speech-normalized text for TTS at [sectionIndex].
  @override
  Future<String> extractSectionSpeechText(int sectionIndex) async {
    final res = await _send(
      (id) => DocumentRequest.extractSectionSpeechText(
        id: id,
        sectionIndex: sectionIndex,
      ),
    );
    return res.maybeWhen(
      sectionSpeechText: (_, speechText) => speechText,
      orElse: () =>
          throw DocumentParseException('Failed to extract speech text'),
    );
  }

  /// Resolves an in-document footnote URL.
  @override
  Future<FootnoteItem?> resolveFootnote(
    String url, {
    int? currentChapterIndex,
  }) async {
    final res = await _send(
      (id) => DocumentRequest.resolveFootnote(
        id: id,
        url: url,
        currentChapterIndex: currentChapterIndex,
      ),
    );
    return res.maybeWhen(
      footnoteResolved: (_, footnote) => footnote,
      orElse: () => null,
    );
  }

  /// Loads raw asset bytes with zero-copy [TransferableTypedData] across isolates.
  @override
  Future<Uint8List?> loadAsset(String assetPath, {int? sectionIndex}) async {
    final res = await _send(
      (id) => DocumentRequest.loadAsset(
        id: id,
        assetPath: assetPath,
        sectionIndex: sectionIndex,
      ),
    );
    return res.maybeWhen(
      assetLoaded: (_, assetData) => assetData?.materialize().asUint8List(),
      orElse: () => null,
    );
  }

  /// Loads a page image for fixed-layout documents (PDF, CBZ, CBT) with zero-copy [TransferableTypedData].
  @override
  Future<Uint8List> loadPageImage(
    int pageIndex, {
    double scale = 1.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    final res = await _send(
      (id) => DocumentRequest.loadPageImage(
        id: id,
        pageIndex: pageIndex,
        scale: scale,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      ),
    );
    return res.maybeWhen(
      pageImageLoaded: (_, imgData) {
        final bytes = imgData?.materialize().asUint8List();
        if (bytes == null) {
          throw DocumentParseException('Failed to load page image $pageIndex');
        }
        return bytes;
      },
      orElse: () =>
          throw DocumentParseException('Failed to load page image $pageIndex'),
    );
  }

  /// Queries the dimensions of [pageIndex] for fixed-layout documents.
  @override
  Future<PageSize?> getPageSize(int pageIndex) async {
    final res = await _send(
      (id) => DocumentRequest.getPageSize(id: id, pageIndex: pageIndex),
    );
    return res.maybeWhen(
      pageSizeLoaded: (_, pageSize) => pageSize,
      orElse: () => null,
    );
  }

  /// Resolves the chapter index corresponding to a link [href].
  @override
  Future<int?> resolveSectionIndex(String href) async {
    final res = await _send(
      (id) => DocumentRequest.resolveSectionIndex(id: id, href: href),
    );
    return res.maybeWhen(
      sectionIndexResolved: (_, sectionIndex) => sectionIndex,
      orElse: () => null,
    );
  }

  /// Resolves a relative asset path against [sectionIndex].
  @override
  Future<String> resolveAssetPath(int sectionIndex, String relativePath) async {
    final res = await _send(
      (id) => DocumentRequest.resolveAssetPath(
        id: id,
        sectionIndex: sectionIndex,
        relativePath: relativePath,
      ),
    );
    return res.maybeWhen(
      assetPathResolved: (_, resolvedPath) => resolvedPath,
      orElse: () => relativePath,
    );
  }

  @override
  Future<void> dispose() async {
    if (isDisposed) return;
    _log.d('Disposing IsolateDocumentSession for: $filePath');
    super.dispose();

    if (_pending.isNotEmpty) {
      for (final completer in _pending.values) {
        if (!completer.isCompleted) {
          completer.completeError(
            const DocumentDisposedException('Session disposed'),
          );
        }
      }
      _pending.clear();
    }

    final disposeId = _nextRequestId++;
    final disposeCompleter = Completer<DocumentResponse>();
    _pending[disposeId] = disposeCompleter;

    try {
      _workerSendPort.send(DocumentRequest.dispose(id: disposeId));
    } catch (_) {}

    try {
      await disposeCompleter.future.timeout(const Duration(seconds: 2));
    } catch (_) {}

    await _subscription.cancel();
    _hostReceivePort.close();
    _isolate.kill(priority: Isolate.immediate);
  }
}
