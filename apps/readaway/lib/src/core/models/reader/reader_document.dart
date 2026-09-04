import 'reader_block.dart';

/// Representation of a parsed reader page or document.
///
/// Contains the pure [ReaderBlock] AST produced by [DocumentParser].
/// Decoupled from Flutter's rendering tree so theme and typography changes
/// do not require re-parsing.
class ReaderDocument {
  const ReaderDocument({
    required this.blocks,
    this.modalFontSize,
  });

  final List<ReaderBlock> blocks;

  /// Most common font size on the page (MuPDF points), i.e. the body size
  /// all other sizes were measured against.
  final double? modalFontSize;

  static const ReaderDocument empty = ReaderDocument(blocks: []);
}
