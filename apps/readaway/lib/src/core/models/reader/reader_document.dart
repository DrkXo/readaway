import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../theme/theme.dart';
import '../../utils/reader/reader_html_utils.dart';
import 'reader_block.dart';

/// Builds the render-ready [ReaderBlock] tree from MuPDF structured-text HTML.
///
/// [ReaderDocument.fromDom] does everything that depends on the book
/// content (parsing support, line fusion, inline span construction); the
/// widget maps blocks onto widgets using only theme + user typography.
///
/// This split is what makes rebuilds cheap (font-size/theme changes never
/// re-parse) and gives upcoming features a stable surface: TTS can iterate
/// [ParagraphBlock]s, annotations/bookmarks can anchor to
/// `(pageIndex, blockIndex)`.
class ReaderDocument {
  const ReaderDocument({required this.blocks, this.modalFontSize});

  final List<ReaderBlock> blocks;

  /// Most common font size on the page (MuPDF points), i.e. the body size
  /// all other sizes were measured against.
  final double? modalFontSize;

  /// Convenience wrapper that parses [html] first.
  factory ReaderDocument.build(
    String html, {
    required AppColors appColors,
    required double baseFontSize,
    required double lineHeight,
    required RecognizerProvider recognizerFor,
    String serifFont = 'Noto Serif',
    String sansSerifFont = 'Noto Sans',
    String monospaceFont = 'Fira Code',
    bool overrideFont = false,
  }) {
    return ReaderDocument.fromDom(
      html_parser.parse(html),
      appColors: appColors,
      baseFontSize: baseFontSize,
      lineHeight: lineHeight,
      recognizerFor: recognizerFor,
      serifFont: serifFont,
      sansSerifFont: sansSerifFont,
      monospaceFont: monospaceFont,
      overrideFont: overrideFont,
    );
  }

  /// Walks MuPDF stext output once, producing the render-ready block list.
  ///
  /// Pass [modalFontSize] to reuse a previously computed value.
  factory ReaderDocument.fromDom(
    dom.Document document, {
    required AppColors appColors,
    required double baseFontSize,
    required double lineHeight,
    required RecognizerProvider recognizerFor,
    double? modalFontSize,
    String serifFont = 'Noto Serif',
    String sansSerifFont = 'Noto Sans',
    String monospaceFont = 'Fira Code',
    bool overrideFont = false,
  }) {
    final body = document.body;
    if (body == null) return const ReaderDocument(blocks: []);

    modalFontSize ??= computeModalFontSize(body);
    final ctx = _BuildContext(
      baseStyle: readerTextStyle(
        appColors: appColors,
        fontSize: baseFontSize,
        height: lineHeight,
      ),
      baseFontSize: baseFontSize,
      modalFontSize: modalFontSize,
      recognizerFor: recognizerFor,
      serifFont: serifFont,
      sansSerifFont: sansSerifFont,
      monospaceFont: monospaceFont,
      overrideFont: overrideFont,
    );

    return ReaderDocument(
      blocks: _buildBlocks(body.nodes, ctx),
      modalFontSize: ctx.modalFontSize,
    );
  }

  static List<ReaderBlock> _buildBlocks(
    List<dom.Node> nodes,
    _BuildContext ctx,
  ) {
    final blocks = <ReaderBlock>[];
    var run = <dom.Element>[];

    void flushRun() {
      if (run.isEmpty) return;
      for (final group in groupParagraphLines(run)) {
        final block = _paragraphBlock(group, ctx);
        if (block != null) blocks.add(block);
      }
      run = <dom.Element>[];
    }

    for (final node in nodes) {
      if (node is dom.Element && node.localName?.toLowerCase() == 'p') {
        run.add(node);
        continue;
      }
      // Inter-element whitespace between line-paragraphs must not split a run.
      if (node is dom.Text && node.text.trim().isEmpty) continue;

      flushRun();
      final block = _blockNode(node, ctx);
      if (block != null) blocks.add(block);
    }
    flushRun();
    return blocks;
  }

