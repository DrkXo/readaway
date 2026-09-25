import 'dart:io';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:readaway_core/readaway_core.dart';
import 'package:share_plus/share_plus.dart';

/// Handler type definition for invoking share operations (allows mocking in tests).
typedef ShareHandler = Future<ShareResult> Function(ShareParams params);

/// Handler type definition for resolving temporary directories.
typedef TempDirectoryProvider = Future<Directory> Function();

/// Core application service responsible for sharing document files, extracted page images, and text snippets.
@lazySingleton
class ShareService {
  final ShareHandler _shareHandler;
  final TempDirectoryProvider _tempDirectoryProvider;
  final _log = AppLogger.instance.scope('ShareService');

  @factoryMethod
  ShareService()
    : _shareHandler = _defaultShareHandler,
      _tempDirectoryProvider = _defaultTempDirectoryProvider;

  ShareService.withHandler({
    required this._shareHandler,
    TempDirectoryProvider? tempDirectoryProvider,
  }) : _tempDirectoryProvider =
           tempDirectoryProvider ?? _defaultTempDirectoryProvider;

  static Future<Directory> _defaultTempDirectoryProvider() async {
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  static Future<ShareResult> _defaultShareHandler(ShareParams params) {
    return SharePlus.instance.share(params);
  }

  /// Shares an entire document file at [filePath] using the system share sheet.
  Future<bool> shareDocumentFile({
    required String filePath,
    String? title,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        _log.w('Cannot share non-existent document file: $filePath');
        return false;
      }

      final fileName = title ?? p.basename(filePath);
      _log.i('Sharing document file: $filePath');
      final result = await _shareHandler(
        ShareParams(
          files: [XFile(filePath, name: fileName)],
          subject: fileName,
          text: fileName,
        ),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (e, st) {
      _log.e(
        'Failed to share document file: $filePath',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Shares a rasterized page image from [imageBytes].
  Future<bool> sharePageImage({
    required String filePath,
    required int pageIndex,
    required int totalPages,
    required Uint8List imageBytes,
    String? title,
  }) async {
    try {
      if (imageBytes.isEmpty) {
        _log.w('Cannot share empty page image for page $pageIndex');
        return false;
      }

      final tempDir = await _tempDirectoryProvider();
      final baseDocName = p.basenameWithoutExtension(filePath);
      final displayDocTitle = title ?? baseDocName;
      final displayPageNumber = pageIndex + 1;

      final sanitizedDocName = baseDocName.replaceAll(
        RegExp(r'[^\w\-_]+'),
        '_',
      );
      final tempFile = File(
        p.join(tempDir.path, '${sanitizedDocName}_page_$displayPageNumber.png'),
      );
      await tempFile.writeAsBytes(imageBytes, flush: true);

      final shareTitle = '$displayDocTitle - Page $displayPageNumber';
      final shareText =
          'Page $displayPageNumber of $totalPages from "$displayDocTitle"';

      _log.i('Sharing page $displayPageNumber image: ${tempFile.path}');
      final result = await _shareHandler(
        ShareParams(
          files: [
            XFile(
              tempFile.path,
              mimeType: 'image/png',
              name: '${sanitizedDocName}_page_$displayPageNumber.png',
            ),
          ],
          subject: shareTitle,
          text: shareText,
        ),
      );

      return result.status != ShareResultStatus.unavailable;
    } catch (e, st) {
      _log.e(
        'Failed to share page image for page $pageIndex',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Shares raw image bytes with a custom [fileName].
  Future<bool> shareImageBytes({
    required Uint8List imageBytes,
    required String fileName,
    String? subject,
    String? text,
  }) async {
    try {
      if (imageBytes.isEmpty) {
        _log.w('Cannot share empty image bytes: $fileName');
        return false;
      }

      final tempDir = await _tempDirectoryProvider();
      final tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(imageBytes, flush: true);

      final result = await _shareHandler(
        ShareParams(
          files: [
            XFile(
              tempFile.path,
              mimeType: 'image/png',
              name: fileName,
            ),
          ],
          subject: subject ?? fileName,
          text: text,
        ),
      );

      return result.status != ShareResultStatus.unavailable;
    } catch (e, st) {
      _log.e(
        'Failed to share image bytes: $fileName',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Shares a plain text snippet with optional [subject].
  Future<bool> shareText(String text, {String? subject}) async {
    try {
      final result = await _shareHandler(
        ShareParams(
          text: text,
          subject: subject,
        ),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (e, st) {
      _log.e('Failed to share text', error: e, stackTrace: st);
      return false;
    }
  }
}
