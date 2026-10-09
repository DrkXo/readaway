import 'package:flutter/material.dart';
import 'package:readaway/src/features/reader/domain/entity/reader_preferences.dart';

import '../../../bloc/reader_bloc.dart';
import 'fixed_layout_reader_page.dart';

/// Utility methods to map between document page indices and dual-page spread indices.
class FixedLayoutSpreadHelper {
  const FixedLayoutSpreadHelper._();

  /// Determines if dual-page spread layout should be active based on user preferences and constraints.
  static bool isDualSpreadActive({
    required ReaderPreferences prefs,
    required BoxConstraints constraints,
  }) {
    switch (prefs.pageSpread) {
      case ReaderPageSpread.single:
        return false;
      case ReaderPageSpread.dual:
        return true;
      case ReaderPageSpread.auto:
        return constraints.maxWidth >= 720 &&
            constraints.maxWidth > constraints.maxHeight;
    }
  }

  /// Calculates the total number of spreads given the document's [pageCount].
  ///
  /// Page 0 is preserved as a standalone cover page. Interior pages are paired
  /// (e.g. [1, 2], [3, 4], ...).
  static int totalSpreads(int pageCount, {required bool isDualSpread}) {
    if (!isDualSpread || pageCount <= 1) return pageCount;
    return 1 + (pageCount ~/ 2);
  }

  /// Maps a document page index (0-based) to its corresponding spread index.
  static int spreadForPage(int pageIndex, {required bool isDualSpread}) {
    if (!isDualSpread || pageIndex <= 0) return pageIndex;
    return ((pageIndex - 1) ~/ 2) + 1;
  }

  /// Resolves the primary document page index associated with [spreadIndex].
  static int primaryPageForSpread(
    int spreadIndex, {
    required bool isDualSpread,
  }) {
    if (!isDualSpread || spreadIndex <= 0) return spreadIndex;
    return (2 * spreadIndex) - 1;
  }

  /// Resolves the pair of page indices `(first, second)` rendered in [spreadIndex].
  ///
  /// [second] is null if [spreadIndex] contains only a single page (e.g. cover page or trailing page).
  static (int first, int? second) pagesForSpread(
    int spreadIndex,
    int pageCount, {
    required bool isDualSpread,
  }) {
    if (!isDualSpread || spreadIndex == 0) {
      return (spreadIndex, null);
    }
    final first = (2 * spreadIndex) - 1;
    final second = (first + 1 < pageCount) ? first + 1 : null;
    return (first, second);
  }
}

/// Renders either a single page or a side-by-side two-page spread with
/// support for Manga RTL and Western LTR reading order.
class FixedLayoutSpreadPage extends StatelessWidget {
  const FixedLayoutSpreadPage({
    super.key,
    required this.spreadIndex,
    required this.state,
    required this.prefs,
    required this.isDualSpread,
    this.isContinuous = false,
    this.onZoomChanged,
    this.onPageChangeRequested,
  });

  final int spreadIndex;
  final ReaderState state;
  final ReaderPreferences prefs;
  final bool isDualSpread;
  final bool isContinuous;
  final ValueChanged<bool>? onZoomChanged;
  final ValueChanged<int>? onPageChangeRequested;

  @override
  Widget build(BuildContext context) {
    final (
      firstPageIndex,
      secondPageIndex,
    ) = FixedLayoutSpreadHelper.pagesForSpread(
      spreadIndex,
      state.pageCount,
      isDualSpread: isDualSpread,
    );

    final firstPage = FixedLayoutReaderPage(
      key: ValueKey('spread_page_${state.documentPath}_$firstPageIndex'),
      index: firstPageIndex,
      state: state,
      prefs: prefs,
      isContinuous: isContinuous,
      onZoomChanged: onZoomChanged,
      onPageChangeRequested: onPageChangeRequested,
    );

    if (secondPageIndex == null) {
      return Center(child: firstPage);
    }

    final secondPage = FixedLayoutReaderPage(
      key: ValueKey('spread_page_${state.documentPath}_$secondPageIndex'),
      index: secondPageIndex,
      state: state,
      prefs: prefs,
      isContinuous: isContinuous,
      onZoomChanged: onZoomChanged,
      onPageChangeRequested: onPageChangeRequested,
    );

    // In Manga RTL mode, earlier page is on the right, later page is on the left.
    // In Western LTR mode, earlier page is on the left, later page is on the right.
    final leftChild = prefs.isRtl ? secondPage : firstPage;
    final rightChild = prefs.isRtl ? firstPage : secondPage;

    final theme = Theme.of(context);
    final spineDividerColor = theme.colorScheme.outlineVariant.withValues(
      alpha: 0.2,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: leftChild),
        Container(
          width: 1.0,
          color: spineDividerColor,
        ),
        Expanded(child: rightChild),
      ],
    );
  }
}
