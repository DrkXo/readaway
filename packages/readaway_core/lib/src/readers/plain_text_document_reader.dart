import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../abstracts/reflowable_document_reader.dart';
import '../errors/document_exception.dart';
import '../lifecycle/disposable.dart';
import '../models/models.dart';

/// Reads a plain-text document, automatically detecting character encoding,
/// parsing book metadata from filename/header, segmenting content into chapters,
/// and presenting them as reflowable HTML sections.
class PlainTextDocumentReader
    with DisposableMixin
    implements ReflowableDocumentReader {
  final String _filePath;
  final TxtMetadata _txtMetadata;
  final List<TxtChapter> _chapters;
  final List<DocumentSection> _sections;
  final List<OutlineItem> _outline;

  PlainTextDocumentReader._({
    required this._filePath,
    required TxtMetadata metadata,
    required List<TxtChapter> chapters,
    required List<DocumentSection> sections,
    required List<OutlineItem> outline,
  }) : _txtMetadata = metadata,
       _chapters = List.unmodifiable(chapters),
       _sections = List.unmodifiable(sections),
       _outline = List.unmodifiable(outline);

  /// Opens a plain-text document from [filePath].
  static Future<PlainTextDocumentReader> fromFile(
    String filePath, {
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
      fallbackParagraphsPerChapter: fallbackParagraphsPerChapter,
    );
  }

  /// Opens a plain-text document from in-memory [bytes].
  static Future<PlainTextDocumentReader> fromBytes(
    Uint8List bytes, {
    String filePath = 'untitled.txt',
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
          title: ch.title,
        ),
      );

      final level = (hasVolumes && !ch.isVolume) ? 1 : 0;
      outline.add(OutlineItem(title: ch.title, href: href, level: level));
    }

    return PlainTextDocumentReader._(
      filePath: filePath,
      metadata: metadata,
      chapters: chapters,
      sections: sections,
      outline: outline,
    );
  }

  @override
  String get format => 'txt';

  @override
  bool get isReflowable => true;

  @override
  String? get title => _txtMetadata.title;

  @override
  DocumentMetadata? get metadata => DocumentMetadata.normalized(
    title: _txtMetadata.title,
    author: _txtMetadata.author,
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
    checkNotDisposed('loadSectionHtml');
    if (index < 0 || index >= _chapters.length) {
      throw RangeError.range(
        index,
        0,
        _chapters.length - 1,
        'index',
        'chapter index out of bounds',
      );
    }
    return _chapters[index].contentHtml;
  }

  @override
  Uint8List? loadAsset(String assetPath) {
    if (isDisposed) return null;
    return null;
  }

  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) =>
      relativeHref;

  @override
  int? resolveSectionIndex(String href) {
    if (href.isEmpty) return null;
    final clean = href.split('#').first.split('?').first;
    if (clean.isEmpty) return null;

    for (int i = 0; i < _sections.length; i++) {
      if (_sections[i].href == clean) return i;
    }

    if (p.basename(clean) == p.basename(_filePath)) return 0;
    return null;
  }
}

/// Detects character encodings of text files and decodes them into Dart Strings.
class EncodingDetector {
  const EncodingDetector._();

  static const int _headSampleSize = 64 * 1024;
  static const int _midSampleSize = 8192;

