import 'package:path/path.dart' as p;

import '../../models/models.dart';

/// Extracts book metadata (title, author) from plain text filenames and header content.
class TxtMetadataExtractor {
  const TxtMetadataExtractor._();

  static final RegExp _authorHeaderRegex = RegExp(
    r'[【\[]?\s*作者\s*[】\]]?\s*[:：\s]\s*([^\r\n]+)',
    caseSensitive: false,
  );

  static final RegExp _authorZhuRegex = RegExp(
    r'[【\[]?\s*([^\r\n]+?)\s*著\s*[】\]]?(?:\r?\n|$)',
    caseSensitive: false,
  );

  /// Extracts [TxtMetadata] from [filePath], [headerText], and detected [encoding].
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

  static ({String title, String? author}) _extractFromFilename(String filename) {
    // 1. Chinese 《Title》Author pattern
    final cjkBookMatch = RegExp(r'《([^》]+)》(.*)').firstMatch(filename);
    if (cjkBookMatch != null) {
      final title = cjkBookMatch.group(1)!.trim();
      final rest = cjkBookMatch.group(2)?.trim() ?? '';
      final author = _parseAuthorFragment(rest);
      return (title: title, author: author);
    }

    // 2. Bracketed 【Title】Author pattern
    final bracketMatch = RegExp(r'【([^】]+)】(.*)').firstMatch(filename);
    if (bracketMatch != null) {
      final title = bracketMatch.group(1)!.trim();
      final rest = bracketMatch.group(2)?.trim() ?? '';
      final author = _parseAuthorFragment(rest);
      return (title: title, author: author);
    }

    // 3. Western "Title - Author" pattern
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

    // Labeled: 作者：X / 作者:X / 作者 X
    final labeled = RegExp(r'作者\s*[：:\s]\s*(.+)$').firstMatch(text);
    if (labeled != null) {
      final candidate = _stripWrappingPunctuation(labeled.group(1)!);
      return _isPlausibleAuthor(candidate) ? candidate : null;
    }

    // Bracketed author: [X], (X), 【X】, （X）
    final bracketed = RegExp(r'^[\[(（【［]\s*([^\])）】］]+)\s*[\])）】］]$').firstMatch(text.trim());
    if (bracketed != null) {
      final candidate = _stripWrappingPunctuation(bracketed.group(1)!);
      return _isPlausibleAuthor(candidate) ? candidate : null;
    }

    final candidate = _stripWrappingPunctuation(text);
    return _isPlausibleAuthor(candidate) ? candidate : null;
  }

  static String? _extractAuthorFromHeader(String headerText) {
    final sample = headerText.length > 1024 ? headerText.substring(0, 1024) : headerText;

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
    return text.replaceAll(RegExp(r'^[\p{P}\p{S}\s]+|[\p{P}\p{S}\s]+$', unicode: true), '');
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
