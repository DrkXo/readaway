import 'dart:async';
import 'dart:typed_data';

import '../abstracts/document_reader.dart';
import '../abstracts/page_document_reader.dart';
import '../abstracts/reflowable_document_reader.dart';
import '../lifecycle/disposable.dart';
import '../models/models.dart';
import '../readers/document_reader_factory.dart';
import '../readers/html_text_extractor.dart';
import '../transformers/transformers.dart';
import 'document_session.dart';

/// In-process document session implementation.
///
/// Used for PDF documents where pdfrx / PDFium already manages its own
/// native worker threads, avoiding cross-isolate native FFI callback issues.
class DirectDocumentSession with DisposableMixin implements DocumentSession {
  final DocumentReader _reader;

  @override
  final String filePath;

  DirectDocumentSession._(this._reader, this.filePath);

  static Future<DirectDocumentSession> open(
    String filePath, {
    String? password,
  }) async {
    final reader = await DocumentReaderFactory().open(
      filePath,
      password: password,
    );
    return DirectDocumentSession._(reader, filePath);
  }

  @override
  String? get title => _reader.title;

  @override
  DocumentMetadata? get metadata => _reader.metadata;

  @override
  List<OutlineItem> get outline => _reader.outline;

  @override
  int get sectionCount {
    final r = _reader;
    return r is ReflowableDocumentReader ? r.sectionCount : 0;
  }

  @override
  int get pageCount {
    final r = _reader;
    return r is PageDocumentReader ? r.pageCount : 0;
  }

  @override
  String? get coverImagePath => _reader.coverImagePath;

  @override
  bool get isReflowable => _reader.isReflowable;

  @override
  String get format => _reader.format;

  @override
  Future<String> loadSectionHtml(int sectionIndex) async {
    final r = _reader;
    if (r is! ReflowableDocumentReader) {
      throw StateError('Current document is not reflowable');
    }
    return r.loadSectionHtml(sectionIndex);
  }

  @override
  Future<String> extractSectionText(int sectionIndex) async {
    final r = _reader;
    if (r is! ReflowableDocumentReader) {
      throw StateError('Current document is not reflowable');
    }
    final html = r.loadSectionHtml(sectionIndex);
    return HtmlTextExtractor.extractPageText(html);
  }

  @override
  Future<String> extractSectionSpeechText(int sectionIndex) async {
    final r = _reader;
    if (r is ReflowableDocumentReader) {
      final html = r.loadSectionHtml(sectionIndex);
      return HtmlTextExtractor.extractSpeechText(html);
    }
    return '';
  }

  @override
  Future<FootnoteItem?> resolveFootnote(
    String url, {
    int? currentChapterIndex,
  }) async {
    final r = _reader;
    if (r is! ReflowableDocumentReader) return null;

    String? targetHref;
    String? anchorId;
    if (url.contains('#')) {
      final parts = url.split('#');
      targetHref = parts.first.trim().isEmpty ? null : parts.first.trim();
      anchorId = parts.length > 1 ? parts[1].trim() : null;
    } else {
      targetHref = url.trim();
    }

    if (anchorId == null || anchorId.isEmpty) return null;

    final targetIndex = targetHref != null && targetHref.isNotEmpty
        ? r.resolveSectionIndex(targetHref)
        : currentChapterIndex;

    if (targetIndex != null &&
        targetIndex >= 0 &&
        targetIndex < r.sectionCount) {
      final html = r.loadSectionHtml(targetIndex);
      return FootnoteTransformer.findFootnote(html, anchorId);
    }
    return null;
  }

  @override
  Future<Uint8List?> loadAsset(String assetPath, {int? sectionIndex}) async {
    return _reader.loadAsset(assetPath);
  }

  @override
  Future<Uint8List> loadPageImage(
    int pageIndex, {
    double scale = 1.0,
    int? targetWidth,
    int? targetHeight,
  }) async {
    final r = _reader;
    if (r is! PageDocumentReader) {
      throw StateError('Current document is not a fixed-layout page document');
    }
    return r.loadPageImage(
      pageIndex,
      scale: scale,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  @override
  Future<PageSize?> getPageSize(int pageIndex) async {
    final r = _reader;
    if (r is! PageDocumentReader) return null;
    return r.getPageSize(pageIndex);
  }

  @override
  Future<int?> resolveSectionIndex(String href) async {
    final r = _reader;
    if (r is! ReflowableDocumentReader) return null;
    return r.resolveSectionIndex(href);
  }

  @override
  Future<String> resolveAssetPath(int sectionIndex, String relativePath) async {
    final r = _reader;
    if (r is! ReflowableDocumentReader) return relativePath;
    return r.resolveAssetPath(
      sectionIndex,
      relativePath,
    );
  }

  @override
  Future<void> dispose() async {
    if (isDisposed) return;
    super.dispose();
    await _reader.dispose();
  }
}
