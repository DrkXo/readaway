import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/toast/toast_service.dart';
import '../../../../../core/services/toast/toast_types.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entity/reader_note.dart';
import '../../bloc/annotations_bloc.dart';
import 'reader_note_labels.dart';

/// The bookmarks saved in the open document.
///
/// Rows are a uniform height, so the list is laid out from an item extent
/// rather than measured — worth having in a drawer that scrolls with a book
/// behind it.
class ReaderBookmarksList extends StatelessWidget {
  const ReaderBookmarksList({super.key, required this.onJumpToNote});

  /// Called with the bookmark the reader tapped.
  final ValueChanged<ReaderNote> onJumpToNote;

  static const double _itemExtent = 64;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnotationsBloc, AnnotationsState>(
      builder: (context, state) {
        final bookmarks = state.bookmarks;

        if (bookmarks.isEmpty) {
          return const AppEmptyView(
            icon: LucideIcons.bookmark,
            title: 'No bookmarks',
            message: 'Tap the bookmark button while reading to save a place.',
          );
        }

        return ListView.builder(
          itemExtent: _itemExtent,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return _BookmarkTile(
              key: ValueKey(bookmark.id),
              bookmark: bookmark,
              onTap: () => onJumpToNote(bookmark),
            );
          },
        );
      },
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    super.key,
    required this.bookmark,
    required this.onTap,
  });

  final ReaderNote bookmark;
  final VoidCallback onTap;

  /// How the bookmark addresses its place, in the words the reader saw when
  /// they made it.
  String get _location => readerNoteLocationLabel(bookmark.anchor);

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final bloc = context.read<AnnotationsBloc>();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              LucideIcons.bookmark,
              size: 14,
              color: appColors.sidebarForeground.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    bookmark.anchor.text,
                    variant: AppTextVariant.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    _location,
                    variant: AppTextVariant.caption,
                    color: appColors.sidebarForeground.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: LucideIcons.trash2,
              tooltip: 'Delete bookmark',
              semanticLabel: 'Delete bookmark',
              size: AppIconButtonSize.small,
              // Deleting is a tombstone, so the undo is its exact inverse and
              // the bookmark comes back with its original content.
              onPressed: () {
                bloc.add(AnnotationsEvent.deleteNote(id: bookmark.id));
                context.showToast(
                  message: 'Bookmark removed',
                  action: ToastAction(
                    label: 'Undo',
                    onPressed: () => bloc.add(
                      AnnotationsEvent.restoreNote(id: bookmark.id),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
