import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../annotations/domain/entity/reader_note.dart';
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
/// Owns the tab bar, so switching tabs never moves it, and so the close or pin
/// action lives in one place rather than being repeated inside each tab. The
/// contents tab is the existing [ReaderTocContent] with its own header row
/// suppressed, because the tab bar is that header now.
class ReaderSidePanel extends StatefulWidget {
  const ReaderSidePanel({
    super.key,
    required this.onJumpToChapter,
    required this.onJumpToNote,
    this.headerAction,
    this.initialTab = ReaderSidePanelTab.contents,
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

  @override
  State<ReaderSidePanel> createState() => _ReaderSidePanelState();
}

class _ReaderSidePanelState extends State<ReaderSidePanel> {
  late ReaderSidePanelTab _active = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Column(
      children: [
        _TabBar(
          active: _active,
          onChanged: (tab) => setState(() => _active = tab),
          action: widget.headerAction,
        ),
        Divider(height: 1, thickness: 1, color: appColors.sidebarBorder),
        Expanded(
          child: switch (_active) {
            ReaderSidePanelTab.contents => ReaderTocContent(
              onJumpToPage: widget.onJumpToChapter,
              showHeader: false,
            ),
            ReaderSidePanelTab.bookmarks => ReaderBookmarksList(
              onJumpToNote: widget.onJumpToNote,
            ),
            ReaderSidePanelTab.annotations => ReaderAnnotationsList(
              onJumpToNote: widget.onJumpToNote,
            ),
          },
        ),
      ],
    );
  }
}

/// The panel's tab row.
///
/// Labels are sentence case at a small size rather than the uppercase, wide
/// letter-spacing the section headers use: three words of that style need more
/// width than a 300px panel has once the action button is accounted for.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.active,
    required this.onChanged,
    this.action,
  });

  final ReaderSidePanelTab active;
  final ValueChanged<ReaderSidePanelTab> onChanged;
  final Widget? action;

  static const Map<ReaderSidePanelTab, String> _labels = {
    ReaderSidePanelTab.contents: 'Contents',
    ReaderSidePanelTab.bookmarks: 'Bookmarks',
    ReaderSidePanelTab.annotations: 'Annotations',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, action == null ? 12 : 4, 0),
      child: Row(
        children: [
          for (final tab in ReaderSidePanelTab.values)
            Expanded(
              child: _Tab(
                label: _labels[tab]!,
                selected: tab == active,
                onTap: () => onChanged(tab),
              ),
            ),
          ?action,
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        // The label alone does not reach a 44pt target, so the whole tab is
        // given that height rather than only the text.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                label,
                variant: AppTextVariant.label,
                fontSize: 12,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? accent
                    : appColors.sidebarForeground.withValues(alpha: 0.75),
              ),
              const SizedBox(height: 6),
              // Colour is not the only signal: the selected tab also carries a
              // rule beneath it, so the state survives a monochrome theme.
              AnimatedContainer(
                duration: context.appMotion.fast,
                height: 2,
                decoration: BoxDecoration(
                  color: selected ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