  static ParagraphBlock? _paragraphBlock(
    List<dom.Element> lines,
    _BuildContext ctx,
  ) {
    final spans = <InlineSpan>[];
    String? prevText;

    for (final line in lines) {
      final lineSpans = _buildInlineSpans(line.nodes, ctx, ctx.baseStyle);
      if (lineSpans.isEmpty) continue;
      final lineText = line.text.trim();
      if (spans.isNotEmpty && prevText != null) {
        if (shouldDehyphenate(prevText, lineText)) {
          stripTrailingHyphen(spans);
        } else if (!cjkBoundary(prevText, lineText)) {
          spans.add(const TextSpan(text: ' '));
        }
      }
      spans.addAll(lineSpans);
      prevText = lineText;
    }

    if (spans.isEmpty) return null;
    return ParagraphBlock(spans);
  }

  static ReaderBlock? _blockNode(dom.Node node, _BuildContext ctx) {
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return LooseTextBlock(text);
    }
    if (node is! dom.Element) return null;

    switch (node.localName?.toLowerCase()) {
      case 'div':
        return _container(node, ctx);
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return _heading(node, ctx);
      case 'br':
        return const SpacerBlock();
      case 'img':
        return _image(node);
      case 'a':
        return _linkBlock(node, ctx);
      case 'ul':
      case 'ol':
        return _list(
          node,
          ordered: node.localName?.toLowerCase() == 'ol',
          ctx: ctx,
        );
      case 'blockquote':
        final inner = _buildBlocks(node.nodes, ctx);
        if (inner.isEmpty) return null;
        return QuoteBlock(inner);
      case 'hr':
        return const RuleBlock();
      case 'table':
        return _table(node, ctx);
      default:
        return _container(node, ctx);
    }
  }

  static ContainerBlock? _container(dom.Element element, _BuildContext ctx) {
    final children = _buildBlocks(element.nodes, ctx);
    if (children.isEmpty) return null;
    return ContainerBlock(children);
  }

  static HeadingBlock? _heading(dom.Element element, _BuildContext ctx) {
    final level = int.tryParse(element.localName![1]);
    if (level == null) return null;
    final spans = _buildInlineSpans(element.nodes, ctx, ctx.baseStyle);
    if (spans.isEmpty) return null;
    return HeadingBlock(level, spans);
  }

  static ImageBlock? _image(dom.Element element) {
    final src = element.attributes['src'];
    if (src == null || src.isEmpty) return null;

    if (src.startsWith('data:image')) {
      final base64Data = src.replaceFirst(_dataUriRegex, '');
      try {
        return ImageBlock(bytes: base64Decode(base64Data));
      } catch (_) {
        return null;
      }
    }
    if (src.startsWith('file://')) {
      return ImageBlock(file: src.replaceFirst('file://', ''));
    }
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return ImageBlock(url: src);
    }
    return null;
  }

  /// Block-level `<a>`: renders its content as a tight paragraph with the
  /// underline + recognizer applied.
  static ParagraphBlock? _linkBlock(dom.Element element, _BuildContext ctx) {
    final href = element.attributes['href'];
    final spans = _buildInlineSpans(
      element.nodes,
      ctx,
      ctx.baseStyle.copyWith(decoration: TextDecoration.underline),
      forceRecognizerHref: href,
    );
    if (spans.isEmpty) return null;
    return ParagraphBlock(spans, padded: false);
  }

  static ListBlock? _list(
    dom.Element element, {
    required bool ordered,
    required _BuildContext ctx,
  }) {
    final items = <List<ReaderBlock>>[];
    for (final node in element.nodes) {
      if (node is dom.Element && node.localName?.toLowerCase() == 'li') {
        final children = _buildBlocks(node.nodes, ctx);
        if (children.isNotEmpty) items.add(children);
      }
    }
    if (items.isEmpty) return null;
    return ListBlock(ordered: ordered, items: items);
  }

  static TableBlock? _table(dom.Element element, _BuildContext ctx) {
    final rows = <ReaderTableRow>[];
    for (final tr in element.querySelectorAll('tr')) {
      final cells = <ReaderTableCell>[];
      for (final child in tr.nodes) {
        if (child is! dom.Element) continue;
        final tag = child.localName?.toLowerCase();
        if (tag != 'td' && tag != 'th') continue;
        final cellChildren = _buildBlocks(child.nodes, ctx);
        if (cellChildren.isNotEmpty) {
          cells.add(
            ReaderTableCell(
              children: cellChildren,
              isHeader: tag == 'th',
            ),
          );
        }
      }
      if (cells.isNotEmpty) rows.add(ReaderTableRow(cells));
    }
    if (rows.isEmpty) return null;
    return TableBlock(rows);
  }
}

