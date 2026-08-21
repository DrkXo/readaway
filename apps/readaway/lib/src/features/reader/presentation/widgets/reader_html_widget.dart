import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../../core/theme/theme.dart';
import 'reader_html_layout.dart';

/// Renders the HTML extracted by MuPDF's structured-text output as
/// soft-wrapping [RichText] paragraphs.
///
/// Line fusion, CSS parsing and font-size scaling live in
/// `reader_html_layout.dart`; this file maps the resulting structure onto
/// widgets. Colors come from the app theme; the book contributes structure
/// and relative sizes ([ReaderHtmlWidget.baseFontSize] acts as the scale
/// anchor).
class ReaderHtmlWidget extends StatefulWidget {
  const ReaderHtmlWidget({
    super.key,
    required this.html,
    required this.appColors,
    this.baseFontSize = 18.0,
    this.lineHeight = 1.75,
    this.onTapUrl,
  });

  final String html;
  final AppColors appColors;
  final double baseFontSize;
  final double lineHeight;
  final void Function(String url)? onTapUrl;

  @override
  State<ReaderHtmlWidget> createState() => _ReaderHtmlWidgetState();
}

class _ReaderHtmlWidgetState extends State<ReaderHtmlWidget> {
  final List<TapGestureRecognizer> _recognizers = [];

  /// Most common font size on the page (MuPDF points), i.e. the body size all
  /// other sizes are measured against.
  double? _modalFontSize;

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TextStyle get _baseStyle => readerTextStyle(
    appColors: widget.appColors,
    fontSize: widget.baseFontSize,
    height: widget.lineHeight,
  );

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final document = html_parser.parse(widget.html);
    final body = document.body;
    if (body == null) return const SizedBox.shrink();

    _modalFontSize = computeModalFontSize(body);

    final children = _buildChildren(body.nodes);
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Walks container nodes, buffering runs of sibling `<p>` elements so
  /// [groupParagraphLines] can fuse them into paragraphs.
  List<Widget> _buildChildren(List<dom.Node> nodes) {
    final children = <Widget>[];
    var run = <dom.Element>[];

    void flushRun() {
      if (run.isEmpty) return;
      for (final group in groupParagraphLines(run)) {
        final widget = _buildParagraphGroup(group);
        if (widget != null) children.add(widget);
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
      final widget = _buildBlockNode(node);
      if (widget != null) children.add(widget);
    }
    flushRun();
    return children;
  }

  Widget? _buildParagraphGroup(List<dom.Element> lines) {
    final spans = <InlineSpan>[];
    String? prevText;

    for (final line in lines) {
      final lineSpans = _buildInlineSpans(line.nodes, _baseStyle);
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RichText(
        text: TextSpan(children: spans, style: _baseStyle),
      ),
    );
  }

  Widget? _buildBlockNode(dom.Node node) {
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return Text(text, style: _baseStyle);
    }
    if (node is! dom.Element) return null;

    final tag = node.localName?.toLowerCase();
    switch (tag) {
      case 'div':
        return _buildDiv(node);
      case 'h1':
        return _buildHeading(node, 1);
      case 'h2':
        return _buildHeading(node, 2);
      case 'h3':
        return _buildHeading(node, 3);
      case 'h4':
        return _buildHeading(node, 4);
      case 'h5':
        return _buildHeading(node, 5);
      case 'h6':
        return _buildHeading(node, 6);
      case 'br':
        return const SizedBox(height: 16);
      case 'img':
        return _buildImage(node);
      case 'a':
        return _buildLink(node);
      case 'ul':
        return _buildList(node, ordered: false);
      case 'ol':
        return _buildList(node, ordered: true);
      case 'li':
        return _buildListItem(node);
      case 'blockquote':
        return _buildBlockquote(node);
      case 'hr':
        return const Divider();
      case 'table':
        return _buildTable(node);
      default:
        return _buildUnknown(node);
    }
  }

