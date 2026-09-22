import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../errors/document_exception.dart';
import '../lifecycle/disposable.dart';
import '../models/models.dart';
import 'document_isolate_messages.dart';
import 'document_isolate_worker.dart';

/// Client proxy managing an active document session inside a dedicated background isolate.
class IsolateDocumentSession with DisposableMixin implements Disposable {
  final Isolate _isolate;
  final SendPort _workerSendPort;
  final ReceivePort _hostReceivePort;
  final StreamSubscription<dynamic> _subscription;
  final Map<int, Completer<DocumentResponse>> _pending;
  int _nextRequestId;

  final String filePath;
  final String? title;
  final DocumentMetadata? metadata;
  final List<OutlineItem> outline;
  final int sectionCount;
  final int pageCount;
  final String? coverImagePath;
  final bool isReflowable;
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
              final ex = (msg.contains('DocumentOpenException') || msg.contains('not found') || msg.contains('No handler supports'))
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
    } catch (e) {
      await subscription.cancel();
      hostReceivePort.close();
      isolate.kill(priority: Isolate.immediate);
      throw DocumentOpenException('Failed to establish isolate handshake: $e');
    }

    final openCompleter = Completer<DocumentResponse>();
    final openId = nextId++;
    pending[openId] = openCompleter;

    workerSendPort.send(DocumentRequest.open(
      id: openId,
      filePath: filePath,
      password: password,
    ));

    final DocumentResponse openResponse;
    try {
      openResponse = await openCompleter.future;
    } catch (e) {
      await subscription.cancel();
      hostReceivePort.close();
      isolate.kill(priority: Isolate.immediate);
      if (e is DocumentException) rethrow;
      throw DocumentOpenException('Failed to open document in isolate: $e');
    }

    return openResponse.when(
      opened: (
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
        subscription.cancel();
        hostReceivePort.close();
        isolate.kill(priority: Isolate.immediate);
        throw DocumentEncryptedException(
          message,
          isInvalidPassword: isInvalidPassword,
        );
      },
      error: (id, message, stackTrace) {
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
      orElse: () => throw DocumentParseException('Failed to load page image $pageIndex'),
    );
  }

  /// Queries the dimensions of [pageIndex] for fixed-layout documents.
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
  void dispose() {
    if (isDisposed) return;
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

    disposeCompleter.future
        .timeout(const Duration(seconds: 2))
        .whenComplete(() {
      _subscription.cancel();
      _hostReceivePort.close();
      _isolate.kill(priority: Isolate.beforeNextEvent);
    }).ignore();
  }
}
