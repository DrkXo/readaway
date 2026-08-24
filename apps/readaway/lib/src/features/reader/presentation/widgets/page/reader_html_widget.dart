part of '../reader_widgets.dart';

/// Renders MuPDF structured-text HTML as soft-wrapping [RichText]
/// paragraphs.
///
/// Parsing, line fusion and span construction run once per content change
/// and live in [ReaderDocument] (`core/models/reader/reader_document.dart`);
/// this widget only maps blocks onto widgets. Theme or typography changes
/// rebuild from the cached document without re-parsing. Colors come from the
/// app theme; [ReaderHtmlWidget.baseFontSize] acts as the scale anchor.
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
    return _mapBlocks(
      blocks,
      _PaintContext(
        baseStyle: baseStyle,
        foregroundColor: foregroundColor,
        paragraphMargin: paragraphMargin,
        textIndent: textIndent,
        fullJustification: fullJustification,
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
      _modalFontSize = body == null ? null : computeModalFontSize(body);
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
          wordSpacing: widget.wordSpacing,
        ),
        foregroundColor: widget.appColors.readerForeground,
        paragraphMargin: widget.paragraphMargin,
        textIndent: widget.textIndent,
        fullJustification: widget.fullJustification,
      ),
    );
  }
}

class _PaintContext {
  const _PaintContext({
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

List<Widget> _mapBlocks(List<ReaderBlock> blocks, _PaintContext ctx) {
  final widgets = <Widget>[];
  for (final block in blocks) {
    final widget = _mapBlock(block, ctx);
    if (widget != null) widgets.add(widget);
  }
  return widgets;
}

Widget? _mapBlock(ReaderBlock block, _PaintContext ctx) {
  switch (block) {
    case ParagraphBlock(:final spans, :final padded):
      final textAlign = ctx.fullJustification ? TextAlign.justify : null;
      final effectiveSpans = <InlineSpan>[
        if (ctx.textIndent > 0)
          TextSpan(
            text: '\u200B${' ' * ctx.textIndent.round()}',
            style: ctx.baseStyle,
          ),
        ...spans,
      ];
      final rich = Text.rich(
        TextSpan(children: effectiveSpans, style: ctx.baseStyle),
        textAlign: textAlign,
      );
      if (!padded) return RepaintBoundary(child: rich);
      return Padding(
        padding: EdgeInsets.symmetric(vertical: ctx.paragraphMargin),
        child: RepaintBoundary(child: rich),
      );
    case LooseTextBlock(:final text):
      return Text(text, style: ctx.baseStyle);
    case HeadingBlock(:final level, :final spans):
      final style = switch (level) {
        1 => ctx.baseStyle.copyWith(
          fontSize: ctx.baseStyle.fontSize! * 1.5,
          fontWeight: FontWeight.bold,
        ),
        2 => ctx.baseStyle.copyWith(
          fontSize: ctx.baseStyle.fontSize! * 1.3,
          fontWeight: FontWeight.bold,
        ),
        3 => ctx.baseStyle.copyWith(
          fontSize: ctx.baseStyle.fontSize! * 1.1,
          fontWeight: FontWeight.bold,
        ),
        _ => ctx.baseStyle.copyWith(fontWeight: FontWeight.bold),
      };
      return Padding(
        padding: EdgeInsets.only(top: level == 1 ? 24 : 16, bottom: 8),
        child: RepaintBoundary(
          child: Text.rich(TextSpan(children: spans, style: style)),
        ),
      );
    case SpacerBlock():
      return const SizedBox(height: 16);
    case RuleBlock():
      return const Divider();
    case ImageBlock():
      Widget image;
      if (block.bytes != null) {
        image = Image.memory(block.bytes!, fit: BoxFit.contain);
      } else if (block.file != null) {
        image = Image.file(File(block.file!), fit: BoxFit.contain);
      } else if (block.url != null) {
        image = Image.network(block.url!, fit: BoxFit.contain);
      } else {
        return null;
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RepaintBoundary(child: image),
      );
    case ContainerBlock(:final children):
      final mapped = _mapBlocks(children, ctx);
      if (mapped.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: mapped,
      );
    case QuoteBlock(:final children):
      final mapped = _mapBlocks(children, ctx);
      if (mapped.isEmpty) return null;
      return Padding(
        padding: const EdgeInsets.only(left: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: ctx.foregroundColor.withValues(alpha: 0.3),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: mapped,
            ),
          ),
        ),
      );
    case ListBlock(:final ordered, :final items):
      final children = <Widget>[];
      var index = 1;
      for (final item in items) {
        final prefix = ordered ? '$index. ' : '\u2022 ';
        index++;
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prefix, style: ctx.baseStyle),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _mapBlocks(item, ctx),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      if (children.isEmpty) return null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    case TableBlock(:final rows):
      final tableRows = <TableRow>[];
      for (final row in rows) {
        final cells = <Widget>[];
        for (final cell in row.cells) {
          cells.add(
            Padding(
              padding: const EdgeInsets.all(8),
              child: DefaultTextStyle(
                style: ctx.baseStyle.copyWith(
                  fontWeight: cell.isHeader ? FontWeight.bold : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _mapBlocks(cell.children, ctx),
                ),
              ),
            ),
          );
        }
        if (cells.isNotEmpty) tableRows.add(TableRow(children: cells));
      }
      if (tableRows.isEmpty) return null;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(
            color: ctx.foregroundColor.withValues(alpha: 0.2),
          ),
          children: tableRows,
        ),
      );
  }
}
