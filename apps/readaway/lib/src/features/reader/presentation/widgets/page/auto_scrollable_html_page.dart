import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../settings/domain/models/reader_preferences.dart';
import '../../controllers/auto_scroll_controller.dart';
import 'reader_html_widget.dart';
import 'reader_selection_area.dart';

class AutoScrollableHtmlPage extends StatefulWidget {
  const AutoScrollableHtmlPage({
    super.key,
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
  State<AutoScrollableHtmlPage> createState() => AutoScrollableHtmlPageState();
}

class AutoScrollableHtmlPageState extends State<AutoScrollableHtmlPage> {
  final ScrollController _scrollController = ScrollController();

  static FontWeight _resolveFontWeight(String weight) => switch (weight) {
    'lighter' => FontWeight.w300,
    'bold' => FontWeight.w700,
    _ => FontWeight.normal,
  };

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
                  fontWeight: _resolveFontWeight(widget.prefs.fontWeight),
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
