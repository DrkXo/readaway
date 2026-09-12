import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../models/models.dart';

/// Parses an EPUB 2 NCX navigation document into a hierarchical outline.
class NcxParser {
  const NcxParser();

  /// Parses [bytes] (an NCX document) into a list of top-level [OutlineItem]s.
  ///
  /// [resolveHref] maps a content `src` to a normalized href (e.g. resolved
  /// relative to the OPF directory). When omitted, `src` is used as-is.
  List<OutlineItem> parse(
    Uint8List bytes, {
    String? Function(String src)? resolveHref,
    int? Function(String href)? resolveSectionIndex,
  }) {
    final doc = XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));
    final navMap = doc.findAllElements('navMap').firstOrNull;
    if (navMap == null) return const [];

    List<OutlineItem> parseNavPoints(XmlElement parent, int level) {
      final items = <OutlineItem>[];
      for (final child in parent.findElements('navPoint')) {
        final labelElem = child.findElements('navLabel').firstOrNull;
        final textElem = labelElem?.findElements('text').firstOrNull;
        final label = textElem?.innerText.trim() ?? '';

        final contentElem = child.findElements('content').firstOrNull;
        final src = contentElem?.getAttribute('src') ?? '';

        final href = resolveHref?.call(src) ?? src;

        items.add(
          OutlineItem(
            title: label.isNotEmpty ? label : 'Chapter ${items.length + 1}',
            href: href.isEmpty ? null : href,
            level: level,
            chapterIndex: resolveSectionIndex?.call(href),
            children: parseNavPoints(child, level + 1),
          ),
        );
      }
      return items;
    }

    return parseNavPoints(navMap, 0);
  }
}
