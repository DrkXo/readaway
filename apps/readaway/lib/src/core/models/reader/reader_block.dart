import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Intermediate representation between MuPDF HTML and Flutter widgets.
///
/// The block tree is produced by the reader's HTML model builder and mapped
/// onto widgets by the reader widget. Keeping these as plain data models lets
/// TTS iterate [ParagraphBlock]s and annotations/bookmarks anchor to
/// `(pageIndex, blockIndex)`.
sealed class ReaderBlock {
  const ReaderBlock();
}

/// A fused logical paragraph (or a bare block-level link run when
/// [padded] is false) rendered as one soft-wrapping RichText.
class ParagraphBlock extends ReaderBlock {
  const ParagraphBlock(this.spans, {this.padded = true});

  final List<InlineSpan> spans;

  /// Whether the standard vertical padding applies.
  final bool padded;
}

/// Stray top-level text outside any container element.
class LooseTextBlock extends ReaderBlock {
  const LooseTextBlock(this.text);

  final String text;
}

class HeadingBlock extends ReaderBlock {
  const HeadingBlock(this.level, this.spans);

  final int level;
  final List<InlineSpan> spans;
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

/// Provides (possibly cached) gesture recognizers for `<a href>` spans so
/// taps survive rebuilds without leaking; ownership stays with the caller.
typedef RecognizerProvider = TapGestureRecognizer? Function(String href);
