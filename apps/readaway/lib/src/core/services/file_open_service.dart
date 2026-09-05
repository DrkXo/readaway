import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

import '../models/reader/supported_document_formats.dart';
import 'logging_service.dart';

/// Represents an incoming document file received from the OS or CLI.
class IncomingDocument {
  final String path;
  final String fileName;

  const IncomingDocument({
    required this.path,
    required this.fileName,
  });

  @override
  String toString() => 'IncomingDocument(path: $path, fileName: $fileName)';
}

@singleton
class FileOpenService {
  static const MethodChannel _channel = MethodChannel('dev.readaway/file_opener');

  final LoggingService _loggingService;

  Logger get _log => _loggingService.logger;

  final PublishSubject<IncomingDocument> _incomingDocumentSubject =
      PublishSubject<IncomingDocument>();

  IncomingDocument? _pendingDocument;

  Stream<IncomingDocument> get incomingDocuments =>
      _incomingDocumentSubject.stream;

  IncomingDocument? get pendingDocument => _pendingDocument;

  FileOpenService({
    required LoggingService loggingService,
  }) : _loggingService = loggingService; // ignore: prefer_initializing_formals

  /// Initializes native platform channel handlers (for Android, iOS, macOS).
  @PostConstruct(preResolve: true)
  Future<void> init() async {
    await initializePlatformChannel();
  }

  /// Inspects command-line arguments (from desktop launch) and queues any supported document.
  void initializeWithArgs(List<String> args) {
    if (args.isEmpty) return;

    for (final rawArg in args) {
      // Strip out options / flags like -v, --debug, etc.
      if (rawArg.startsWith('-')) continue;

      var cleaned = rawArg.trim();
      // Handle file:// URIs passed on some Linux desktop launchers
      if (cleaned.startsWith('file://')) {
        final uri = Uri.tryParse(cleaned);
        if (uri != null && uri.toFilePath().isNotEmpty) {
          cleaned = uri.toFilePath();
        }
      }

      // Check if file exists on disk
      try {
        final file = File(cleaned);
        if (file.existsSync()) {
          final fileName = p.basename(cleaned);
          _log.info('[FileOpenService] Detected CLI argument file: $cleaned');
          queueDocument(IncomingDocument(path: file.absolute.path, fileName: fileName));
          break;
        }
      } catch (e) {
        _log.warning('[FileOpenService] Error checking CLI arg "$cleaned": $e');
      }
    }
  }

  /// Initializes native platform channel handlers (for Android, iOS, macOS).
  Future<void> initializePlatformChannel() async {
    if (kIsWeb) return;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'openFile':
          final args = call.arguments;
          if (args is Map) {
            final path = args['path'] as String?;
            final fileName = (args['fileName'] as String?) ??
                (path != null ? p.basename(path) : null);
            if (path != null && path.isNotEmpty) {
              _log.info('[FileOpenService] Received runtime openFile: $path');
              queueDocument(IncomingDocument(
                path: path,
                fileName: fileName ?? p.basename(path),
              ));
            }
          }
          break;
        default:
          _log.warning('[FileOpenService] Unhandled platform call: ${call.method}');
      }
    });

    try {
      final initial = await _channel.invokeMethod<Map>('getInitialFile');
      if (initial != null) {
        final path = initial['path'] as String?;
        final fileName = (initial['fileName'] as String?) ??
            (path != null ? p.basename(path) : null);
        if (path != null && path.isNotEmpty) {
          _log.info('[FileOpenService] Received initial file from native: $path');
          queueDocument(IncomingDocument(
            path: path,
            fileName: fileName ?? p.basename(path),
          ));
        }
      }
    } on MissingPluginException {
      // Platform channels not implemented on this platform or test runner; safe to ignore.
    } catch (e) {
      _log.warning('[FileOpenService] Error fetching initial file: $e');
    }
  }

  /// Consumes and returns the cold-start pending document, if any.
  IncomingDocument? consumePendingDocument() {
    final doc = _pendingDocument;
    _pendingDocument = null;
    return doc;
  }

  /// Queues an incoming document and emits it to [incomingDocuments].
  void queueDocument(IncomingDocument doc) {
    if (!SupportedDocumentFormats.isSupported(doc.path)) {
      _log.warning(
        '[FileOpenService] Document format not supported for path: ${doc.path}',
      );
    }

    _pendingDocument = doc;
    _incomingDocumentSubject.add(doc);
  }

  @disposeMethod
  void dispose() {
    _incomingDocumentSubject.close();
  }
}
