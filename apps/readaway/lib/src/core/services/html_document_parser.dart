import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:injectable/injectable.dart';
import 'package:mupdf/mupdf.dart';

import '../../features/reader/domain/services/document_parser.dart';
import '../models/reader/reader_block.dart';
import '../models/reader/reader_document.dart';
import '../utils/reader/reader_html_utils.dart';

/// Concrete implementation of [DocumentParser] for MuPDF structured-text HTML.
///
/// Parses HTML in a single pass into pure [ReaderBlock] AST nodes.
/// Operates purely on data without any Flutter rendering dependencies, making it
/// safe to run on background isolates or the main thread.
@LazySingleton(as: DocumentParser)
class HtmlDocumentParser implements DocumentParser<String> {
  const HtmlDocumentParser();

  @override
  ReaderDocument parse(String html, {List<PageLink>? links}) {
    if (html.isEmpty) return ReaderDocument.empty;

    final document = html_parser.parse(html);
    final body = document.body;
    if (body == null) return ReaderDocument.empty;

    // Fast inline stripping of heights
    for (final element in document.querySelectorAll('*')) {
      stripHeight(element);
    }

    // Merge link coordinates directly into the DOM
    if (links != null && links.isNotEmpty) {
      mergePageLinks(document, links);
    }

    final modalFontSize = computeModalFontSize(body);
    final blocks = _buildBlocks(body.nodes, modalFontSize);

    return ReaderDocument(
      blocks: blocks,
      modalFontSize: modalFontSize,
    );
  }

  List<ReaderBlock> _buildBlocks(List<dom.Node> nodes, double? modalFontSize) {
    final blocks = <ReaderBlock>[];
    var run = <dom.Element>[];

    void flushRun() {
      if (run.isEmpty) return;
      for (final group in groupParagraphLines(run)) {
        final block = _paragraphBlock(group, modalFontSize);
        if (block != null) blocks.add(block);
      }
      run = <dom.Element>[];
    }

    for (final node in nodes) {
      if (node is dom.Element && node.localName?.toLowerCase() == 'p') {
        final imgChild =
            node.children.length == 1 &&
                node.children.first.localName?.toLowerCase() == 'img' &&
                node.text.trim().isEmpty
            ? node.children.first
            : null;
        if (imgChild != null) {
          flushRun();
          final imgBlock = _image(imgChild);
          if (imgBlock != null) {
            blocks.add(imgBlock);
            continue;
          }
        }
        run.add(node);
        continue;
      }

      // Inter-element whitespace between line-paragraphs must not split a run.
      if (node is dom.Text && node.text.trim().isEmpty) continue;

      flushRun();
      final block = _blockNode(node, modalFontSize);
      if (block != null) blocks.add(block);
    }

    flushRun();
    return blocks;
  }

  ParagraphBlock? _paragraphBlock(
    List<dom.Element> lines,
    double? modalFontSize,
  ) {
    final spans = <ReaderSpan>[];
    String? prevText;

    for (final line in lines) {
      final lineSpans = _buildInlineSpans(line.nodes, modalFontSize);
      if (lineSpans.isEmpty) continue;

      final lineText = line.text.trim();
      if (spans.isNotEmpty && prevText != null) {
        if (shouldDehyphenate(prevText, lineText)) {
          stripTrailingHyphen(spans);
        } else if (!cjkBoundary(prevText, lineText)) {
          spans.add(const ReaderTextSpan(text: ' '));
        }
      }

      spans.addAll(lineSpans);
      prevText = lineText;
    }

    if (spans.isEmpty) return null;
    return ParagraphBlock(spans);
  }

  ReaderBlock? _blockNode(dom.Node node, double? modalFontSize) {
    if (node is dom.Text) {
      final text = node.text.trim();
      if (text.isEmpty) return null;
      return LooseTextBlock(text);
    }
    if (node is! dom.Element) return null;

    switch (node.localName?.toLowerCase()) {
      case 'div':
        return _container(node, modalFontSize);
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        return _heading(node, modalFontSize);
      case 'br':
        return const SpacerBlock();
      case 'img':
        return _image(node);
      case 'a':
        return _linkBlock(node, modalFontSize);
      case 'ul':
      case 'ol':
        return _list(
          node,
          ordered: node.localName?.toLowerCase() == 'ol',
          modalFontSize: modalFontSize,
        );
      case 'blockquote':
        final inner = _buildBlocks(node.nodes, modalFontSize);
        if (inner.isEmpty) return null;
        return QuoteBlock(inner);
      case 'hr':
        return const RuleBlock();
      case 'table':
        return _table(node, modalFontSize);
      default:
        return _container(node, modalFontSize);
    }
  }

  ContainerBlock? _container(dom.Element element, double? modalFontSize) {
    final children = _buildBlocks(element.nodes, modalFontSize);
    if (children.isEmpty) return null;
    return ContainerBlock(children);
  }

  HeadingBlock? _heading(dom.Element element, double? modalFontSize) {
    final level = int.tryParse(element.localName![1]);
    if (level == null) return null;
    final spans = _buildInlineSpans(element.nodes, modalFontSize);
    if (spans.isEmpty) return null;
    return HeadingBlock(level, spans);
  }

