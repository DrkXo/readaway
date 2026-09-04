import 'dart:typed_data';

/// Intermediate representation between MuPDF HTML and Flutter widgets.
///
/// The block tree is produced by [DocumentParser] and mapped onto widgets by
/// the reader presentation layer. Keeping these as plain data models enables
/// single-pass parsing, instant theme/font re-styling without re-parsing,
/// TTS iteration over [ParagraphBlock]s, and annotations/bookmarks anchored to
/// `(pageIndex, blockIndex)`.
sealed class ReaderBlock {
  const ReaderBlock();
}

/// Abstract inline span for styled text and inline assets.
sealed class ReaderSpan {
  const ReaderSpan();

  String get plainText;
}

/// A styled run of text within a paragraph or heading.
class ReaderTextSpan extends ReaderSpan {
  const ReaderTextSpan({
    this.text = '',
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.monospace = false,
    this.subscript = false,
    this.superscript = false,
    this.fontFamily,
    this.fontSizeRatio,
    this.linkHref,
    this.children = const [],
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final bool monospace;
  final bool subscript;
  final bool superscript;
  final String? fontFamily;
  final double? fontSizeRatio;
  final String? linkHref;
  final List<ReaderSpan> children;

  @override
  String get plainText {
    final buffer = StringBuffer(text);
    for (final child in children) {
      buffer.write(child.plainText);
    }
    return buffer.toString();
  }

  ReaderTextSpan copyWith({
    String? text,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    bool? monospace,
    bool? subscript,
    bool? superscript,
    String? fontFamily,
    double? fontSizeRatio,
    String? linkHref,
    List<ReaderSpan>? children,
  }) {
    return ReaderTextSpan(
      text: text ?? this.text,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      monospace: monospace ?? this.monospace,
      subscript: subscript ?? this.subscript,
      superscript: superscript ?? this.superscript,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeRatio: fontSizeRatio ?? this.fontSizeRatio,
      linkHref: linkHref ?? this.linkHref,
      children: children ?? this.children,
    );
  }
}

/// Inline image embedded in a text line.
class ReaderInlineImageSpan extends ReaderSpan {
  const ReaderInlineImageSpan({
    this.bytes,
    this.file,
    this.url,
  });

  final Uint8List? bytes;
  final String? file;
  final String? url;

  @override
  String get plainText => '';
}

/// A fused logical paragraph (or a bare block-level link run when
/// [padded] is false) rendered as one soft-wrapping RichText.
class ParagraphBlock extends ReaderBlock {
  const ParagraphBlock(this.spans, {this.padded = true});

  final List<ReaderSpan> spans;

  /// Whether the standard vertical padding applies.
  final bool padded;

  String get plainText => spans.map((s) => s.plainText).join();
}

/// Stray top-level text outside any container element.
class LooseTextBlock extends ReaderBlock {
  const LooseTextBlock(this.text);

  final String text;
}

class HeadingBlock extends ReaderBlock {
  const HeadingBlock(this.level, this.spans);

  final int level;
  final List<ReaderSpan> spans;

  String get plainText => spans.map((s) => s.plainText).join();
}

/// `<br>` between blocks.
class SpacerBlock extends ReaderBlock {
  const SpacerBlock();
}

/// `<hr>`.
class RuleBlock extends ReaderBlock {
  const RuleBlock();
}

/// Exactly one of [bytes], [file], [url] is set; decoded during model
/// build so rebuilds never re-decode base64.
class ImageBlock extends ReaderBlock {
  const ImageBlock({this.bytes, this.file, this.url});

  final Uint8List? bytes;
  final String? file;
  final String? url;
}

/// Generic flow container (`div`, unknown tags).
class ContainerBlock extends ReaderBlock {
  const ContainerBlock(this.children);

  final List<ReaderBlock> children;
}

class QuoteBlock extends ReaderBlock {
  const QuoteBlock(this.children);

  final List<ReaderBlock> children;
}

class ListBlock extends ReaderBlock {
  const ListBlock({required this.ordered, required this.items});

  final bool ordered;
  final List<List<ReaderBlock>> items;
}

class ReaderTableCell {
  const ReaderTableCell({required this.children, required this.isHeader});

  final List<ReaderBlock> children;
  final bool isHeader;
}

class ReaderTableRow {
  const ReaderTableRow(this.cells);

  final List<ReaderTableCell> cells;
}

class TableBlock extends ReaderBlock {
  const TableBlock(this.rows);

  final List<ReaderTableRow> rows;
}
