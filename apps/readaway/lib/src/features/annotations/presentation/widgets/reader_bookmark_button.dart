import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../core/services/toast/toast_service.dart';
import '../../../../core/services/toast/toast_types.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/services/annotation_anchor_resolver.dart';
import '../bloc/annotations_bloc.dart';

/// Toggles a bookmark at the position the reader is on.
///
/// Takes the position rather than reading the reader bloc, so this stays in the
/// annotations feature and does not reach back into the reader. The host already
/// has that state, and already rebuilds when the page turns.
///
/// The button is `selected` while the current page is bookmarked, so it always
/// says what pressing it will do rather than only what it did last.
class ReaderBookmarkButton extends StatelessWidget {
  const ReaderBookmarkButton({
    super.key,
    required this.isReflowable,
    required this.currentPage,
    this.currentVirtualPage,
    this.size = AppIconButtonSize.small,
  });

  final bool isReflowable;

  /// The current chapter in a reflowable document, or the page in a fixed-layout
  /// one.
  final int currentPage;

  /// The current virtual page, when pagination has measured one.
  final int? currentVirtualPage;

  final AppIconButtonSize size;

  @override
  Widget build(BuildContext context) {
    // Without the coordinator there is no character space to anchor to, so the
    // button would be offering to save a position it cannot describe.
    if (!GetIt.I.isRegistered<PaginationCoordinator>()) {
      return const SizedBox.shrink();
    }

    final anchor = AnnotationAnchorResolver(GetIt.I<PaginationCoordinator>())
        .anchorForReadingPosition(
          isReflowable: isReflowable,
          currentPage: currentPage,
          currentVirtualPage: currentVirtualPage,
        );

    final bloc = context.read<AnnotationsBloc>();
    final bookmarked = context.select<AnnotationsBloc, bool>(
      (annotations) => annotations.state.hasBookmarkAt(anchor),
    );

    return AppIconButton(
      icon: LucideIcons.bookmark,
      tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark this page',
      semanticLabel: bookmarked ? 'Remove bookmark' : 'Bookmark this page',
      size: size,
      selected: bookmarked,
      onPressed: () {
        // Toggling is its own inverse, so undo is the same event.
        bloc.add(AnnotationsEvent.toggleBookmark(anchor: anchor));
        context.showToast(
          message: bookmarked ? 'Bookmark removed' : 'Bookmarked',
          action: ToastAction(
            label: 'Undo',
            onPressed: () =>
                bloc.add(AnnotationsEvent.toggleBookmark(anchor: anchor)),
          ),
        );
      },
    );
  }
}
