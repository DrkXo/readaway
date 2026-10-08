import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/theme/tts_highlight_palette.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entity/reader_note.dart';
import '../../bloc/annotations_bloc.dart';
import 'reader_note_defaults.dart';

/// Writes or edits the note attached to a passage.
///
/// Saving is explicit, but the sheet also commits when it is dismissed. Losing
/// a paragraph the reader just typed because they tapped the barrier is the
/// worst thing this sheet could do, and it is not what tapping a barrier means.
/// [ReaderNoteEditorSheet._commit] is idempotent, so dismissing after saving
/// writes nothing twice.
class ReaderNoteEditorSheet extends StatefulWidget {
  const ReaderNoteEditorSheet({super.key, required this.anchor, this.note});

  /// The passage being annotated. Used to create the note when [note] is null.
  final ReaderNoteAnchor anchor;

  /// The record being edited, or null when writing a new note.
  final ReaderNote? note;

  /// Opens the editor for [note], or for a new note on [anchor].
  static Future<void> show({
    required BuildContext context,
    required ReaderNoteAnchor anchor,
    ReaderNote? note,
  }) => showAppSheet<void>(
    context: context,
    title: note == null ? 'New note' : 'Edit note',
    // A note can be any length, so the sheet grows rather than scrolling a
    // sentence field inside fixed chrome.
    isScrollControlled: true,
    builder: (_) => ReaderNoteEditorSheet(anchor: anchor, note: note),
  );

  @override
  State<ReaderNoteEditorSheet> createState() => _ReaderNoteEditorSheetState();
}

class _ReaderNoteEditorSheetState extends State<ReaderNoteEditorSheet> {
  late final AnnotationsBloc _bloc = context.read<AnnotationsBloc>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.note?.note ?? '',
  );

  /// Seeded from the note and not editable here: this sheet changes a note and
  /// its colour, and style is a separate choice the reader makes when they
  /// paint. Keeping it final means the restyle never silently changes a
  /// squiggly underline into a fill.
  late final HighlightStyle _style =
      widget.note?.style ?? kDefaultHighlightStyle;
  late String _colorValue =
      widget.note?.colorValue ?? kDefaultHighlightColorValue;

  /// Whether the reader has asked to paint a note that was not painted before.
  bool _paint = false;

  /// Guards [._commit] against running twice for one sheet.
  bool _committed = false;

  bool get _isHighlight => widget.note?.isPainted ?? false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Writes what changed, exactly once.
  void _commit() {
    if (_committed) return;
    _committed = true;

    final existing = widget.note;
    final body = _controller.text.trim();

    if (existing == null) {
      // A note with no words and no highlight is not worth saving.
      if (body.isEmpty && !_paint) return;
      _bloc.add(
        AnnotationsEvent.addNote(
          anchor: widget.anchor,
          note: body,
          style: _paint ? _style : null,
          colorValue: _paint ? _colorValue : null,
        ),
      );
      return;
    }

    if (body.isEmpty &&
        existing.hasNoteBody &&
        !existing.isPainted &&
        !_paint) {
      // Emptying the body of a pure note leaves nothing worth keeping, so the record
      // goes rather than lingering as an empty row.
      _bloc.add(AnnotationsEvent.deleteNote(id: existing.id));
      return;
    }

    if (body != existing.note) {
      _bloc.add(AnnotationsEvent.updateNoteBody(id: existing.id, note: body));
    }

    // Called only when something about the painting actually changed, so an
    // untouched highlight is not rewritten just for being opened.
    final shouldPaint = existing.isPainted || _paint;
    if (shouldPaint &&
        (existing.type != ReaderNoteType.highlight ||
            _style != existing.style ||
            _colorValue != existing.colorValue)) {
      _bloc.add(
        AnnotationsEvent.restyleNote(
          id: existing.id,
          style: _style,
          colorValue: _colorValue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _commit();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Excerpt(text: widget.anchor.text),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('note-editor-field'),
              controller: _controller,
              autofocus: widget.note == null,
              minLines: 3,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14, color: appColors.inputForeground),
              decoration: InputDecoration(
                hintText: 'Write a note…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: appColors.inputPlaceholderForeground,
                ),
                filled: true,
                fillColor: appColors.inputBackground,
                contentPadding: const EdgeInsets.all(12),
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
                  borderSide: BorderSide(
                    color: appColors.focusBorder,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_isHighlight || _paint) ...[
              const SizedBox(height: 16),
              AppText(
                'Highlight colour',
                variant: AppTextVariant.label,
                color: appColors.sidebarForeground.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              _ColourSwatches(
                selected: _colorValue,
                onSelected: (value) => setState(() => _colorValue = value),
              ),
            ] else ...[
              const SizedBox(height: 8),
              _PaintToggle(
                value: _paint,
                onChanged: (value) => setState(() => _paint = value),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.note != null)
                  TextButton.icon(
                    onPressed: () {
                      // Deleting is what this sheet means by delete, so the
                      // commit must not also write the body back.
                      _committed = true;
                      _bloc.add(
                        AnnotationsEvent.deleteNote(id: widget.note!.id),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    _commit();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 44),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The passage the note is about, so the writer can see what they are writing
/// about without leaving the sheet.
class _Excerpt extends StatelessWidget {
  const _Excerpt({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: appColors.sidebarBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: appColors.borderSubtle, width: 3),
        ),
      ),
      child: AppText(
        text.isEmpty ? 'This passage' : text,
        variant: AppTextVariant.caption,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        color: appColors.sidebarForeground.withValues(alpha: 0.8),
      ),
    );
  }
}

/// Offers to paint a passage that is currently only a note.
class _PaintToggle extends StatelessWidget {
  const _PaintToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Switch(value: value, onChanged: onChanged),
            const SizedBox(width: 8),
            const Expanded(child: Text('Highlight this passage too')),
          ],
        ),
      ),
    );
  }
}

/// The palette, as swatches.
///
/// Selection is shown by a ring rather than a tick, because a tick has to pick a
/// colour that contrasts with the swatch it sits on, and half this palette is
/// mid-tone.
class _ColourSwatches extends StatelessWidget {
  const _ColourSwatches({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final option in kTtsHighlightColorOptions)
          Semantics(
            button: true,
            selected: option.key == selected,
            label: option.label,
            child: Tooltip(
              message: option.label,
              child: InkWell(
                onTap: () => onSelected(option.key),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: resolveTtsHighlightColor(option.key, scheme),
                    border: Border.all(
                      color: option.key == selected
                          ? scheme.onSurface
                          : scheme.outlineVariant,
                      width: option.key == selected ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