  static DetectedEncoding detect(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const DetectedEncoding(
        name: 'utf-8',
        confidence: 1.0,
        hasBom: false,
      );
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xef &&
        bytes[1] == 0xbb &&
        bytes[2] == 0xbf) {
      return const DetectedEncoding(
        name: 'utf-8',
        confidence: 1.0,
        hasBom: true,
      );
    }

    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) {
      return const DetectedEncoding(
        name: 'utf-16le',
        confidence: 1.0,
        hasBom: true,
      );
    }

    if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
      return const DetectedEncoding(
        name: 'utf-16be',
        confidence: 1.0,
        hasBom: true,
      );
    }

    final headLen = bytes.length < _headSampleSize
        ? bytes.length
        : _headSampleSize;
    final headSample = Uint8List.sublistView(bytes, 0, headLen);

    bool isStrictUtf8 = true;
    try {
      utf8.decode(headSample);
      if (bytes.length > _headSampleSize * 2) {
        final midStart = (bytes.length - _midSampleSize) ~/ 2;
        final midSample = Uint8List.sublistView(
          bytes,
          midStart,
          midStart + _midSampleSize,
        );
        utf8.decode(midSample);
      }
    } catch (_) {
      isStrictUtf8 = false;
    }

    if (isStrictUtf8) {
      return const DetectedEncoding(
        name: 'utf-8',
        confidence: 0.99,
        hasBom: false,
      );
    }

    int highByteCount = 0;
    final sampleSize = headSample.length < 4096 ? headSample.length : 4096;
    for (int i = 0; i < sampleSize; i++) {
      if (headSample[i] >= 0x80) highByteCount++;
    }
    final highByteRatio = sampleSize > 0 ? highByteCount / sampleSize : 0.0;

    if (highByteRatio > 0.1) {
      bool sjisPattern = false;
      for (int i = 0; i < sampleSize - 1; i++) {
        final b1 = headSample[i];
        final b2 = headSample[i + 1];
        if (((b1 >= 0x81 && b1 <= 0x9f) || (b1 >= 0xe0 && b1 <= 0xfc)) &&
            ((b2 >= 0x40 && b2 <= 0x7e) || (b2 >= 0x80 && b2 <= 0xfc))) {
          sjisPattern = true;
          break;
        }
      }

      if (sjisPattern) {
        return const DetectedEncoding(
          name: 'shift-jis',
          confidence: 0.85,
          hasBom: false,
        );
      }

      if (highByteRatio > 0.3) {
        return const DetectedEncoding(
          name: 'gbk',
          confidence: 0.88,
          hasBom: false,
        );
      }
    }

    return const DetectedEncoding(
      name: 'utf-8',
      confidence: 0.75,
      hasBom: false,
    );
  }

  static String decode(Uint8List bytes, {DetectedEncoding? detected}) {
    final encoding = detected ?? detect(bytes);

    switch (encoding.name.toLowerCase()) {
      case 'utf-16le':
        final skip = encoding.hasBom ? 2 : 0;
        final actualBytes = bytes.sublist(skip);
        final charCodes = <int>[];
        for (int i = 0; i + 1 < actualBytes.length; i += 2) {
          charCodes.add(actualBytes[i] | (actualBytes[i + 1] << 8));
        }
        return String.fromCharCodes(charCodes);

      case 'utf-16be':
        final skip = encoding.hasBom ? 2 : 0;
        final actualBytes = bytes.sublist(skip);
        final charCodes = <int>[];
        for (int i = 0; i + 1 < actualBytes.length; i += 2) {
          charCodes.add((actualBytes[i] << 8) | actualBytes[i + 1]);
        }
        return String.fromCharCodes(charCodes);

      case 'utf-8':
      default:
        final skip = encoding.hasBom && bytes.length >= 3 ? 3 : 0;
        final actualBytes = skip > 0 ? bytes.sublist(skip) : bytes;
        return utf8.decode(actualBytes, allowMalformed: true);
    }
  }
}

/// Extracts book metadata (title, author) from plain text filenames and header content.
class TxtMetadataExtractor {
  const TxtMetadataExtractor._();

  static final RegExp _authorHeaderRegex = RegExp(
    r'[【\[]?\s*(?:作者|author)\s*[】\]]?\s*[:：\s]\s*([^\r\n]+)',
    caseSensitive: false,
  );

  static final RegExp _authorZhuRegex = RegExp(
    r'[【\[]?\s*([^\r\n]+?)\s*著\s*[】\]]?(?:\r?\n|$)',
    caseSensitive: false,
  );

  static TxtMetadata extract({
    required String filePath,
    required String headerText,
    required String encoding,
  }) {
    final filename = p.basenameWithoutExtension(filePath);
    final filenameMeta = _extractFromFilename(filename);

    final headerAuthor = _extractAuthorFromHeader(headerText);
    final author = headerAuthor ?? filenameMeta.author;
    final title = filenameMeta.title;

    return TxtMetadata(
      title: title,
      author: author,
      encoding: encoding,
      language: _detectLanguage(headerText),
    );
  }

