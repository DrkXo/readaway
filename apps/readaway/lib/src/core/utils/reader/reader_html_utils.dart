import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../features/reader/domain/entity/reader_link.dart';

/// Extracts plain text from document HTML for TTS playback and text analysis.
///
/// Traverses all semantic text-bearing block elements (headings, paragraphs, blockquotes,
/// lists, and leaf divs), joining them with newlines to preserve natural speech phrasing.
String extractPageText(String html) {
  if (html.isEmpty) return '';
  final doc = html_parser.parse(html);
  final body = doc.body;
  if (body == null) return '';

  final blocks = <String>[];
  final visited = <dom.Element>{};

  void processNode(dom.Node node) {
    if (node is dom.Element) {
      final tag = node.localName?.toLowerCase();
      if (tag == 'script' || tag == 'style' || tag == 'noscript' || tag == 'head') {
        return;
      }

      const blockTags = {
        'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
        'p', 'blockquote', 'li', 'dt', 'dd', 'pre',
      };

      if (blockTags.contains(tag)) {
        final text = node.text.trim();
        if (text.isNotEmpty && !visited.contains(node)) {
          blocks.add(text);
          visited.add(node);
        }
        return;
      }

      // Check if container element has block children
      bool hasBlockChildren = false;
      for (final child in node.children) {
        final childTag = child.localName?.toLowerCase();
        if (blockTags.contains(childTag) ||
            childTag == 'div' ||
            childTag == 'article' ||
            childTag == 'section') {
          hasBlockChildren = true;
          break;
        }
      }

      if (tag == 'div' && !hasBlockChildren) {
        final text = node.text.trim();
        if (text.isNotEmpty && !visited.contains(node)) {
          blocks.add(text);
          visited.add(node);
        }
        return;
      }

      for (final child in node.nodes) {
        processNode(child);
      }
    } else if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isNotEmpty) {
        blocks.add(text);
      }
    }
  }

  processNode(body);
  return blocks.join('\n');
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
