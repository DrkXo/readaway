import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entity/reader_note.dart';
import '../../../domain/entity/reader_notes_filter.dart';
import '../../bloc/annotations_bloc.dart';
import 'reader_note_labels.dart';

/// Narrows the Annotations tab.
///
/// Lives inside the list rather than over it, so hiding the filter is not a
/// separate mode the panel has to know about, and so the "no matches" state can
/// be shown where the rows would have been.
class ReaderNotesFilterBar extends StatelessWidget {
  const ReaderNotesFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnotationsBloc, AnnotationsState>(
      // Only what the bar itself shows: the filter, and the colours and styles
      // there are to offer. A page turn or a TTS tick changes none of it.
      buildWhen: (previous, current) =>
          previous.filter != current.filter ||
          !identical(previous.notes, current.notes),
      builder: (context, state) {
        final bloc = context.read<AnnotationsBloc>();
        final filter = state.filter;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: AppSegmentedControl<ReaderNoteKindFilter>(
                      value: filter.kind,
                      onChanged: (kind) => bloc.add(
                        AnnotationsEvent.filterChanged(
                          filter: filter.copyWith(kind: kind),
                        ),
                      ),
                      segments: const [
                        AppSegment(
                          value: ReaderNoteKindFilter.all,
                          label: 'All',
                        ),
                        AppSegment(
                          value: ReaderNoteKindFilter.highlights,
                          label: 'Highlights',
                        ),
                        AppSegment(
                          value: ReaderNoteKindFilter.notes,
                          label: 'Notes',
                        ),
                      ],
                    ),
                  ),
                  if (state.availableColors.isNotEmpty ||
                      state.availableStyles.isNotEmpty)
                    _ExclusionMenu(state: state),
                ],
              ),
            ),
            _SearchField(
              query: filter.query,
              onChanged: (query) => bloc.add(
                AnnotationsEvent.filterChanged(
                  filter: filter.copyWith(query: query),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Hides annotations by colour or style, and clears the whole filter.
///
/// The menu offers *exclusions*, so a colour the reader has never seen — one
/// they just added, or a preset from a newer build — stays visible until they
/// choose to hide it.
class _ExclusionMenu extends StatelessWidget {
  const _ExclusionMenu({required this.state});

  final AnnotationsState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AnnotationsBloc>();
    final filter = state.filter;

    void apply(ReaderNotesFilter next) =>
        bloc.add(AnnotationsEvent.filterChanged(filter: next));

    return AppPopupMenu<String>(
      tooltip: 'Filter by colour or style',
      offset: const Offset(0, 4),
      onSelected: (value) {
        if (value == 'clear') {
          apply(const ReaderNotesFilter());
          return;
        }
        if (value.startsWith('color:')) {
          final color = value.substring('color:'.length);
          final excluded = {...filter.excludedColors};
          excluded.contains(color)
              ? excluded.remove(color)
              : excluded.add(color);
          apply(filter.copyWith(excludedColors: excluded));
          return;
        }
        final style = HighlightStyle.values.firstWhere(
          (candidate) => candidate.name == value.substring('style:'.length),
        );
        final excluded = {...filter.excludedStyles};
        excluded.contains(style) ? excluded.remove(style) : excluded.add(style);
        apply(filter.copyWith(excludedStyles: excluded));
      },
      entries: [
        if (filter.isActive) ...[
          const AppPopupEntry<String>(value: 'clear', label: 'Clear filters'),
          const AppPopupDivider(),
        ],
        if (state.availableColors.isNotEmpty) ...[
          const AppPopupHeader('Hide these colours'),
          for (final color in state.availableColors)
            AppPopupEntry<String>(
              value: 'color:$color',
              label: readerNoteColorLabel(color),
              icon: filter.excludedColors.contains(color)
                  ? Icons.check_rounded
                  : null,
            ),
        ],
        if (state.availableStyles.isNotEmpty) ...[
          if (state.availableColors.isNotEmpty) const AppPopupDivider(),
          const AppPopupHeader('Hide these styles'),
          for (final style in state.availableStyles)
            AppPopupEntry<String>(
              value: 'style:${style.name}',
              label: readerHighlightStyleLabel(style),
              icon: filter.excludedStyles.contains(style)
                  ? Icons.check_rounded
                  : null,
            ),
        ],
      ],
      child: const Padding(
        // Padded to a 44pt target rather than left as a bare icon.
        padding: EdgeInsets.all(14),
        child: Icon(LucideIcons.slidersHorizontal, size: 16),
      ),
    );
  }
}

/// Searches note bodies and the excerpts they were made from.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.query, required this.onChanged});

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );

  @override
  void didUpdateWidget(_SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The filter can be cleared from the menu, so the field follows it — but it
    // never rewrites what is being typed, which would fight the typist.
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: SizedBox(
        height: 44,
        child: TextField(
          key: const ValueKey('annotations-search-field'),
          controller: _controller,
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(fontSize: 13, color: appColors.inputForeground),
          decoration: InputDecoration(
            hintText: 'Search highlights and notes…',
            hintStyle: TextStyle(
              fontSize: 13,
              color: appColors.inputPlaceholderForeground,
            ),
            prefixIcon: const Icon(LucideIcons.search, size: 16),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(LucideIcons.x, size: 16),
                  ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            filled: true,
            fillColor: appColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: appColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: appColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: appColors.focusBorder, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