  static ({String title, String? author}) _extractFromFilename(
    String filename,
  ) {
    final cjkBookMatch = RegExp(r'《([^》]+)》(.*)').firstMatch(filename);
    if (cjkBookMatch != null) {
      final title = cjkBookMatch.group(1)!.trim();
      final rest = cjkBookMatch.group(2)?.trim() ?? '';
      return (title: title, author: _parseAuthorFragment(rest));
    }

    final bracketMatch = RegExp(r'【([^】]+)】(.*)').firstMatch(filename);
    if (bracketMatch != null) {
      final title = bracketMatch.group(1)!.trim();
      final rest = bracketMatch.group(2)?.trim() ?? '';
      return (title: title, author: _parseAuthorFragment(rest));
    }

    final dashMatch = RegExp(r'^(.*?)\s+[-–—]\s+(.*?)$').firstMatch(filename);
    if (dashMatch != null) {
      final title = dashMatch.group(1)!.trim();
      final author = _stripWrappingPunctuation(dashMatch.group(2)!.trim());
      if (_isPlausibleAuthor(author)) {
        return (title: title, author: author);
      }
    }

    return (title: filename, author: null);
  }

  static String? _parseAuthorFragment(String text) {
    if (text.isEmpty) return null;

    final labeled = RegExp(r'作者\s*[：:\s]\s*(.+)$').firstMatch(text);
    if (labeled != null) {
      final candidate = _stripWrappingPunctuation(labeled.group(1)!);
      return _isPlausibleAuthor(candidate) ? candidate : null;
    }

    final bracketed = RegExp(r'^[\[(（【［]\s*([^\])）】］]+)\s*[\])）】］]$')
        .firstMatch(text.trim());
    if (bracketed != null) {
      final candidate = _stripWrappingPunctuation(bracketed.group(1)!);
      return _isPlausibleAuthor(candidate) ? candidate : null;
    }

    final candidate = _stripWrappingPunctuation(text);
    return _isPlausibleAuthor(candidate) ? candidate : null;
  }

  static String? _extractAuthorFromHeader(String headerText) {
    final sample = headerText.length > 1024
        ? headerText.substring(0, 1024)
        : headerText;

    final m1 = _authorHeaderRegex.firstMatch(sample);
    if (m1 != null) {
      final candidate = _stripWrappingPunctuation(m1.group(1)!.trim());
      if (_isPlausibleAuthor(candidate)) return candidate;
    }

    final m2 = _authorZhuRegex.firstMatch(sample);
    if (m2 != null) {
      final candidate = _stripWrappingPunctuation(m2.group(1)!.trim());
      if (_isPlausibleAuthor(candidate)) return candidate;
    }

    return null;
  }

  static String _stripWrappingPunctuation(String text) {
    return text.replaceAll(
      RegExp(r'^[\p{P}\p{S}\s]+|[\p{P}\p{S}\s]+$', unicode: true),
      '',
    );
  }

  static bool _isPlausibleAuthor(String name) {
    return name.isNotEmpty &&
        name.length <= 25 &&
        !name.contains(':') &&
        !name.contains('：') &&
        !RegExp(r'\d{4,}').hasMatch(name);
  }

  static String? _detectLanguage(String text) {
    final sample = text.length > 1024 ? text.substring(0, 1024) : text;
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(sample)) {
      return RegExp(r'[\u3040-\u30ff]').hasMatch(sample) ? 'ja' : 'zh';
    }
    if (RegExp(r'[\u0400-\u04ff]').hasMatch(sample)) {
      return 'ru';
    }
    return 'en';
  }
}

/// Segments raw plain-text content into structured chapters with semantic HTML.
class TxtChapterExtractor {
  final int fallbackParagraphsPerChapter;

  const TxtChapterExtractor({this.fallbackParagraphsPerChapter = 100});

