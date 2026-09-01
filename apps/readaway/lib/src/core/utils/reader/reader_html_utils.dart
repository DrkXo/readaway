import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' as css;
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:mupdf/mupdf.dart';

import '../../models/reader/stext_line_geom.dart';

/// Layout reconstruction for MuPDF's structured-text HTML output.
///
/// That extraction emits one `<p style="top;left;line-height">` per rendered
/// visual line, with book typography preserved as inline spans
/// (`<b>/<i>/<tt>/<sup>` plus `<span style="font-size:Npt;color">`). These
/// helpers fuse consecutive lines back into logical paragraphs using their
/// geometry, and map extracted font sizes onto the app's base size while
/// keeping the book's relative hierarchy. Colors come from the app theme;
/// [resolveFontSize] takes the place of the book's absolute sizes.

/// Groups consecutive stext line-paragraphs into logical paragraphs.
///
/// Two lines belong together when they are vertically adjacent (gap within
/// 1.5x line-height) and the second does not start an indent jump relative
/// to the first (equal or smaller left edge). This handles both flush-left
/// books and books that mark paragraphs by first-line indentation alone.
///
/// Two consecutive link-wrapped lines ([mergePageLinks]) never fuse, so TOC
/// entries render as separate tappable rows instead of one wall of text.
///
/// ponytail: geometric heuristic; centered/right-aligned blocks with tight
/// leading can be split or fused incorrectly — revisit if a book hits it.
/// ponytail: two adjacent link-bearing prose lines (multi-line hyperlink)
/// split into two blocks — same line-granularity ceiling as mergePageLinks.
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
  if (style == null || style.isEmpty) return {};
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
bool stripTrailingHyphen(List<InlineSpan> spans) {
  for (var i = spans.length - 1; i >= 0; i--) {
    final span = spans[i];
    if (span is WidgetSpan) continue;
    final ts = span as TextSpan;
    final text = ts.text;
    if (text != null && text.isNotEmpty) {
      if (!text.endsWith('-')) return false;
      spans[i] = TextSpan(
        text: text.substring(0, text.length - 1),
        style: ts.style,
        children: ts.children,
        recognizer: ts.recognizer,
      );
      return true;
    }
    final children = ts.children;
    if (children != null && children.isNotEmpty) {
      return stripTrailingHyphen(children);
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
///
/// ponytail: line granularity — stext HTML lines carry no width, so two
/// links overlapping one line collapse to the first; word-level rects need
/// char quads from a custom extractor.
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

/// Parses CSS declaration blocks (the content of a `style` attribute) into a
/// property → value map.
///
/// This is the single shared entry point for all CSS parsing in the app. It
/// delegates to `package:csslib`'s real tokenizer/parser instead of the
/// fragile `split(';')`/`split(':')` string splitting that used to live in
/// [parseStyles] and `_stripHeight`. Because it returns the same
/// `Map<String, String>` contract, existing consumers are unaffected.
///
/// csslib parses full stylesheets, so a bare declaration block is wrapped in
/// a dummy selector (`x { ... }`) before parsing, then the first ruleset's
/// declarations are extracted. Errors are collected and ignored (best-effort),
/// so malformed CSS degrades to an empty/partial map rather than throwing.
/// Parses [style] (a CSS declaration block, e.g. `color: red; font-size: 12pt`)
/// into a map of lowercased property → trimmed value.
///
/// Returns an empty map for null/empty input or when nothing parses.
Map<String, String> parseDeclarations(String style) {
  final trimmed = style.trim();
  if (trimmed.isEmpty) return const {};

  final errors = <css.Message>[];
  // Wrap the declaration block in a dummy selector so csslib parses it as a
  // ruleset's declaration group.
  final sheet = css.parse('x { $trimmed }', errors: errors);

  final result = <String, String>{};
  for (final top in sheet.topLevels) {
    if (top is! css.RuleSet) continue;
    for (final node in top.declarationGroup.declarations) {
      if (node is! css.Declaration) continue;
      final value = _serializeValue(node);
      if (value.isEmpty) continue;
      result[node.property.toLowerCase()] = value;
    }
  }
  return result;
}

/// Serializes a declaration's expression back to its CSS value string.
String _serializeValue(css.Declaration declaration) {
  final expression = declaration.expression;
  if (expression == null) return '';
  final printer = css.CssPrinter();
  expression.visit(printer);
  return printer.toString().trim();
}