  Widget _buildDiv(dom.Element element) {
    final children = _buildChildren(element.nodes);
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildHeading(dom.Element element, int level) {
    final spans = _buildInlineSpans(element.nodes, _baseStyle);
    if (spans.isEmpty) return const SizedBox.shrink();
    final baseStyle = _baseStyle;
    final headingStyle = switch (level) {
      1 => baseStyle.copyWith(
        fontSize: baseStyle.fontSize! * 1.5,
        fontWeight: FontWeight.bold,
      ),
      2 => baseStyle.copyWith(
        fontSize: baseStyle.fontSize! * 1.3,
        fontWeight: FontWeight.bold,
      ),
      3 => baseStyle.copyWith(
        fontSize: baseStyle.fontSize! * 1.1,
        fontWeight: FontWeight.bold,
      ),
      _ => baseStyle.copyWith(fontWeight: FontWeight.bold),
    };
    return Padding(
      padding: EdgeInsets.only(top: level == 1 ? 24 : 16, bottom: 8),
      child: RichText(
        text: TextSpan(children: spans, style: headingStyle),
      ),
    );
  }

  Widget _buildBlockquote(dom.Element element) {
    final children = _buildChildren(element.nodes);
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: widget.appColors.readerForeground.withValues(alpha: 0.3),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildList(dom.Element element, {required bool ordered}) {
    final items = <Widget>[];
    var index = 1;
    for (final node in element.nodes) {
      if (node is dom.Element && node.localName?.toLowerCase() == 'li') {
        final item = _buildListItem(node, index: ordered ? index : null);
        if (item != null) items.add(item);
        if (ordered) index++;
      }
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Widget? _buildListItem(dom.Element element, {int? index}) {
    final children = _buildChildren(element.nodes);
    if (children.isEmpty) return null;
    final prefix = index != null ? '$index. ' : '\u2022 ';
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prefix, style: _baseStyle),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLink(dom.Element element) {
    final spans = _buildInlineSpans(element.nodes, _baseStyle);
    if (spans.isEmpty) return const SizedBox.shrink();
    final href = element.attributes['href'];
    if (href == null || href.isEmpty) {
      return RichText(
        text: TextSpan(children: spans, style: _baseStyle),
      );
    }
    final recognizer = TapGestureRecognizer()
      ..onTap = () => widget.onTapUrl?.call(href);
    _recognizers.add(recognizer);
    return RichText(
      text: TextSpan(
        children: spans,
        style: _baseStyle.copyWith(decoration: TextDecoration.underline),
        recognizer: recognizer,
      ),
    );
  }

  Widget _buildImage(dom.Element element) {
    final src = element.attributes['src'];
    if (src == null || src.isEmpty) return const SizedBox.shrink();

    Widget image;
    if (src.startsWith('data:image')) {
      final regex = RegExp(r'data:image/[^;]+;base64,');
      final base64Data = src.replaceFirst(regex, '');
      try {
        final bytes = base64Decode(base64Data);
        image = Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        return const SizedBox.shrink();
      }
    } else if (src.startsWith('file://')) {
      final filePath = src.replaceFirst('file://', '');
      image = Image.file(File(filePath), fit: BoxFit.contain);
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      image = Image.network(src, fit: BoxFit.contain);
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: image,
    );
  }

  Widget _buildTable(dom.Element element) {
    final rows = <TableRow>[];
    for (final node in element.querySelectorAll('tr')) {
      final cells = <Widget>[];
      for (final child in node.nodes) {
        if (child is dom.Element) {
          final tag = child.localName?.toLowerCase();
          if (tag == 'td' || tag == 'th') {
            final cellContent = _buildTableCell(child);
            if (cellContent != null) cells.add(cellContent);
          }
        }
      }
      if (cells.isNotEmpty) {
        rows.add(TableRow(children: cells));
      }
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(
          color: widget.appColors.readerForeground.withValues(alpha: 0.2),
        ),
        children: rows,
      ),
    );
  }

  Widget? _buildTableCell(dom.Element element) {
    final children = _buildChildren(element.nodes);
    if (children.isEmpty) return null;
    final isHeader = element.localName?.toLowerCase() == 'th';
    return Padding(
      padding: const EdgeInsets.all(8),
      child: DefaultTextStyle(
        style: _baseStyle.copyWith(
          fontWeight: isHeader ? FontWeight.bold : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildUnknown(dom.Element element) {
    final children = _buildChildren(element.nodes);
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<InlineSpan> _buildInlineSpans(
    Iterable<dom.Node> nodes,
    TextStyle baseStyle,
  ) {
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      final span = _buildInlineSpan(node, baseStyle);
      if (span != null) spans.add(span);
    }
    return spans;
  }

  InlineSpan? _buildInlineSpan(dom.Node node, TextStyle baseStyle) {
    if (node is dom.Text) {
      final text = node.text;
      if (text.isEmpty) return null;
      return TextSpan(text: text, style: baseStyle);
    }
    if (node is! dom.Element) return null;

    final tag = node.localName?.toLowerCase();
    final styles = parseStyles(node);
    final style = _buildTextStyle(styles, baseStyle);

    final children = <InlineSpan>[];
    for (final child in node.nodes) {
      final span = _buildInlineSpan(child, style);
      if (span != null) children.add(span);
    }

    switch (tag) {
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
        final href = node.attributes['href'];
        if (href != null && href.isNotEmpty) {
          final recognizer = TapGestureRecognizer()
            ..onTap = () => widget.onTapUrl?.call(href);
          _recognizers.add(recognizer);
          return TextSpan(
            style: style.copyWith(decoration: TextDecoration.underline),
            children: children,
            recognizer: recognizer,
          );
        }
        return TextSpan(style: style, children: children);
      case 'br':
        return const WidgetSpan(child: SizedBox(height: 16));
      case 'sub':
        return TextSpan(
          style: style.copyWith(fontSize: style.fontSize! * 0.7, height: 1),
          children: children,
        );
      case 'sup':
        return TextSpan(
          style: style.copyWith(fontSize: style.fontSize! * 0.7, height: 1),
          children: children,
        );
      case 'code':
      case 'tt':
        return TextSpan(
          style: style.copyWith(fontFamily: 'monospace'),
          children: children,
        );
      default:
        final text = node.text.trim();
        if (text.isNotEmpty) {
          return TextSpan(text: text, style: style);
        }
        if (children.isNotEmpty) {
          return TextSpan(style: style, children: children);
        }
        return null;
    }
  }

  TextStyle _buildTextStyle(Map<String, String> styles, TextStyle base) {
    var result = base;

    final weight = styles['font-weight'];
    if (weight != null) {
      if (weight == 'bold') {
        result = result.copyWith(fontWeight: FontWeight.bold);
      } else if (weight == 'normal') {
        result = result.copyWith(fontWeight: FontWeight.normal);
      } else {
        final w = int.tryParse(weight);
        if (w != null) {
          final fontWeight = FontWeight.values.firstWhere(
            (e) => e.value == w,
            orElse: () => FontWeight.w400,
          );
          result = result.copyWith(fontWeight: fontWeight);
        }
      }
    }

    final fontStyle = styles['font-style'];
    if (fontStyle == 'italic') {
      result = result.copyWith(fontStyle: FontStyle.italic);
    } else if (fontStyle == 'normal') {
      result = result.copyWith(fontStyle: FontStyle.normal);
    }

    final fontSize = styles['font-size'];
    if (fontSize != null) {
      final value = parseCssPt(fontSize);
      if (value != null && value > 0) {
        result = result.copyWith(
          fontSize: resolveFontSize(value, _modalFontSize, widget.baseFontSize),
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
        result = result.copyWith(
          decoration: TextDecoration.combine(decorations),
        );
      }
    }

    return result;
  }
}
