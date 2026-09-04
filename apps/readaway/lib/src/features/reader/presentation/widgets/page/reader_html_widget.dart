import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../core/models/reader/reader_block.dart';
import '../../../../../core/models/reader/reader_document.dart';
import '../../../../../core/theme/theme.dart';
import '../../extensions/reader_block_list_extension.dart';

class ReaderHtmlWidget extends StatefulWidget {
  const ReaderHtmlWidget({
    super.key,
    required this.document,
    required this.appColors,
    this.baseFontSize = 18.0,
    this.lineHeight = 1.75,
    this.letterSpacing = -0.2,
    this.fontFamily,
    this.fontWeight = FontWeight.normal,
    this.wordSpacing = 0,
    this.textIndent = 0,
    this.fullJustification = true,
    this.paragraphMargin = 8,
    this.serifFont = 'Noto Serif',
    this.sansSerifFont = 'Noto Sans',
    this.monospaceFont = 'Fira Code',
    this.overrideFont = false,
    this.onTapUrl,
  });

  final ReaderDocument document;
  final AppColors appColors;
  final double baseFontSize;
  final double lineHeight;
  final double letterSpacing;
  final String? fontFamily;
  final FontWeight fontWeight;
  final double wordSpacing;
  final double textIndent;
  final bool fullJustification;

  /// Vertical padding applied around each paragraph block.
  final double paragraphMargin;

  /// Font used for the book's `font-family: serif` generic family.
  final String serifFont;

  /// Font used for the book's `font-family: sans-serif` generic family.
  final String sansSerifFont;

  /// Font used for the book's `font-family: monospace` generic family (and
  /// `<code>`/`<tt>`).
  final String monospaceFont;

  /// When true, force [fontFamily] on all text, ignoring the book's own
  /// `font-family` declarations.
  final bool overrideFont;

  final void Function(String url)? onTapUrl;

  @override
  State<ReaderHtmlWidget> createState() => _ReaderHtmlWidgetState();

  /// Maps a parsed block list onto widgets. Exposed for tests.
  static List<Widget> buildBlocks(
    List<ReaderBlock> blocks, {
    required TextStyle baseStyle,
    required Color foregroundColor,
    double paragraphMargin = 8,
    double textIndent = 0,
    bool fullJustification = true,
    String serifFont = 'Noto Serif',
    String sansSerifFont = 'Noto Sans',
    String monospaceFont = 'Fira Code',
    bool overrideFont = false,
    TapGestureRecognizer? Function(String href)? recognizerFor,
  }) {
    return blocks.mapBlocks(
      PaintContext(
        baseStyle: baseStyle,
        foregroundColor: foregroundColor,
        paragraphMargin: paragraphMargin,
        textIndent: textIndent,
        fullJustification: fullJustification,
        serifFont: serifFont,
        sansSerifFont: sansSerifFont,
        monospaceFont: monospaceFont,
        overrideFont: overrideFont,
        recognizerFor: recognizerFor,
      ),
    );
  }
}

class _ReaderHtmlWidgetState extends State<ReaderHtmlWidget> {
  final ReaderLinkHandlers _linkHandlers = ReaderLinkHandlers();

  @override
  void dispose() {
    _linkHandlers.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReaderHtmlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      _linkHandlers.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    _linkHandlers.onTapUrl = widget.onTapUrl;

    if (widget.document.blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ReaderHtmlWidget.buildBlocks(
        widget.document.blocks,
        baseStyle: readerTextStyle(
          appColors: widget.appColors,
          fontSize: widget.baseFontSize,
          height: widget.lineHeight,
          letterSpacing: widget.letterSpacing,
          fontFamily: widget.fontFamily,
          fontWeight: widget.fontWeight,
        ),
        foregroundColor: widget.appColors.readerForeground,
        paragraphMargin: widget.paragraphMargin,
        textIndent: widget.textIndent,
        fullJustification: widget.fullJustification,
        serifFont: widget.serifFont,
        sansSerifFont: widget.sansSerifFont,
        monospaceFont: widget.monospaceFont,
        overrideFont: widget.overrideFont,
        recognizerFor: _linkHandlers.recognizerFor,
      ),
    );
  }
}

/// Owns one recognizer per href so taps survive rebuilds without leaking.
class ReaderLinkHandlers {
  final Map<String, TapGestureRecognizer> _byHref = {};

  /// Latest tap target; recognizers read this at tap time.
  void Function(String url)? onTapUrl;

  TapGestureRecognizer? recognizerFor(String href) {
    return _byHref.putIfAbsent(href, () {
      final recognizer = TapGestureRecognizer();
      recognizer.onTap = () => onTapUrl?.call(href);
      return recognizer;
    });
  }

  void dispose() {
    for (final r in _byHref.values) {
      r.dispose();
    }
    _byHref.clear();
  }
}

class PaintContext {
  const PaintContext({
    required this.baseStyle,
    required this.foregroundColor,
    this.paragraphMargin = 8,
    this.textIndent = 0,
    this.fullJustification = true,
    this.serifFont = 'Noto Serif',
    this.sansSerifFont = 'Noto Sans',
    this.monospaceFont = 'Fira Code',
    this.overrideFont = false,
    this.recognizerFor,
  });

  final TextStyle baseStyle;
  final Color foregroundColor;
  final double paragraphMargin;
  final double textIndent;
  final bool fullJustification;
  final String serifFont;
  final String sansSerifFont;
  final String monospaceFont;
  final bool overrideFont;
  final TapGestureRecognizer? Function(String href)? recognizerFor;
}
