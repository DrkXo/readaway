import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:mupdf/mupdf.dart';

import '../../models/reader/reader_block.dart';
import '../../models/reader/stext_line_geom.dart';

/// Layout reconstruction and pure string/math utilities for MuPDF's
/// structured-text HTML output.
///
/// That extraction emits one `<p style="top;left;line-height">` per rendered
/// visual line, with book typography preserved as inline spans
/// (`<b>/<i>/<tt>/<sup>` plus `<span style="font-size:Npt;color">`). These
/// helpers fuse consecutive lines back into logical paragraphs using their
/// geometry, and map extracted font sizes onto the app's base size while
/// keeping the book's relative hierarchy.

/// Groups consecutive stext line-paragraphs into logical paragraphs.
///
/// Two lines belong together when they are vertically adjacent (gap within
/// 1.5x line-height) and the second does not start an indent jump relative
/// to the first (equal or smaller left edge). This handles both flush-left
/// books and books that mark paragraphs by first-line indentation alone.
///
/// Two consecutive link-wrapped lines ([mergePageLinks]) never fuse, so TOC
/// entries render as separate tappable rows instead of one wall of text.
List<List<dom.Element>> groupParagraphLines(List<dom.Element> lines) {
  final groups = <List<dom.Element>>[];
  var current = <dom.Element>[];
  StextLineGeom? prev;
  var prevLink = false;

  for (final line in lines) {
    final geom = StextLineGeom.from(line);
    final link = _isLinkLine(line);
    final merges =
        current.isNotEmpty &&
        geom != null &&
        prev != null &&
        !(link && prevLink) &&
        geom.top > prev.top &&
        geom.top - prev.top <= prev.lineH * 1.5 &&
        geom.left <= prev.left + 3;
    if (!merges && current.isNotEmpty) {
      groups.add(current);
      current = <dom.Element>[];
    }
    current.add(line);
    prev = geom;
    prevLink = link;
  }
  if (current.isNotEmpty) groups.add(current);
  return groups;
}

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

/// True when [p]'s content was fully wrapped in an anchor by
/// [mergePageLinks].
bool _isLinkLine(dom.Element p) =>
    p.children.any((c) => c.localName?.toLowerCase() == 'a');

/// Maps an absolute font size extracted from the book onto the user's
/// preferred [base] size while preserving relative hierarchy around the
/// page's most common body size [modal] (e.g. a 22pt heading over an 11pt
/// body renders at 2x the base size).
double resolveFontSize(double extracted, double? modal, double base) {
  if (modal == null || modal <= 0) return extracted;
  final ratio = extracted / modal;
  return base * ratio.clamp(0.5, 4.0);
}

