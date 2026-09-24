import 'package:path/path.dart' as p;

import '../../models/models.dart';

/// Extractor for generating document [OutlineItem]s from comic archive directory
/// structures, chapter filename conventions, or page entries when ComicInfo bookmarks
/// are absent.
class ComicTocExtractor {
  const ComicTocExtractor._();

  static final RegExp _chapterPatternRegex = RegExp(
    r'(?:^|[\s._\-\[/])(chapter|chap|ch|c|episode|ep|volume|vol|v|act|part|section|book)[\s._#-]*([0-9]+(?:\.[0-9]+)?)(?![0-9a-zA-Z])',
    caseSensitive: false,
  );

  /// Extracts structured [OutlineItem]s from [pagePaths].
  static List<OutlineItem> extract(List<String> pagePaths) {
    if (pagePaths.isEmpty) return const [];

    // 1. Try folder-based hierarchical grouping
    final folderOutline = _extractFromFolders(pagePaths);
    if (folderOutline.isNotEmpty) {
      return folderOutline;
    }

    // 2. Try filename-based chapter grouping
    final chapterOutline = _extractFromChapterPatterns(pagePaths);
    if (chapterOutline.isNotEmpty) {
      return chapterOutline;
    }

    // 3. Fallback: clean page names
    return _extractFromPageNames(pagePaths);
  }

  static List<OutlineItem> _extractFromFolders(List<String> pagePaths) {
    final splitPaths = pagePaths.map((path) {
      final normalized = path.replaceAll('\\', '/');
      final dir = p.posix.dirname(normalized);
      if (dir == '.' || dir.isEmpty) return <String>[];
      return p.posix.split(dir).where((s) => s != '.' && s.isNotEmpty).toList();
    }).toList();

    final hasFolders = splitPaths.any((parts) => parts.isNotEmpty);
    if (!hasFolders) return const [];

    // Strip single common root directory if all files share it
    var commonPrefixLength = 0;
    if (splitPaths.every((p) => p.isNotEmpty)) {
      final first = splitPaths.first;
      for (var i = 0; i < first.length; i++) {
        final segment = first[i];
        if (splitPaths.every(
          (parts) => parts.length > i && parts[i] == segment,
        )) {
          commonPrefixLength = i + 1;
        } else {
          break;
        }
      }
    }

    final effectivePaths = splitPaths.map((parts) {
      if (parts.length <= commonPrefixLength) return <String>[];
      return parts.sublist(commonPrefixLength);
    }).toList();

    final hasEffectiveFolders = effectivePaths.any((parts) => parts.isNotEmpty);
    if (!hasEffectiveFolders) return const [];

    final topLevelItems = <OutlineItem>[];
    String? currentTopFolder;
    OutlineItem? currentItem;
    final currentChildren = <OutlineItem>[];
    String? currentSubFolder;

    for (var i = 0; i < pagePaths.length; i++) {
      final parts = effectivePaths[i];
      if (parts.isEmpty) continue;

      final topFolder = parts[0];
      final subFolder = parts.length > 1 ? parts[1] : null;

      if (topFolder != currentTopFolder) {
        if (currentItem != null) {
          topLevelItems.add(
            currentItem.copyWith(children: List.unmodifiable(currentChildren)),
          );
          currentChildren.clear();
        }

        currentTopFolder = topFolder;
        currentSubFolder = subFolder;
        currentItem = OutlineItem(
          title: _cleanName(topFolder),
          href: 'page:$i',
          level: 0,
          chapterIndex: i,
        );

        if (subFolder != null) {
          currentChildren.add(
            OutlineItem(
              title: _cleanName(subFolder),
              href: 'page:$i',
              level: 1,
              chapterIndex: i,
            ),
          );
        }
      } else if (subFolder != null && subFolder != currentSubFolder) {
        currentSubFolder = subFolder;
        currentChildren.add(
          OutlineItem(
            title: _cleanName(subFolder),
            href: 'page:$i',
            level: 1,
            chapterIndex: i,
          ),
        );
      }
    }

    if (currentItem != null) {
      topLevelItems.add(
        currentItem.copyWith(children: List.unmodifiable(currentChildren)),
      );
    }

    return topLevelItems.length > 1 ||
            (topLevelItems.isNotEmpty &&
                topLevelItems.first.children.isNotEmpty)
        ? topLevelItems
        : const [];
  }

  static List<OutlineItem> _extractFromChapterPatterns(List<String> pagePaths) {
    final chapterTransitions = <OutlineItem>[];
    String? currentChapterKey;

    for (var i = 0; i < pagePaths.length; i++) {
      final base = p.basenameWithoutExtension(pagePaths[i]);
      final match = _chapterPatternRegex.firstMatch(base);

      if (match != null) {
        final prefix = match.group(1) ?? 'Chapter';
        final number = match.group(2) ?? '';
        final chapterKey = '${prefix.toLowerCase()}_$number';

        if (chapterKey != currentChapterKey) {
          currentChapterKey = chapterKey;
          final title = _formatChapterLabel(prefix, number);
          chapterTransitions.add(
            OutlineItem(
              title: title,
              href: 'page:$i',
              level: 0,
              chapterIndex: i,
            ),
          );
        }
      }
    }

    // Return if at least 2 distinct chapters were detected
    return chapterTransitions.length >= 2 ? chapterTransitions : const [];
  }

  static List<OutlineItem> _extractFromPageNames(List<String> pagePaths) {
    final items = <OutlineItem>[];
    final seenTitles = <String, int>{};

    for (var i = 0; i < pagePaths.length; i++) {
      final rawBase = p.basenameWithoutExtension(pagePaths[i]);
      var title = _cleanName(rawBase);

      if (RegExp(r'^\d+$').hasMatch(title)) {
        final pageNum = int.tryParse(title);
        title = pageNum != null ? 'Page $pageNum' : 'Page ${i + 1}';
      }

      final count = (seenTitles[title] ?? 0) + 1;
      seenTitles[title] = count;
      final uniqueTitle = count > 1 ? '$title ($count)' : title;

      items.add(
        OutlineItem(
          title: uniqueTitle,
          href: 'page:$i',
          level: 0,
          chapterIndex: i,
        ),
      );
    }

    return items;
  }

  static String _cleanName(String raw) {
    var cleaned = raw
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isNotEmpty ? cleaned : raw;
  }

  static String _formatChapterLabel(String prefix, String number) {
    final lower = prefix.toLowerCase();
    final String label;
    if (lower.startsWith('ch') || lower == 'c') {
      label = 'Chapter';
    } else if (lower.startsWith('ep')) {
      label = 'Episode';
    } else if (lower.startsWith('vol') || lower == 'v') {
      label = 'Volume';
    } else if (lower == 'act') {
      label = 'Act';
    } else if (lower == 'part') {
      label = 'Part';
    } else if (lower == 'section') {
      label = 'Section';
    } else if (lower == 'book') {
      label = 'Book';
    } else {
      label = prefix;
    }
    return '$label $number';
  }
}
