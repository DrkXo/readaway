import 'package:pdfrx/pdfrx.dart';

import '../../models/models.dart';

/// Extractor for generating document [OutlineItem]s from printed Table of Contents
/// in PDF documents that lack native PDF outline metadata.
class PdfTocExtractor {
  const PdfTocExtractor._();

  static final RegExp _tocKeywordRegex = RegExp(
    r'(?:table\s+of\s+contents|contents|inhaltsverzeichnis|table\s+des\s+mati[èe]res|'
    r'sommaire|índice|indice|sommario|目录|目次|inhoud|содержание)',
    caseSensitive: false,
  );

  static final RegExp _dotLeaderLineRegex = RegExp(
    r'^([ \t]*)(.+?)(?:(?:[\.·…_–—\-\s]{3,})|\t+|\s{4,})\s*([0-9]+|[ivxlcdm]+)\s*$',
    caseSensitive: false,
  );

  static final RegExp _trailingPageNumberRegex = RegExp(
    r'^([ \t]*)(.+?)\s{2,}([0-9]+)\s*$',
  );

  /// Scans the initial pages of [pdfDoc] for a printed Table of Contents and
  /// converts it into structured [OutlineItem]s.
  static Future<List<OutlineItem>> extract(
    PdfDocument pdfDoc, {
    int maxScanPages = 40,
  }) async {
    final totalPages = pdfDoc.pages.length;
    if (totalPages == 0) return const [];

    final scanLimit = totalPages < maxScanPages ? totalPages : maxScanPages;
    final pageTextCache = <int, String>{};
    final tocPages = <int, String>{};

    var foundTocStart = false;
    var consecutiveNonTocPages = 0;

    for (var i = 0; i < scanLimit; i++) {
      final rawText = (await pdfDoc.pages[i].loadText())?.fullText;
      if (rawText == null || rawText.trim().isEmpty) {
        if (foundTocStart) {
          consecutiveNonTocPages++;
          if (consecutiveNonTocPages > 2) break;
        }
        continue;
      }

      pageTextCache[i] = rawText;

      final isTocPage = _isTocPage(rawText, hasStarted: foundTocStart);
      if (isTocPage) {
        foundTocStart = true;
        consecutiveNonTocPages = 0;
        tocPages[i] = rawText;
      } else if (foundTocStart) {
        consecutiveNonTocPages++;
        if (consecutiveNonTocPages > 1) break;
      }
    }

    if (tocPages.isEmpty) return const [];

    final rawEntries = _parseTocEntries(tocPages);
    if (rawEntries.isEmpty) return const [];

    final lastTocPageIndex = tocPages.keys.reduce((a, b) => a > b ? a : b);
    final pageOffset = await _calibratePageOffset(
      pdfDoc,
      rawEntries: rawEntries,
      lastTocPageIndex: lastTocPageIndex,
      pageTextCache: pageTextCache,
    );

    return _buildOutlineTree(
      rawEntries,
      pageOffset: pageOffset,
      totalPages: totalPages,
    );
  }

  static bool _isTocPage(String text, {required bool hasStarted}) {
    final lower = text.toLowerCase();
    final lines = text.split(RegExp(r'\r?\n'));

    var matchingLines = 0;
    for (final line in lines) {
      if (_dotLeaderLineRegex.hasMatch(line) ||
          _trailingPageNumberRegex.hasMatch(line)) {
        matchingLines++;
      }
    }

    if (_tocKeywordRegex.hasMatch(lower) && matchingLines >= 1) {
      return true;
    }

    if (matchingLines >= 3) {
      return true;
    }

    if (hasStarted && matchingLines >= 2) {
      return true;
    }

    return false;
  }

  static List<_RawTocEntry> _parseTocEntries(Map<int, String> tocPages) {
    final entries = <_RawTocEntry>[];
    String? pendingTitlePrefix;
    int? pendingIndent;

    for (final pageEntry in tocPages.entries) {
      final lines = pageEntry.value.split(RegExp(r'\r?\n'));

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // Skip standalone headers/footers (lines without page leader target)
        if (_isStandaloneHeaderOrFooter(trimmed)) {
          pendingTitlePrefix = null;
          pendingIndent = null;
          continue;
        }

        var match = _dotLeaderLineRegex.firstMatch(line);
        match ??= _trailingPageNumberRegex.firstMatch(line);

        if (match != null) {
          final indent = (pendingIndent ?? (match.group(1)?.length ?? 0));
          var title = match.group(2)!.trim();
          if (pendingTitlePrefix != null) {
            title = '$pendingTitlePrefix $title'.trim();
            pendingTitlePrefix = null;
            pendingIndent = null;
          }

          final pageStr = match.group(3)!.trim();
          final printedPage = int.tryParse(pageStr) ?? _romanToInt(pageStr);

          if (printedPage != null &&
              title.isNotEmpty &&
              !_isTocKeyword(title)) {
            entries.add(
              _RawTocEntry(
                title: _cleanTitle(title),
                printedPage: printedPage,
                indent: indent,
              ),
            );
          }
        } else {
          // Check if this line is part of a wrapped title
          if (trimmed.length < 80 && !trimmed.contains(RegExp(r'^\d+$'))) {
            pendingTitlePrefix = pendingTitlePrefix == null
                ? trimmed
                : '$pendingTitlePrefix $trimmed';
            pendingIndent ??= (line.length - line.trimLeft().length);
          } else {
            pendingTitlePrefix = null;
            pendingIndent = null;
          }
        }
      }
    }

