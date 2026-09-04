import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/services/services.dart';
import '../../../../../../core/theme/theme.dart';
import '../../../../../settings/domain/models/reader_preferences.dart';
import '../../../bloc/reader_bloc.dart';
import '../reader_document_view.dart';
import '../reader_selection_area.dart';

/// A reflowable document page item widget that lazily loads and renders page content.
class ReflowablePageItem extends StatelessWidget {
  const ReflowablePageItem({
    super.key,
    required this.index,
    required this.state,
    required this.prefs,
    required this.onPageChangeRequested,
  });

  final int index;
  final ReaderState state;
  final ReaderPreferences prefs;
  final void Function(int) onPageChangeRequested;

  static FontWeight _resolveFontWeight(String weight) => switch (weight) {
    'lighter' => FontWeight.w300,
    'bold' => FontWeight.w700,
    _ => FontWeight.normal,
  };

  @override
  Widget build(BuildContext context) {
    final doc = state.documentPages != null && index < state.documentPages!.length
        ? state.documentPages![index]
        : null;

    if (doc == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final bloc = context.read<ReaderBloc>();
          if (!bloc.isClosed) {
            bloc.add(ReaderEvent.loadPage(index: index));
          }
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: prefs.marginTop,
            bottom: prefs.marginBottom,
            left: prefs.marginHorizontal,
            right: prefs.marginHorizontal,
          ),
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                0.0,
                constraints.maxHeight -
                    prefs.marginTop -
                    prefs.marginBottom,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ReaderSelectionArea(
                child: ReaderDocumentView(
                  document: doc,
                  appColors: context.appColors,
                  baseFontSize: prefs.fontSize,
                  lineHeight: prefs.lineHeight,
                  letterSpacing: prefs.letterSpacing,
                  fontFamily: prefs.fontFamily,
                  fontWeight: _resolveFontWeight(prefs.fontWeight),
                  wordSpacing: prefs.wordSpacing,
                  textIndent: prefs.textIndent,
                  fullJustification: prefs.fullJustification,
                  paragraphMargin: prefs.paragraphMargin,
                  serifFont: prefs.serifFont,
                  sansSerifFont: prefs.sansSerifFont,
                  monospaceFont: prefs.monospaceFont,
                  overrideFont: prefs.overrideFont,
                  onTapUrl: (url) => _onTapUrl(context, url),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTapUrl(BuildContext context, String url) {
    final match = RegExp(r'^#page=(\d+)$').firstMatch(url);
    if (match != null) {
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      onPageChangeRequested(
        int.parse(match.group(1)!).clamp(0, maxIndex),
      );
      return;
    }
    logger.d('External link ignored: $url');
  }
}
