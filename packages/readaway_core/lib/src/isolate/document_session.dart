import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../lifecycle/disposable.dart';
import '../models/models.dart';
import 'direct_document_session.dart';
import 'isolate_document_session.dart';

/// Unified contract for an open document session (either running in a dedicated
/// background isolate or in-process).
abstract class DocumentSession with DisposableMixin implements Disposable {
  String get filePath;
  String? get title;
  DocumentMetadata? get metadata;
  List<OutlineItem> get outline;
  int get sectionCount;
  int get pageCount;
  String? get coverImagePath;
  bool get isReflowable;
  String get format;

  Future<String> loadSectionHtml(int sectionIndex);
  Future<String> extractSectionText(int sectionIndex);
  Future<String> extractSectionSpeechText(int sectionIndex);
  Future<FootnoteItem?> resolveFootnote(String url, {int? currentChapterIndex});
  Future<Uint8List?> loadAsset(String assetPath, {int? sectionIndex});
  Future<Uint8List> loadPageImage(
    int pageIndex, {
    double scale = 1.0,
    int? targetWidth,
    int? targetHeight,
  });
  Future<PageSize?> getPageSize(int pageIndex);
  Future<int?> resolveSectionIndex(String href);
  Future<String> resolveAssetPath(int sectionIndex, String relativePath);

  /// Automatically opens the document via [DirectDocumentSession] for PDF
  /// (to prevent multi-isolate native FFI callback collisions with PDFium)
  /// or [IsolateDocumentSession] for reflowables and comic archives.
  static Future<DocumentSession> open(
    String filePath, {
    String? password,
  }) async {
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.pdf') {
      return DirectDocumentSession.open(filePath, password: password);
    }
    return IsolateDocumentSession.open(filePath, password: password);
  }
}
