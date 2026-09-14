import '../../models/models.dart';

/// Segments raw plain-text book content into structured chapters with semantic HTML.
class TxtChapterExtractor {
  final int fallbackParagraphsPerChapter;

  const TxtChapterExtractor({
    this.fallbackParagraphsPerChapter = 100,
  });

  static final List<RegExp> _headingPatterns = [
    // Chinese Chapters & Volumes & Frontmatter
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

  /// Extracts structured [TxtChapter]s from [content].
  List<TxtChapter> extractChapters(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const [];

    for (final pattern in _headingPatterns) {
      final matches = pattern.allMatches(trimmed).toList();
      if (matches.length > 1) {
        return _buildChaptersFromMatches(trimmed, matches);
      }
    }

    // Fallback: chunk paragraphs into balanced chapters
    return _buildFallbackChapters(trimmed);
  }

  List<TxtChapter> _buildChaptersFromMatches(String content, List<Match> matches) {
    final chapters = <TxtChapter>[];

    // Check if there is introductory text before the first chapter heading
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
      final endIndex = (i + 1 < matches.length) ? matches[i + 1].start : content.length;
      final body = content.substring(startIndex, endIndex).trim();

      final isVolume = RegExp(r'(?:第.*?[卷本册部]|part|volume|book)', caseSensitive: false).hasMatch(title);

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

  String _formatChapterHtml(String title, String body, {required bool isVolume}) {
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
