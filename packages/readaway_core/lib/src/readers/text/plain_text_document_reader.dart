import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../abstracts/reflowable_document_reader.dart';
import '../../errors/document_exception.dart';
import '../../models/models.dart';
import '../../transformers/text_transform_pipeline.dart';
import 'encoding_detector.dart';
import 'txt_chapter_extractor.dart';
import 'txt_metadata_extractor.dart';

/// Reads a plain-text document, automatically detecting character encoding,
/// parsing book metadata from filename/header, segmenting content into chapters,
/// and applying natural reading transformations to each section.
class PlainTextDocumentReader implements ReflowableDocumentReader {
  final String _filePath;
  final TxtMetadata _txtMetadata;
  final List<TxtChapter> _chapters;
  final List<DocumentSection> _sections;
  final List<OutlineItem> _outline;
  final TextTransformPipeline _pipeline;
  bool _disposed = false;

  PlainTextDocumentReader._({
    required this._filePath,
    required TxtMetadata metadata,
    required this._chapters,
    required this._sections,
    required this._outline,
    this._pipeline = TextTransformPipeline.defaultPipeline,
  }) : _txtMetadata = metadata;

  /// Opens a plain-text document from [filePath].
  static Future<PlainTextDocumentReader> fromFile(
    String filePath, {
    TextTransformPipeline pipeline = TextTransformPipeline.defaultPipeline,
    int fallbackParagraphsPerChapter = 100,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentOpenException('Text file not found: $filePath');
    }
    final bytes = file.readAsBytesSync();
    return fromBytes(
      bytes,
      filePath: filePath,
      pipeline: pipeline,
      fallbackParagraphsPerChapter: fallbackParagraphsPerChapter,
    );
  }

  /// Opens a plain-text document from in-memory [bytes].
  static Future<PlainTextDocumentReader> fromBytes(
    Uint8List bytes, {
    String filePath = 'untitled.txt',
    TextTransformPipeline pipeline = TextTransformPipeline.defaultPipeline,
    int fallbackParagraphsPerChapter = 100,
  }) async {
    final detectedEncoding = EncodingDetector.detect(bytes);
    final text = EncodingDetector.decode(bytes, detected: detectedEncoding);

    final headerSample = text.length > 2048 ? text.substring(0, 2048) : text;
    final metadata = TxtMetadataExtractor.extract(
      filePath: filePath,
      headerText: headerSample,
      encoding: detectedEncoding.name,
    );

    final extractor = TxtChapterExtractor(
      fallbackParagraphsPerChapter: fallbackParagraphsPerChapter,
    );
    final chapters = extractor.extractChapters(text);

    final hasVolumes = chapters.any((c) => c.isVolume);

    final sections = <DocumentSection>[];
    final outline = <OutlineItem>[];

    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      final href = 'chapter_$i.html';

      sections.add(
        DocumentSection(
          index: i,
          id: 'chapter_$i',
          href: href,
          mediaType: 'text/html',
          title: ch.title,
        ),
      );

      final level = (hasVolumes && !ch.isVolume) ? 1 : 0;
      outline.add(
        OutlineItem(
          title: ch.title,
          href: href,
          level: level,
          chapterIndex: i,
        ),
      );
    }

    return PlainTextDocumentReader._(
      filePath: filePath,
      metadata: metadata,
      chapters: chapters,
      sections: sections,
      outline: outline,
      pipeline: pipeline,
    );
  }

  @override
  String get format => 'txt';

  @override
  bool get isReflowable => true;

  @override
  String? get title => _txtMetadata.title;

  @override
  DocumentMetadata? get metadata => DocumentMetadata(
        title: _txtMetadata.title,
        creator: _txtMetadata.author,
        language: _txtMetadata.language,
      );

  @override
  List<OutlineItem> get outline => _outline;

  @override
  String? get coverImagePath => null;

  @override
  int get sectionCount => _sections.length;

  @override
  List<DocumentSection> get sections => _sections;

  @override
  String loadSectionHtml(int index) {
    _checkNotDisposed();
    if (index < 0 || index >= _chapters.length) {
      throw RangeError.range(
        index,
        0,
        _chapters.length - 1,
        'index',
        'chapter index out of bounds',
      );
    }

    final rawHtml = _chapters[index].contentHtml;
    final ctx = TransformContext(
      content: rawHtml,
      language: _txtMetadata.language,
    );
    return _pipeline.transform(ctx);
  }

  @override
  Uint8List? loadAsset(String assetPath) => null;

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) =>
      relativeHref;

  @override
  int? resolveSectionIndex(String href) {
    if (href.isEmpty) return null;
    final clean = href.split('#').first.split('?').first;
    if (clean.isEmpty) return null;

    // Direct chapter href match (e.g. chapter_0.html)
    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].href == clean) return i;
    }

    // Matching base filename resolves to first section
    if (p.basename(clean) == p.basename(_filePath)) return 0;

    return null;
  }

  @override
  void dispose() {
    _disposed = true;
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw DocumentDisposedException(
        'PlainTextDocumentReader has been disposed',
      );
    }
  }
}
