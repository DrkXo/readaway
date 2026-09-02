import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../../../core/models/reader/reader_block.dart';
import '../../../../../core/models/reader/reader_document.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/utils/reader/reader_html_utils.dart' as html_utils;
import '../../extensions/reader_block_list_extension.dart';

class ReaderHtmlWidget extends StatefulWidget {
  const ReaderHtmlWidget({
    super.key,
    required this.html,
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

  final String html;
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
  }) {
    return blocks.mapBlocks(
      PaintContext(
        baseStyle: baseStyle,
        foregroundColor: foregroundColor,
        paragraphMargin: paragraphMargin,
        textIndent: textIndent,
        fullJustification: fullJustification,
      ),
    );
  }
}

class _ReaderHtmlWidgetState extends State<ReaderHtmlWidget> {
  final ReaderLinkHandlers _linkHandlers = ReaderLinkHandlers();

  dom.Document? _parsedDoc;
  double? _modalFontSize;
  ReaderDocument? _document;
  double? _docFontSize;
  double? _docLineHeight;
  double? _docLetterSpacing;
  String? _docFontFamily;
  FontWeight? _docFontWeight;
  String? _docSerifFont;
  String? _docSansSerifFont;
  String? _docMonospaceFont;
  bool? _docOverrideFont;
  AppColors? _docColors;

  @override
  void dispose() {
    _linkHandlers.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReaderHtmlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      // Old spans (and their recognizers) die with the old document.
      _linkHandlers.dispose();
      _parsedDoc = null;
      _document = null;
    }
  }

  ReaderDocument get _documentSynced {
    final cached = _document;
    if (cached != null &&
        _docFontSize == widget.baseFontSize &&
        _docLineHeight == widget.lineHeight &&
        _docLetterSpacing == widget.letterSpacing &&
        _docFontFamily == widget.fontFamily &&
        _docFontWeight == widget.fontWeight &&
        _docSerifFont == widget.serifFont &&
        _docSansSerifFont == widget.sansSerifFont &&
        _docMonospaceFont == widget.monospaceFont &&
        _docOverrideFont == widget.overrideFont &&
        identical(_docColors, widget.appColors)) {
      return cached;
    }

    if (_parsedDoc == null) {
      _parsedDoc = html_parser.parse(widget.html);
      final body = _parsedDoc!.body;
      _modalFontSize = body == null
          ? null
          : html_utils.computeModalFontSize(body);
    }

    final doc = ReaderDocument.fromDom(
      _parsedDoc!,
      appColors: widget.appColors,
      baseFontSize: widget.baseFontSize,
      lineHeight: widget.lineHeight,
      recognizerFor: _linkHandlers.recognizerFor,
      modalFontSize: _modalFontSize,
      serifFont: widget.serifFont,
      sansSerifFont: widget.sansSerifFont,
      monospaceFont: widget.monospaceFont,
      overrideFont: widget.overrideFont,
    );

    _document = doc;
    _docFontSize = widget.baseFontSize;
    _docLineHeight = widget.lineHeight;
    _docLetterSpacing = widget.letterSpacing;
    _docFontFamily = widget.fontFamily;
    _docFontWeight = widget.fontWeight;
    _docSerifFont = widget.serifFont;
    _docSansSerifFont = widget.sansSerifFont;
    _docMonospaceFont = widget.monospaceFont;
    _docOverrideFont = widget.overrideFont;
    _docColors = widget.appColors;
    return doc;
  }

  @override
  Widget build(BuildContext context) {
    _linkHandlers.onTapUrl = widget.onTapUrl;

    final doc = _documentSynced;
    if (doc.blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ReaderHtmlWidget.buildBlocks(
        doc.blocks,
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
  });

  final TextStyle baseStyle;
  final Color foregroundColor;
  final double paragraphMargin;
  final double textIndent;
  final bool fullJustification;
}
