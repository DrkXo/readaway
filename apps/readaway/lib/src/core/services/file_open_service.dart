import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';
import 'package:rxdart/rxdart.dart';

import '../models/document_format.dart';

/// Represents an incoming document file received from the OS or CLI.
class IncomingDocument {
  final String path;
  final String fileName;

  /// True when this document was delivered on cold-start via an external
  /// intent (Android `getInitialSharedUris`, `getInitialLink`, macOS initial
  /// file, or CLI args). False when the app was already running and a new
  /// file arrived while in the foreground (`onSharedUrisReceived`, stream
  /// links). Used by the router to decide whether closing the reader should
  /// return to the calling app (`SystemNavigator.pop`) or to the library.
  final bool fromExternalLaunch;

  const IncomingDocument({
    required this.path,
    required this.fileName,
    this.fromExternalLaunch = false,
  });

  @override
  String toString() =>
      'IncomingDocument(path: $path, fileName: $fileName, fromExternalLaunch: $fromExternalLaunch)';
}

/// Captures file/deep-links from the OS ([AppLinks]) and turns them into real
/// filesystem paths the reader can open. Android `content://` URIs are
/// materialized into the app cache via a tiny native resolver.
@singleton
class FileOpenService {
  final _log = AppLogger.instance.scope('FileOpenService');

  static const MethodChannel _contentResolver = MethodChannel(
    'dev.readaway/content_resolver',
  );

  // macOS only: Finder "Open With"/LaunchServices hands real paths to the
  // native AppDelegate, which forwards them over this channel.
  static const MethodChannel _macOsBridge = MethodChannel(
    'dev.readaway/file_opener',
  );

  // Replays startup-queued documents (CLI args, initial links) to the first
  // listener: the router subscribes after the first frame, but documents can
  // be queued before runApp on desktop cold-starts.
  final ReplaySubject<IncomingDocument> _incomingDocumentSubject =
      ReplaySubject<IncomingDocument>(maxSize: 1);

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;

  Stream<IncomingDocument> get incomingDocuments =>
      _incomingDocumentSubject.stream;

  FileOpenService();

  /// Wires up OS file-open forwarding (mobile deep links + macOS Finder + Android share/send intents).
  @PostConstruct(preResolve: true)
  Future<void> init() async {
    await _listenForAppLinks();
    await _listenForMacOsFileOpens();
    await _listenForAndroidSendIntents();
  }