class _BuildContext {
  const _BuildContext({
    required this.baseStyle,
    required this.baseFontSize,
    required this.modalFontSize,
    required this.recognizerFor,
    this.serifFont = 'Noto Serif',
    this.sansSerifFont = 'Noto Sans',
    this.monospaceFont = 'Fira Code',
    this.overrideFont = false,
  });

  final TextStyle baseStyle;
  final double baseFontSize;
  final double? modalFontSize;
  final RecognizerProvider recognizerFor;

  /// Font used for the book's `font-family: serif` generic family.
  final String serifFont;

  /// Font used for the book's `font-family: sans-serif` generic family.
  final String sansSerifFont;

  /// Font used for the book's `font-family: monospace` generic family (and
  /// `<code>`/`<tt>`).
  final String monospaceFont;

  /// When true, force the base font on all text, ignoring the book's own
  /// `font-family` declarations.
  final bool overrideFont;
}

final RegExp _dataUriRegex = RegExp(r'data:image/[^;]+;base64,');

/// Builds the inline span tree for [nodes], threading [baseStyle] down and
/// applying tag semantics (`b/i/u/s/sub/sup/code/a/...`) plus inline
/// `style="..."` overrides.
List<InlineSpan> _buildInlineSpans(
  Iterable<dom.Node> nodes,
  _BuildContext ctx,
  TextStyle baseStyle, {
  String? forceRecognizerHref,
}) {
  final spans = <InlineSpan>[];
  for (final node in nodes) {
    final span = _inlineSpan(node, ctx, baseStyle, forceRecognizerHref);
    if (span != null) spans.add(span);
  }
  return spans;
}

InlineSpan? _inlineSpan(
  dom.Node node,
  _BuildContext ctx,
  TextStyle baseStyle,
  String? forceRecognizerHref,
) {
  if (node is dom.Text) {
    if (node.text.isEmpty) return null;
    return TextSpan(text: node.text, style: baseStyle);
  }
  if (node is! dom.Element) return null;

  final styles = parseStyles(node);
  final style = _textStyle(styles, baseStyle, ctx);

  final children = <InlineSpan>[];
  for (final child in node.nodes) {
    final span = _inlineSpan(child, ctx, style, forceRecognizerHref);
    if (span != null) children.add(span);
  }

  switch (node.localName?.toLowerCase()) {
    case 'b':
    case 'strong':
      return TextSpan(
        style: style.copyWith(fontWeight: FontWeight.bold),
        children: children,
      );
    case 'i':
    case 'em':
      return TextSpan(
        style: style.copyWith(fontStyle: FontStyle.italic),
        children: children,
      );
    case 'u':
      return TextSpan(
        style: style.copyWith(decoration: TextDecoration.underline),
        children: children,
      );
    case 's':
    case 'strike':
    case 'del':
      return TextSpan(
        style: style.copyWith(decoration: TextDecoration.lineThrough),
        children: children,
      );
    case 'span':
      return TextSpan(style: style, children: children);
    case 'a':
      final raw = forceRecognizerHref ?? node.attributes['href'];
      final href = (raw == null || raw.isEmpty) ? null : raw;
      if (href != null && children.isNotEmpty) {
        // RenderParagraph routes taps through the hit-tested leaf span, so
        // the recognizer goes onto leaves rather than this wrapper.
        final recognizer = ctx.recognizerFor(href);
        if (recognizer != null) {
          return TextSpan(
            style: style.copyWith(decoration: TextDecoration.underline),
            children: [
              for (final child in children) _withRecognizer(child, recognizer),
            ],
          );
        }
      }
      return TextSpan(
        style: href != null
            ? style.copyWith(decoration: TextDecoration.underline)
            : style,
        children: children,
      );
    case 'br':
      return const WidgetSpan(child: SizedBox(height: 16));
    case 'sub':
    case 'sup':
      return TextSpan(
        style: style.copyWith(fontSize: style.fontSize! * 0.7, height: 1),
        children: children,
      );
    case 'code':
    case 'tt':
      return TextSpan(
        style: style.copyWith(fontFamily: ctx.monospaceFont),
        children: children,
      );
    default:
      final text = node.text.trim();
      if (text.isNotEmpty) return TextSpan(text: text, style: style);
      if (children.isNotEmpty) {
        return TextSpan(style: style, children: children);
      }
      return null;
  }
}

