part of '../reader_widgets.dart';

/// A single reflowable page that owns its vertical [ScrollController] and
/// registers it with the [AutoScrollController] so auto-scroll can drive it.
///
/// Owning the controller in a `StatefulWidget` is important: `PageView.builder`
/// mounts/unmounts pages on demand, so the controller must be created and
/// disposed alongside the page to avoid leaking or holding stale references.
class _AutoScrollableHtmlPage extends StatefulWidget {
  const _AutoScrollableHtmlPage({
    required this.index,
    required this.html,
    required this.prefs,
    required this.autoScrollController,
    required this.onTapUrl,
  });

  final int index;
  final String html;
  final ReaderPreferences prefs;
  final AutoScrollController? autoScrollController;
  final ValueChanged<String> onTapUrl;

  @override
  State<_AutoScrollableHtmlPage> createState() =>
      _AutoScrollableHtmlPageState();
}

class _AutoScrollableHtmlPageState extends State<_AutoScrollableHtmlPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.autoScrollController?.registerPage(widget.index, _scrollController);
  }

  @override
  void dispose() {
    widget.autoScrollController?.unregisterPage(widget.index);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: widget.prefs.marginTop,
            bottom: widget.prefs.marginBottom,
            left: widget.prefs.marginHorizontal,
            right: widget.prefs.marginHorizontal,
          ),
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Clamp to 0: during initial layout the viewport height can be
              // 0, which would otherwise produce a negative (invalid) minHeight.
              minHeight: math.max(
                0.0,
                constraints.maxHeight -
                    widget.prefs.marginTop -
                    widget.prefs.marginBottom,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ReaderSelectionArea(
                child: ReaderHtmlWidget(
                  html: widget.html,
                  appColors: context.appColors,
                  baseFontSize: widget.prefs.fontSize,
                  lineHeight: widget.prefs.lineHeight,
                  letterSpacing: widget.prefs.letterSpacing,
                  fontFamily: widget.prefs.fontFamily,
                  fontWeight: ReaderPageContent._resolveFontWeight(
                    widget.prefs.fontWeight,
                  ),
                  wordSpacing: widget.prefs.wordSpacing,
                  textIndent: widget.prefs.textIndent,
                  fullJustification: widget.prefs.fullJustification,
                  paragraphMargin: widget.prefs.paragraphMargin,
                  serifFont: widget.prefs.serifFont,
                  sansSerifFont: widget.prefs.sansSerifFont,
                  monospaceFont: widget.prefs.monospaceFont,
                  overrideFont: widget.prefs.overrideFont,
                  onTapUrl: widget.onTapUrl,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