/// Most common font size found among styled elements in [scope] (MuPDF
/// points), i.e. the body size all other sizes are measured against.
double? computeModalFontSize(dom.Element scope) {
  final counts = <int, int>{};
  for (final el in scope.querySelectorAll('[style]')) {
    final fs = parseCssPt(parseStyles(el)['font-size']);
    if (fs != null && fs > 0) {
      final key = (fs * 10).round();
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key / 10.0;
}

double? parseCssPt(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (!t.endsWith('pt') && !t.endsWith('px')) return null;
  return double.tryParse(t.substring(0, t.length - 2));
}

Map<String, String> parseStyles(dom.Element element) {
  final style = element.attributes['style'];
  if (style == null || style.isEmpty) return const {};
  return parseDeclarations(style);
}

/// True when joining two lines must not insert a space because of CJK text
/// at the boundary.
bool cjkBoundary(String prevLine, String nextLine) {
  if (prevLine.isEmpty || nextLine.isEmpty) return false;
  return _isCjkChar(prevLine[prevLine.length - 1]) || _isCjkChar(nextLine[0]);
}

/// True when [prevLine] ends in a soft hyphen introduced by MuPDF's line
/// wrapping and the trailing '-' should be dropped when joining.
bool shouldDehyphenate(String prevLine, String nextLine) {
  if (prevLine.length < 2 || nextLine.isEmpty) return false;
  if (!prevLine.endsWith('-')) return false;
  final beforeHyphen = prevLine[prevLine.length - 2];
  return !_isCjkChar(beforeHyphen) &&
      beforeHyphen != ' ' &&
      !_isCjkChar(nextLine[0]);
}

/// Removes a trailing '-' from the rightmost text span so joined lines read
/// "refined" instead of "refined- essences". Returns true once stripped.
///
/// **Mutates [spans] in place** — caller must pass a mutable list.
bool stripTrailingHyphen(List<ReaderSpan> spans) {
  for (var i = spans.length - 1; i >= 0; i--) {
    final span = spans[i];
    if (span is! ReaderTextSpan) continue;
    final text = span.text;
    if (text.isNotEmpty) {
      if (!text.endsWith('-')) return false;
      spans[i] = span.copyWith(
        text: text.substring(0, text.length - 1),
      );
      return true;
    }
    final children = span.children;
    if (children.isNotEmpty) {
      final mutableChildren = List<ReaderSpan>.from(children);
      if (stripTrailingHyphen(mutableChildren)) {
        spans[i] = span.copyWith(children: mutableChildren);
        return true;
      }
    }
  }
  return false;
}

bool _isCjkChar(String ch) => RegExp(
  r'[\u3000-\u303f\u3040-\u30ff\u4e00-\u9fff\uff00-\uffef]',
).hasMatch(ch);

/// Wraps stext line-paragraphs whose geometry intersects a link hot zone in
/// an `<a href>` so taps reach the reader widget's `onTapUrl`. Internal links
/// become `#page=N` (flat page index); external URIs are kept verbatim.
void mergePageLinks(dom.Document document, List<PageLink> links) {
  if (links.isEmpty) return;
  for (final p in document.querySelectorAll('p')) {
    final geom = StextLineGeom.from(p);
    if (geom == null || p.text.trim().isEmpty) continue;

    final bottom = geom.top + geom.lineH;
    for (final link in links) {
      // 1pt vertical tolerance absorbs rounding between the two extractors.
      if (link.y0 >= bottom + 1 || link.y1 <= geom.top - 1) continue;

      final anchor = dom.Element.tag('a')
        ..attributes['href'] = link.isInternal
            ? '#page=${link.pageNumber}'
            : link.uri;
      for (final node in List<dom.Node>.from(p.nodes)) {
        node.remove();
        anchor.append(node);
      }
      p.append(anchor);
      break;
    }
  }
}

/// Strips `height` from [raw]'s elements, then folds [links] onto their
/// intersecting `<p>` lines (see [mergePageLinks]).
///
/// Returns the rewritten HTML, or [raw] itself when null/empty.
String? sanitizeHtml(String? raw, List<PageLink> links) {
  if (raw == null || raw.isEmpty) return raw;

  final document = html_parser.parse(raw);
  for (final element in document.querySelectorAll('*')) {
    stripHeight(element);
  }
  mergePageLinks(document, links);
  return document.outerHtml;
}

/// Removes `height` from an element's attributes and inline style, leaving
/// the remaining declarations intact (dropping the `style` attribute when it
/// becomes empty).
void stripHeight(dom.Element element) {
  element.attributes.remove('height');

  final style = element.attributes['style'];
  if (style == null || style.isEmpty) return;

  final declarations = parseDeclarations(style)..remove('height');
  if (declarations.isEmpty) {
    element.attributes.remove('style');
  } else {
    element.attributes['style'] = declarations.entries
        .map((e) => '${e.key}: ${e.value};')
        .join(' ');
  }
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

/// Fast single-pass scanner for CSS inline declaration blocks (`style="..."`).
///
/// Parses key-value pairs without AST overhead or `csslib` allocation bursts.
/// Correctly respects quotes and parentheses so font families and URLs are safe.
Map<String, String> parseDeclarations(String style) {
  final trimmed = style.trim();
  if (trimmed.isEmpty) return const {};

  final result = <String, String>{};
  final len = trimmed.length;
  var i = 0;

  while (i < len) {
    var colon = -1;
    var semicolon = -1;
    var inSingleQuote = false;
    var inDoubleQuote = false;
    var parenDepth = 0;

    final start = i;
    while (i < len) {
      final c = trimmed.codeUnitAt(i);
      if (c == 39 /* ' */ && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (c == 34 /* " */ && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      } else if (!inSingleQuote && !inDoubleQuote) {
        if (c == 40 /* ( */) {
          parenDepth++;
        } else if (c == 41 /* ) */) {
          if (parenDepth > 0) parenDepth--;
        } else if (c == 58 /* : */ && colon == -1 && parenDepth == 0) {
          colon = i;
        } else if (c == 59 /* ; */ && parenDepth == 0) {
          semicolon = i;
          break;
        }
      }
      i++;
    }

    if (semicolon == -1) {
      semicolon = i;
    }

    if (colon != -1 && colon > start && colon < semicolon) {
      final key = trimmed.substring(start, colon).trim().toLowerCase();
      final value = trimmed.substring(colon + 1, semicolon).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        result[key] = value;
      }
    }

    i = semicolon + 1;
    while (i < len && trimmed.codeUnitAt(i) <= 32) {
      i++;
    }
  }

  return result;
}
