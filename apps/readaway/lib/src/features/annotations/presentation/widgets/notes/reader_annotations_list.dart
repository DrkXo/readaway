import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/services/toast/toast_service.dart';
import '../../../../../core/services/toast/toast_types.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/theme/tts_highlight_palette.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entity/reader_note.dart';
import '../../../domain/entity/reader_notes_filter.dart';
import '../../bloc/annotations_bloc.dart';
import 'reader_note_editor_sheet.dart';
import 'reader_note_labels.dart';
import 'reader_notes_filter_bar.dart';

/// Every highlight and note in the open document.
///
/// Bookmarks are not listed here; they have their own tab. Rows vary in height
/// because a note body can be any length, so this list is measured rather than
/// extent-driven.
class ReaderAnnotationsList extends StatelessWidget {
  const ReaderAnnotationsList({super.key, required this.onJumpToNote});

  /// Called with the annotation the reader tapped.
  final ValueChanged<ReaderNote> onJumpToNote;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnotationsBloc, AnnotationsState>(
      builder: (context, state) {
        // Two different kinds of empty, and only one of them has an action.
        // Nothing annotated yet is a prompt to go and annotate; nothing
        // matching means the filter is hiding everything, so it offers to lift
        // the filter instead.
        if (state.annotations.isEmpty) {
          return const AppEmptyView(
            icon: LucideIcons.bookOpen,
            title: 'No highlights yet',
            message: 'Select text while reading to highlight it or add a note.',
          );
        }

        final visible = state.visibleAnnotations;

        return Column(
          children: [
            const ReaderNotesFilterBar(),
            Expanded(
              child: visible.isEmpty
                  ? AppEmptyView(
                      icon: LucideIcons.searchX,
                      title: 'Nothing matches',
                      message:
                          'No highlight or note matches the current filter.',
                      actionLabel: 'Clear filters',
                      onAction: () => context.read<AnnotationsBloc>().add(
                        const AnnotationsEvent.filterChanged(
                          filter: ReaderNotesFilter(),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final note = visible[index];
                        return _AnnotationTile(
                          key: ValueKey(note.id),
                          note: note,
                          onTap: () => onJumpToNote(note),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AnnotationTile extends StatelessWidget {
  const _AnnotationTile({
    super.key,
    required this.note,
    required this.onTap,
  });

  final ReaderNote note;
  final VoidCallback onTap;

  /// What this annotation is, in words.
  ///
  /// The row's colour already says a highlight is there; this says which kind
  /// it is, so the list never relies on colour alone. Shared with the filter
  /// menu so a hidden row is named the same way it was listed.
  String get _styleLabel => readerNoteKindLabel(note);

  String get _location => readerNoteLocationLabel(note.anchor);

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final bloc = context.read<AnnotationsBloc>();

    // An unpainted note has no highlight colour to show, so its rule is a
    // neutral one rather than a colour the reader never chose.
    final ruleColor = note.isPainted
        ? resolveTtsHighlightColor(
            note.colorValue,
            Theme.of(context).colorScheme,
          )
        : appColors.borderSubtle;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              // Tall enough to read as a rule beside two lines of text, and it
              // grows with the row rather than being pinned to a fixed height.
              constraints: const BoxConstraints(minHeight: 32),
              decoration: BoxDecoration(
                color: ruleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    note.anchor.text,
                    variant: AppTextVariant.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note.hasNoteBody) ...[
                    const SizedBox(height: 4),
                    // Plain text: a row is a summary, and rendering Markdown
                    // per row would cost more than it explains. The note's own
                    // sheet renders it properly.
                    AppText(
                      note.note,
                      variant: AppTextVariant.caption,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      color: appColors.sidebarForeground.withValues(alpha: 0.8),
                    ),
                  ],
                  const SizedBox(height: 4),
                  AppText(
                    '$_styleLabel · $_location',
                    variant: AppTextVariant.caption,
                    color: appColors.sidebarForeground.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: Icons.edit_rounded,
              tooltip: 'Edit $_styleLabel',
              semanticLabel: 'Edit $_styleLabel',
              size: AppIconButtonSize.small,
              onPressed: () => ReaderNoteEditorSheet.show(
                context: context,
                anchor: note.anchor,
                note: note,
              ),
            ),
            AppIconButton(
              icon: LucideIcons.trash2,
              tooltip: 'Delete $_styleLabel',
              semanticLabel: 'Delete $_styleLabel',
              size: AppIconButtonSize.small,
              onPressed: () {
                bloc.add(AnnotationsEvent.deleteNote(id: note.id));
                context.showToast(
                  message: '$_styleLabel removed',
                  action: ToastAction(
                    label: 'Undo',
                    onPressed: () => bloc.add(
                      AnnotationsEvent.restoreNote(id: note.id),
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