  static final List<RegExp> _headingPatterns = [
    RegExp(
      r'(?:^|\r?\n)\s*('
      r'第[ 　0-9零〇一二三四五六七八九十百千万]+[章节回讲篇话](?:[：:、 　\(\)0-9]*[^\r\n]{0,50})?'
      r'|第[ 　0-9零〇一二三四五六七八九十百千万]+[卷本册部封](?:[：:、 　\(\)][：:、 　\(\)0-9]*[^\r\n]{0,50})?'
      r'|(?:楔子|前言|简介|引言|序言|序章|总论|概论|后记|番外篇|番外|外传)(?:[：: 　][^\r\n]{0,50})?'
      r'|chapter[\s.]*[0-9ivxlcdm]+(?:[：:. 　]+[^\r\n]{0,80})?'
      r'|(?:part|volume|book|act|scene)[\s.]*[0-9ivxlcdm]+(?:[：:. 　]+[^\r\n]{0,80})?'
      r')(?!\S)',
      caseSensitive: false,
    ),
  ];

  List<TxtChapter> extractChapters(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const [];

    for (final pattern in _headingPatterns) {
      final matches = pattern.allMatches(trimmed).toList();
      if (matches.length > 1) {
        return _buildChaptersFromMatches(trimmed, matches);
      }
    }

    return _buildFallbackChapters(trimmed);
  }

  List<TxtChapter> _buildChaptersFromMatches(
    String content,
    List<Match> matches,
  ) {
    final chapters = <TxtChapter>[];
    final firstMatch = matches.first;
    if (firstMatch.start > 0) {
      final intro = content.substring(0, firstMatch.start).trim();
      if (intro.isNotEmpty) {
        final firstLine = intro.split('\n').first.trim();
        final title = firstLine.length > 20
            ? '${firstLine.substring(0, 20)}...'
            : (firstLine.isNotEmpty ? firstLine : 'Introduction');
        chapters.add(
          TxtChapter(
            index: 0,
            title: title,
            contentHtml: _formatChapterHtml(title, intro, isVolume: false),
            isVolume: false,
            detected: false,
          ),
        );
      }
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final title = match.group(1)!.trim();
      final startIndex = match.end;
      final endIndex = (i + 1 < matches.length)
          ? matches[i + 1].start
          : content.length;
      final body = content.substring(startIndex, endIndex).trim();

      final isVolume = RegExp(
        r'(?:第.*?[卷本册部]|part|volume|book)',
        caseSensitive: false,
      ).hasMatch(title);

      chapters.add(
        TxtChapter(
          index: chapters.length,
          title: title,
          contentHtml: _formatChapterHtml(title, body, isVolume: isVolume),
          isVolume: isVolume,
          detected: true,
        ),
      );
    }

    return chapters;
  }

  List<TxtChapter> _buildFallbackChapters(String content) {
    final paragraphs = content
        .split(RegExp(r'\r?\n\s*\r?\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return [
        TxtChapter(
          index: 0,
          title: 'Start',
          contentHtml: _formatChapterHtml('Start', content, isVolume: false),
          isVolume: false,
          detected: false,
        ),
      ];
    }

    final chapters = <TxtChapter>[];
    for (int i = 0; i < paragraphs.length; i += fallbackParagraphsPerChapter) {
      final end = (i + fallbackParagraphsPerChapter < paragraphs.length)
          ? i + fallbackParagraphsPerChapter
          : paragraphs.length;
      final chunk = paragraphs.sublist(i, end).join('\n\n');
      final title = 'Section ${chapters.length + 1}';
      chapters.add(
        TxtChapter(
          index: chapters.length,
          title: title,
          contentHtml: _formatChapterHtml(title, chunk, isVolume: false),
          isVolume: false,
          detected: false,
        ),
      );
    }

    return chapters;
  }

  String _formatChapterHtml(
    String title,
    String body, {
    required bool isVolume,
  }) {
    final buffer = StringBuffer('<html><body>');
    if (isVolume) {
      buffer.write('<h1>${_escapeHtml(title)}</h1>');
    } else {
      buffer.write('<h2>${_escapeHtml(title)}</h2>');
    }

    final paras = body.split(RegExp(r'\r?\n+'));
    for (final rawPara in paras) {
      final para = rawPara.trim();
      if (para.isEmpty) continue;
      buffer.write('<p>${_escapeHtml(para)}</p>');
    }

    buffer.write('</body></html>');
    return buffer.toString();
  }

  static String _escapeHtml(String str) {
    return str
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