    return entries;
  }

  static bool _isStandaloneHeaderOrFooter(String text) {
    final lower = text.toLowerCase();
    if (_isTocKeyword(lower) && lower.length < 30) {
      return true;
    }
    if (RegExp(r'^(?:[ivxlcdm]+|\d+)$', caseSensitive: false).hasMatch(lower)) {
      return true;
    }
    return false;
  }

  static bool _isTocKeyword(String text) {
    final lower = text.toLowerCase().trim();
    return _tocKeywordRegex.hasMatch(lower) && lower.length < 30;
  }

  static String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'[\.·…_–—\-]{2,}'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int? _romanToInt(String roman) {
    final r = roman.trim().toLowerCase();
    final romanMap = <String, int>{
      'i': 1,
      'v': 5,
      'x': 10,
      'l': 50,
      'c': 100,
      'd': 500,
      'm': 1000,
    };

    var total = 0;
    var prev = 0;
    for (var i = r.length - 1; i >= 0; i--) {
      final val = romanMap[r[i]];
      if (val == null) return null;
      if (val < prev) {
        total -= val;
      } else {
        total += val;
        prev = val;
      }
    }
    return total > 0 ? total : null;
  }

  static Future<int> _calibratePageOffset(
    PdfDocument pdfDoc, {
    required List<_RawTocEntry> rawEntries,
    required int lastTocPageIndex,
    required Map<int, String> pageTextCache,
  }) async {
    final totalPages = pdfDoc.pages.length;
    final searchStart = lastTocPageIndex + 1;
    final searchEnd = (searchStart + 40).clamp(0, totalPages);

    final offsetVotes = <int, int>{};

    for (final candidate in rawEntries.take(12)) {
      final normalizedTitle = candidate.title.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      if (normalizedTitle.length < 3) continue;

      for (var p = searchStart; p < searchEnd; p++) {
        var pageText = pageTextCache[p];
        if (pageText == null) {
          pageText = (await pdfDoc.pages[p].loadText())?.fullText ?? '';
          pageTextCache[p] = pageText;
        }

        final normalizedPage = pageText.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        if (normalizedPage.contains(normalizedTitle)) {
          final offset = p - (candidate.printedPage - 1);
          if (offset >= 0 && offset < totalPages) {
            offsetVotes[offset] = (offsetVotes[offset] ?? 0) + 1;
          }
        }
      }
    }

    if (offsetVotes.isNotEmpty) {
      return offsetVotes.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Fallback: If first entry is page 1, offset is searchStart
    if (rawEntries.isNotEmpty && rawEntries.first.printedPage == 1) {
      return searchStart;
    }

    return 0;
  }

  static List<OutlineItem> _buildOutlineTree(
    List<_RawTocEntry> rawEntries, {
    required int pageOffset,
    required int totalPages,
  }) {
    if (rawEntries.isEmpty) return const [];

    final minIndent = rawEntries
        .map((e) => e.indent)
        .reduce((a, b) => a < b ? a : b);
    final isNumericOrSubHeading = RegExp(
      r'^(?:[0-9]+|[ivxlcdm]+|[a-z]\))\s*$',
      caseSensitive: false,
    );

    final roots = <_OutlineNode>[];
    _OutlineNode? currentParent;

    for (final entry in rawEntries) {
      final pageIndex = (entry.printedPage - 1 + pageOffset).clamp(
        0,
        totalPages - 1,
      );
      final isSubHeading = isNumericOrSubHeading.hasMatch(entry.title);
      final isChild =
          entry.indent > minIndent + 1 ||
          (currentParent != null && isSubHeading);

      final node = _OutlineNode(
        title: entry.title,
        pageIndex: pageIndex,
        level: isChild
            ? (currentParent != null ? currentParent.level + 1 : 1)
            : 0,
      );

      if (!isChild) {
        currentParent = node;
        roots.add(node);
      } else {
        if (currentParent != null) {
          currentParent.children.add(node);
        } else {
          roots.add(node);
        }
      }
    }

    return roots.map((r) => r.toOutlineItem()).toList();
  }
}

class _RawTocEntry {
  final String title;
  final int printedPage;
  final int indent;

  const _RawTocEntry({
    required this.title,
    required this.printedPage,
    required this.indent,
  });
}

class _OutlineNode {
  final String title;
  final int pageIndex;
  final int level;
  final List<_OutlineNode> children;

  _OutlineNode({
    required this.title,
    required this.pageIndex,
    required this.level,
    List<_OutlineNode>? children,
  }) : children = children ?? [];

  OutlineItem toOutlineItem() {
    return OutlineItem(
      title: title,
      href: 'page:$pageIndex',
      level: level,
      chapterIndex: pageIndex,
      children: children.map((c) => c.toOutlineItem()).toList(),
    );
  }
}