  static String _sanitizePath(String raw) {
    var cleaned = raw.trim();
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      if (cleaned.length >= 2) {
        cleaned = cleaned.substring(1, cleaned.length - 1).trim();
      }
    }
    if (cleaned.startsWith('file://') || cleaned.startsWith('file:')) {
      final uri = Uri.tryParse(cleaned);
      if (uri != null) {
        try {
          final filePath = uri.toFilePath();
          if (filePath.isNotEmpty) {
            cleaned = filePath;
          }
        } catch (_) {
          cleaned = Uri.decodeFull(uri.path);
        }
      }
    }
    return cleaned;
  }

  /// Inspects command-line arguments (from desktop launch) and queues any
  /// supported document.
  void initializeWithArgs(List<String> args) {
    if (args.isEmpty) return;

    for (final rawArg in args) {
      // Strip out options / flags like -v, --debug, etc.
      if (rawArg.startsWith('-')) continue;

      final cleaned = _sanitizePath(rawArg);
      if (cleaned.isEmpty) continue;

      // Check if file exists on disk (try sanitized path and fully decoded path)
      try {
        File file = File(cleaned);
        if (!file.existsSync()) {
          final decoded = Uri.decodeFull(cleaned);
          if (decoded != cleaned) {
            final decodedFile = File(decoded);
            if (decodedFile.existsSync()) {
              file = decodedFile;
            }
          }
        }

        if (file.existsSync()) {
          final fileName = p.basename(file.path);
          _log.i('Detected CLI argument file: ${file.path}');
          queueDocument(
            IncomingDocument(
              path: file.absolute.path,
              fileName: fileName,
              fromExternalLaunch: true,
            ),
          );
          break;
        }
      } catch (e, st) {
        _log.w('Error checking CLI arg "$cleaned"', error: e, stackTrace: st);
      }
    }
  }

  Future<void> _listenForAppLinks() async {
    if (kIsWeb) return;
    try {
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) => handleUri(uri, fromExternalLaunch: true),
      );
      // Don't block DI: let the router mount first so the initial push lands.
      unawaited(() async {
        final initial = await _appLinks.getInitialLink();
        if (initial != null) {
          await handleUri(initial, fromExternalLaunch: true);
        }
      }());
    } catch (e, st) {
      _log.w('app_links unavailable', error: e, stackTrace: st);
    }
  }

  Future<void> _listenForMacOsFileOpens() async {
    if (kIsWeb || !Platform.isMacOS) return;
    try {
      _macOsBridge.setMethodCallHandler(
        (call) async {
          if (call.method == 'openFile') {
            final args = call.arguments;
            if (args is Map) {
              final path = args['path'] as String?;
              if (path != null && path.isNotEmpty) {
                queueDocument(
                  IncomingDocument(
                    path: path,
                    fileName: (args['fileName'] as String?) ?? p.basename(path),
                    fromExternalLaunch: true,
                  ),
                );
              }
            }
          }
        },
      );

      unawaited(() async {
        final initial = await _macOsBridge.invokeMethod<Map>(
          'getInitialFile',
        );
        if (initial != null) {
          final path = initial['path'] as String?;
          if (path != null && path.isNotEmpty) {
            queueDocument(
              IncomingDocument(
                path: path,
                fileName: (initial['fileName'] as String?) ?? p.basename(path),
                fromExternalLaunch: true,
              ),
            );
          }
        }
      }());
    } catch (e, st) {
      _log.w('macOS file-open bridge unavailable', error: e, stackTrace: st);
    }
  }

  Future<void> _listenForAndroidSendIntents() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      _contentResolver.setMethodCallHandler((call) async {
        if (call.method == 'onSharedUrisReceived') {
          final uris = call.arguments;
          if (uris is List) {
            for (final uriStr in uris) {
              if (uriStr is String && uriStr.isNotEmpty) {
                final uri = Uri.tryParse(uriStr);
                if (uri != null) {
                  await handleUri(uri, fromExternalLaunch: true);
                }
              }
            }
          }
        }
      });

      unawaited(() async {
        final initialUris = await _contentResolver.invokeMethod<List>(
          'getInitialSharedUris',
        );
        if (initialUris != null) {
          for (final uriStr in initialUris) {
            if (uriStr is String && uriStr.isNotEmpty) {
              final uri = Uri.tryParse(uriStr);
              if (uri != null) {
                await handleUri(uri, fromExternalLaunch: true);
              }
            }
          }
        }
      }());
    } catch (e, st) {
      _log.w(
        'Android send intent bridge unavailable',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Converts an OS-supplied [uri] into a real path and queues it.
  ///
  /// [fromExternalLaunch] should be `true` only when this URI arrived during
  /// cold-start (initial intent / initial link), so the reader knows to
  /// finish the Activity on close rather than navigate back to the library.
  Future<void> handleUri(Uri uri, {bool fromExternalLaunch = false}) async {
    if (_incomingDocumentSubject.isClosed) return;
    String path;
    final String fileName;

    if (uri.scheme == 'content') {
      // Android scoped-storage content:// URI: ask native to copy it to cache.
      try {
        final resolved = await _contentResolver.invokeMethod<Map>(
          'materialize',
          uri.toString(),
        );
        path = resolved?['path'] as String? ?? '';
        fileName =
            (resolved?['fileName'] as String?) ??
            (path.isNotEmpty ? p.basename(path) : 'document');
      } on PlatformException catch (e, st) {
        _log.w(
          'Failed to materialize $uri: ${e.message}',
          error: e,
          stackTrace: st,
        );
        return;
      }
    } else if (uri.scheme == 'file') {
      try {
        path = uri.toFilePath();
      } catch (_) {
        path = Uri.decodeFull(uri.path);
      }
      fileName = p.basename(path);
    } else {
      // app_links on Linux/Windows forwards raw command-line paths (e.g.
      // /home/u/doc.epub or C:/docs/a.epub) which parse with an empty or
      // single-letter scheme. Treat them as files when they actually exist.
      var candidate = (uri.scheme.length == 1) ? uri.toString() : uri.path;
      candidate = _sanitizePath(candidate);
      File file = File(candidate);
      if (!file.existsSync()) {
        final decoded = Uri.decodeFull(candidate);
        if (decoded != candidate) {
          final decodedFile = File(decoded);
          if (decodedFile.existsSync()) {
            file = decodedFile;
          }
        }
      }

      if (candidate.isEmpty || !file.existsSync()) {
        _log.w('Ignoring non-file link: $uri');
        return;
      }
      path = file.absolute.path;
      fileName = p.basename(path);
    }

    if (path.isEmpty) return;
    _log.i('Opening document: $path');
    queueDocument(
      IncomingDocument(
        path: path,
        fileName: fileName,
        fromExternalLaunch: fromExternalLaunch,
      ),
    );
  }

  /// Queues an incoming document and emits it to [incomingDocuments].
  void queueDocument(IncomingDocument doc) {
    if (!SupportedDocumentFormats.isSupported(doc.path)) {
      _log.w('Document format not supported for path: ${doc.path}');
    }

    _incomingDocumentSubject.add(doc);
  }

  @disposeMethod
  void dispose() {
    _linkSubscription?.cancel();
    _incomingDocumentSubject.close();
  }
}
