import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/core_widgets.dart';
import '../../../../annotations/domain/entity/reader_note.dart';
import '../../../../annotations/presentation/bloc/annotations_bloc.dart';
import '../../../../annotations/presentation/widgets/notes/reader_annotations_list.dart';
import '../../../../annotations/presentation/widgets/notes/reader_bookmarks_list.dart';
import 'reader_toc_content.dart';

/// Which view the side panel is showing.
enum ReaderSidePanelTab {
  /// The document's table of contents.
  contents,

  /// Places the reader saved.
  bookmarks,

  /// Highlights and notes.
  annotations,
}

/// The reader's side panel, holding contents, bookmarks and annotations.
///
/// Designed with authentic Windows Phone / Lumia [MetroPivot] panoramic navigation,
/// enabling continuous horizontal swipe gestures, parallax header glide, and
/// live note/bookmark count badges.
class ReaderSidePanel extends StatefulWidget {
  const ReaderSidePanel({
    super.key,
    required this.onJumpToChapter,
    required this.onJumpToNote,
    this.headerAction,
    this.initialTab = ReaderSidePanelTab.contents,
    this.title = 'contents',
  });

  /// Called with a chapter index when a contents entry is chosen.
  final ValueChanged<int> onJumpToChapter;

  /// Called with the bookmark or annotation whose row was chosen.
  final ValueChanged<ReaderNote> onJumpToNote;

  /// Trailing control in the tab bar: a close button on compact layouts, a pin
  /// toggle on wide ones.
  final Widget? headerAction;

  /// Which tab to open on. The panel is rebuilt rather than reused, so this is
  /// not restored across openings — the reader's place in the book is the thing
  /// worth remembering, not the last tab.
  final ReaderSidePanelTab initialTab;

  /// The grand display title of the panorama (default 'contents').
  final String title;

  @override
  State<ReaderSidePanel> createState() => _ReaderSidePanelState();
}

class _ReaderSidePanelState extends State<ReaderSidePanel> {
  late final MetroPivotController _pivotController;

  @override
  void initState() {
    super.initState();
    _pivotController = MetroPivotController(
      length: ReaderSidePanelTab.values.length,
      initialIndex: widget.initialTab.index,
    );
  }

  @override
  void didUpdateWidget(ReaderSidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        _pivotController.index != widget.initialTab.index) {
      _pivotController.animateTo(widget.initialTab.index);
    }
  }

  @override
  void dispose() {
    _pivotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AnnotationsState? annotationsState;
    try {
      annotationsState = context.watch<AnnotationsBloc>().state;
    } catch (_) {
      // AnnotationsBloc not available in isolated test harness
    }

    final bookmarkCount = annotationsState?.bookmarks.length;
    final annotationCount = annotationsState?.annotations.length;

    return MetroPivot(
      controller: _pivotController,
      title: widget.title,
      titleFontSize: 38,
      tabFontSize: 22,
      trailing: widget.headerAction,
      headerPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      items: [
        MetroPivotItem(
          label: 'contents',
          content: ReaderTocContent(
            onJumpToPage: widget.onJumpToChapter,
            showHeader: false,
          ),
        ),
        MetroPivotItem(
          label: 'bookmarks',
          count: bookmarkCount != null && bookmarkCount > 0
              ? '$bookmarkCount'
              : null,
          content: ReaderBookmarksList(
            onJumpToNote: widget.onJumpToNote,
          ),
        ),
        MetroPivotItem(
          label: 'annotations',
          count: annotationCount != null && annotationCount > 0
              ? '$annotationCount'
              : null,
          content: ReaderAnnotationsList(
            onJumpToNote: widget.onJumpToNote,
          ),
        ),
      ],
    );
  }
}