/// Returns [span] with [recognizer] attached to every leaf TextSpan so
/// taps anywhere in a link's subtree fire. Existing recognizers (nested
/// `<a>`) win and are left untouched.
InlineSpan _withRecognizer(InlineSpan span, GestureRecognizer recognizer) {
  if (span is! TextSpan) return span;
  final children = span.children;
  if (children == null || children.isEmpty) {
    return TextSpan(
      text: span.text,
      style: span.style,
      recognizer: span.recognizer ?? recognizer,
    );
  }
  return TextSpan(
    text: span.text,
    style: span.style,
    children: [
      for (final child in children) _withRecognizer(child, recognizer),
    ],
  );
}

TextStyle _textStyle(
  Map<String, String> styles,
  TextStyle base,
  _BuildContext ctx,
) {
  var result = base;

  // Honor the book's `font-family` unless the user chose to override fonts.
  if (!ctx.overrideFont) {
    final family = styles['font-family'];
    if (family != null) {
      final resolved = _resolveFontFamily(family, ctx);
      if (resolved != null) {
        result = result.copyWith(fontFamily: resolved);
      }
    }
  }

  final weight = styles['font-weight'];
  if (weight != null) {
    if (weight == 'bold') {
      result = result.copyWith(fontWeight: FontWeight.bold);
    } else if (weight == 'normal') {
      result = result.copyWith(fontWeight: FontWeight.normal);
    } else {
      final w = int.tryParse(weight);
      if (w != null) {
        result = result.copyWith(
          fontWeight: FontWeight.values.firstWhere(
            (e) => e.value == w,
            orElse: () => FontWeight.w400,
          ),
        );
      }
    }
  }

  switch (styles['font-style']) {
    case 'italic':
      result = result.copyWith(fontStyle: FontStyle.italic);
    case 'normal':
      result = result.copyWith(fontStyle: FontStyle.normal);
  }

  final fontSize = styles['font-size'];
  if (fontSize != null) {
    final value = parseCssPt(fontSize);
    if (value != null && value > 0) {
      result = result.copyWith(
        fontSize: resolveFontSize(value, ctx.modalFontSize, ctx.baseFontSize),
      );
    }
  }

  final decoration = styles['text-decoration'];
  if (decoration != null) {
    final decorations = <TextDecoration>[];
    if (decoration.contains('underline')) {
      decorations.add(TextDecoration.underline);
    }
    if (decoration.contains('line-through')) {
      decorations.add(TextDecoration.lineThrough);
    }
    if (decorations.isNotEmpty) {
      result = result.copyWith(decoration: TextDecoration.combine(decorations));
    }
  }

  return result;
}

/// Resolves a CSS `font-family` value against the user's configured fonts.
///
/// Generic families (`serif`, `sans-serif`, `monospace`) map to the matching
/// configured font. Named families pass through unchanged so Flutter can
/// resolve them (falling back to the base font if unavailable). Returns null
/// when nothing usable is found, in which case the caller keeps the base font.
String? _resolveFontFamily(String raw, _BuildContext ctx) {
  // `font-family` is a comma-separated fallback list; walk it in order and
  // return the first entry we can map.
  for (final part in raw.split(',')) {
    final name = part.trim().replaceAll(RegExp('^["\']+|["\']+\$'), '');
    if (name.isEmpty) continue;
    switch (name.toLowerCase()) {
      case 'serif':
        return ctx.serifFont;
      case 'sans-serif':
        return ctx.sansSerifFont;
      case 'monospace':
        return ctx.monospaceFont;
      case 'cursive':
      case 'fantasy':
      case 'system-ui':
        // No dedicated mapping; fall through to the next candidate.
        continue;
      default:
        return name;
    }
  }
  return null;
}