  ImageBlock? _image(dom.Element element) {
    final src = element.attributes['src'];
    if (src == null || src.isEmpty) return null;

    if (src.startsWith('data:image')) {
      final commaIndex = src.indexOf(',');
      if (commaIndex == -1) return null;
      final rawBase64 = src.substring(commaIndex + 1);
      final cleanBase64 =
          rawBase64.contains('\n') ||
              rawBase64.contains('\r') ||
              rawBase64.contains(' ')
          ? rawBase64.replaceAll(RegExp(r'\s+'), '')
          : rawBase64;
      try {
        return ImageBlock(bytes: base64Decode(cleanBase64));
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

  ParagraphBlock? _linkBlock(dom.Element element, double? modalFontSize) {
    final span = _inlineSpan(element, modalFontSize);
    if (span == null) return null;
    return ParagraphBlock([span], padded: false);
  }

  ListBlock? _list(
    dom.Element element, {
    required bool ordered,
    required double? modalFontSize,
  }) {
    final items = <List<ReaderBlock>>[];
    for (final node in element.nodes) {
      if (node is dom.Element && node.localName?.toLowerCase() == 'li') {
        final children = _buildBlocks(node.nodes, modalFontSize);
        if (children.isNotEmpty) items.add(children);
      }
    }
    if (items.isEmpty) return null;
    return ListBlock(ordered: ordered, items: items);
  }

  TableBlock? _table(dom.Element element, double? modalFontSize) {
    final rows = <ReaderTableRow>[];
    for (final tr in element.querySelectorAll('tr')) {
      final cells = <ReaderTableCell>[];
      for (final child in tr.nodes) {
        if (child is! dom.Element) continue;
        final tag = child.localName?.toLowerCase();
        if (tag != 'td' && tag != 'th') continue;
        final cellChildren = _buildBlocks(child.nodes, modalFontSize);
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

  List<ReaderSpan> _buildInlineSpans(
    Iterable<dom.Node> nodes,
    double? modalFontSize,
  ) {
    final spans = <ReaderSpan>[];
    for (final node in nodes) {
      final span = _inlineSpan(node, modalFontSize);
      if (span != null) spans.add(span);
    }
    return spans;
  }

  ReaderSpan? _inlineSpan(
    dom.Node node,
    double? modalFontSize,
  ) {
    if (node is dom.Text) {
      if (node.text.isEmpty) return null;
      return ReaderTextSpan(text: node.text);
    }
    if (node is! dom.Element) return null;

    final styles = parseStyles(node);

    var bold = false;
    var italic = false;
    var underline = false;
    var strikethrough = false;
    var monospace = false;
    var subscript = false;
    var superscript = false;
    String? fontFamily;
    double? fontSizeRatio;

    final weight = styles['font-weight'];
    if (weight == 'bold') {
      bold = true;
    } else if (weight != null && (int.tryParse(weight) ?? 0) >= 600) {
      bold = true;
    }

    if (styles['font-style'] == 'italic') {
      italic = true;
    }

    final decoration = styles['text-decoration'];
    if (decoration != null) {
      if (decoration.contains('underline')) underline = true;
      if (decoration.contains('line-through')) strikethrough = true;
    }

    final fs = styles['font-size'];
    if (fs != null) {
      final value = parseCssPt(fs);
      if (value != null &&
          value > 0 &&
          modalFontSize != null &&
          modalFontSize > 0) {
        fontSizeRatio = value / modalFontSize;
      }
    }

    final rawFamily = styles['font-family'];
    if (rawFamily != null) {
      fontFamily = rawFamily.trim().replaceAll(RegExp('^["\']+|["\']+\$'), '');
    }

    final tag = node.localName?.toLowerCase();
    switch (tag) {
      case 'b':
      case 'strong':
        bold = true;
      case 'i':
      case 'em':
        italic = true;
      case 'u':
        underline = true;
      case 's':
      case 'strike':
      case 'del':
        strikethrough = true;
      case 'code':
      case 'tt':
        monospace = true;
      case 'sub':
        subscript = true;
      case 'sup':
        superscript = true;
      case 'img':
        final img = _image(node);
        if (img == null) return null;
        return ReaderInlineImageSpan(
          bytes: img.bytes,
          file: img.file,
          url: img.url,
        );
    }

    final href = tag == 'a' ? node.attributes['href'] : null;
    if (href != null && href.isNotEmpty) {
      underline = true;
    }

    final children = <ReaderSpan>[];
    for (final child in node.nodes) {
      final span = _inlineSpan(child, modalFontSize);
      if (span != null) children.add(span);
    }

    return ReaderTextSpan(
      bold: bold,
      italic: italic,
      underline: underline,
      strikethrough: strikethrough,
      monospace: monospace,
      subscript: subscript,
      superscript: superscript,
      fontFamily: fontFamily,
      fontSizeRatio: fontSizeRatio,
      linkHref: href,
      children: children,
    );
  }
}
