import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../../readaway_core.dart';

/// Parses an EPUB 3 `<nav>` document into a hierarchical outline.
class NavParser {
  const NavParser();

  /// Parses [bytes] (an EPUB 3 nav document) into top-level [OutlineItem]s.
  ///
  /// Prefers the `<nav epub:type="toc">` element, falling back to the first
  /// `<nav>` when no TOC nav is present.
  ///
  /// [resolveHref] maps an anchor `href` to a normalized href. When omitted,
  /// the raw href is used as-is.
  List<OutlineItem> parse(
    Uint8List bytes, {
    String? Function(String href)? resolveHref,
    int? Function(String href)? resolveSectionIndex,
  }) {
    final doc = XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));
    final navs = doc.findAllElements('nav').toList();
    if (navs.isEmpty) return const [];

    final tocNav = navs.firstWhere(
      (n) =>
          n.getAttribute('epub:type') == 'toc' ||
          n.getAttribute('type') == 'toc',
      orElse: () => navs.first,
    );

    final ol = tocNav.findElements('ol').firstOrNull;
    if (ol == null) return const [];

    List<OutlineItem> parseOl(XmlElement ol, int level) {
      final items = <OutlineItem>[];
      for (final li in ol.findElements('li')) {
        final a = li.findElements('a').firstOrNull;
        if (a == null) continue;
        final label = a.innerText.trim();
        final rawHref = a.getAttribute('href') ?? '';
        final href = resolveHref?.call(rawHref) ?? rawHref;
        final nestedOl = li.findElements('ol').firstOrNull;
        items.add(
          OutlineItem(
            title: label.isNotEmpty ? label : 'Chapter ${items.length + 1}',
            href: href.isEmpty ? null : href,
            level: level,
            chapterIndex: resolveSectionIndex?.call(href),
            children: nestedOl == null
                ? const []
                : parseOl(nestedOl, level + 1),
          ),
        );
      }
      return items;
    }

    return parseOl(ol, 0);
  }
}
