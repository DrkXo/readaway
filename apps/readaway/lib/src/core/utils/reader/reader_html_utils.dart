import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../features/reader/domain/entity/reader_link.dart';

/// Extracts plain text from MuPDF structured-text HTML for TTS playback.
///
/// Joins each `<p>` block with a newline so sentence chunking preserves
/// paragraph boundaries, then collapses runs of whitespace.
String extractPageText(String html) {
  final doc = html_parser.parse(html);
  final body = doc.body;
  if (body == null) return '';
  final paragraphs = body
      .querySelectorAll('p')
      .map((e) => e.text.trim())
      .where((t) => t.isNotEmpty);
  return paragraphs.join('\n');
}

/// Indices surrounding [currentIndex] (current, next, previous) that fall
/// within `[0, pageCount)`, in that order. The caller skips any that are
/// already loaded or queued.
List<int> precacheCandidates(int currentIndex, int pageCount) {
  return [
    currentIndex,
    currentIndex + 1,
    currentIndex - 1,
  ].where((idx) => idx >= 0 && idx < pageCount).toList();
}

String injectLinksIntoHtml(
  String htmlString,
  List<ReaderLink> links, {
  required Color linkColor,
}) {
  if (links.isEmpty || htmlString.isEmpty) return htmlString;

  final document = html_parser.parse(htmlString);
  final cssColor = '#${linkColor.toARGB32().toRadixString(16).substring(2)}';

  for (final p in document.querySelectorAll('p')) {
    final topMatch = RegExp(
      r'top:\s*([\d.]+)pt',
    ).firstMatch(p.attributes['style'] ?? '');
    if (topMatch == null) continue;
    final top = double.parse(topMatch.group(1)!);

    ReaderLink? matched;
    for (final link in links) {
      // MuPDF link rectangles and structured-text HTML use the same
      // top-down page coordinate space.
      final linkTop = link.y0;
      final linkBottom = link.y1;
      if (top >= linkTop - 1.0 && top <= linkBottom + 1.0) {
        matched = link;
        break;
      }
    }
    if (matched == null) continue;

    final href = (matched.pageNumber >= 0)
        ? '#page=${matched.pageNumber}'
        : matched.uri;
    if (href.isEmpty) continue;

    for (final span in p.querySelectorAll('span')) {
      if (span.parent?.localName == 'a') continue;
      final spanStyle = span.attributes['style'] ?? '';
      final colorPattern = RegExp(
        r'color\s*:\s*(#0000ff|blue)',
        caseSensitive: false,
      );
      if (!colorPattern.hasMatch(spanStyle)) continue;

      final anchor = dom.Element.tag('a')
        ..attributes['href'] = href
        ..attributes['style'] = 'color: $cssColor;';
      span.attributes['style'] = spanStyle.replaceFirst(
        colorPattern,
        'color: $cssColor',
      );
      span.replaceWith(anchor);
      anchor.append(span);
    }
  }

  return document.outerHtml;
}
