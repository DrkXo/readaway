library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import 'outline_item_tile.dart';

enum TocTab { chapters, pages }

/// Shared table-of-contents UI used by the mobile drawer and the
/// desktop side panel.
class ReaderTocContent extends StatefulWidget {
  const ReaderTocContent({
    super.key,
    required this.onJumpToPage,
    this.headerAction,
  });

  final void Function(int page) onJumpToPage;

  /// Trailing widget in the header row (close button, pin toggle, ...).
  final Widget? headerAction;

  @override
  State<ReaderTocContent> createState() => _ReaderTocContentState();
}

class _ReaderTocContentState extends State<ReaderTocContent> {
  /// Fixed row height so the scroll offset for any outline index is
  /// computable without building the item (ListView is lazy).
  static const double _itemExtent = 56;

  final _scrollController = ScrollController();
  int _lastScrolledIndex = -1;
  TocTab _activeTab = TocTab.chapters;

  /// Index of the outline item covering [currentPage], -1 if none.
  static int _indexOfCurrent(List<OutlineItem> outline, int currentPage) {
    var index = -1;
    for (var i = 0; i < outline.length; i++) {
      final target = outline[i].chapterIndex;
      if (target != null && target >= 0 && target <= currentPage) index = i;
    }
    return index;
  }

  void _reveal(int index) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (index * _itemExtent - position.viewportDimension * 0.3)
        .clamp(0.0, position.maxScrollExtent);
    if ((_scrollController.offset - target).abs() > 1) {
      _scrollController.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final threadColors = <Color>[
      appColors.badgeBackground ?? appColors.scheme.primary,
      appColors.scheme.secondary,
      appColors.warning,
      appColors.success,
    ];

    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.outline != curr.outline ||
          prev.bookTitle != curr.bookTitle ||
          prev.author != curr.author ||
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount,
      builder: (context, state) {
        final outline = state.outline;
        final bookTitle = state.bookTitle;
        final author = state.author;
        final hasOutline = outline != null && outline.isNotEmpty;
        final effectiveTab = hasOutline ? _activeTab : TocTab.pages;

        final currentIndex = hasOutline
            ? _indexOfCurrent(outline, state.currentPage)
            : -1;

        final targetIndex = effectiveTab == TocTab.chapters
            ? currentIndex
            : state.currentPage;

        // Keep the current chapter or page in view on initial load or when position changes,
        // without overriding user manual scrolling on unrelated rebuilds.
        if (targetIndex >= 0 && targetIndex != _lastScrolledIndex) {
          _lastScrolledIndex = targetIndex;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _reveal(targetIndex),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              color: appColors.sidebarSectionHeaderBackground,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  AppText(
                    hasOutline ? 'TABLE OF CONTENTS' : 'CHAPTERS',
                    variant: AppTextVariant.label,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: appColors.sidebarSectionHeaderForeground,
                  ),
                  const Spacer(),
                  ?widget.headerAction,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bookTitle != null && bookTitle.isNotEmpty)
                    AppText(
                      bookTitle,
                      variant: AppTextVariant.title,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (author != null && author.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    AppCaption(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  AppCaption(
                    hasOutline
                        ? (_activeTab == TocTab.chapters
                              ? '${outline.where((o) => o.level == 0).length} chapters'
                              : '${state.pageCount} pages')
                        : '${state.pageCount} pages',
                  ),
                ],
              ),
            ),
            if (hasOutline) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: AppSegmentedControl<TocTab>(
                    segments: [
                      const AppSegment(
                        value: TocTab.chapters,
                        label: 'Chapters',
                        icon: LucideIcons.listTree,
                      ),
                      AppSegment(
                        value: TocTab.pages,
                        label: 'All Pages',
                        icon: LucideIcons.bookOpen,
                      ),
                    ],
                    value: _activeTab,
                    onChanged: (tab) {
                      setState(() => _activeTab = tab);
                      _lastScrolledIndex = -1;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final scrollTarget = tab == TocTab.chapters
                            ? currentIndex
                            : state.currentPage;
                        if (scrollTarget >= 0) _reveal(scrollTarget);
                      });
                    },
                  ),
                ),
              ),
            ],
            Divider(
              height: 1,
              thickness: 1,
              color: appColors.sidebarBorder,
            ),
            Expanded(
              child: effectiveTab == TocTab.chapters && hasOutline
                  ? ListView.builder(
                      controller: _scrollController,
                      itemExtent: _itemExtent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: outline.length,
                      itemBuilder: (context, index) {
                        final item = outline[index];
                        final title = item.title;
                        if (title.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final targetPage = item.chapterIndex ?? 0;
                        return OutlineItemTile(
                          item: item,
                          isCurrent: index == currentIndex,
                          threadColors: threadColors,
                          onTap: () => widget.onJumpToPage(targetPage),
                        );
                      },
                    )
                  : state.pageCount == 0
                  ? const AppEmptyView(
                      icon: LucideIcons.fileX,
                      title: 'No pages',
                      message: 'This document has no pages.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemExtent: _itemExtent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: state.pageCount,
                      itemBuilder: (context, index) {
                        return _PageItemTile(
                          pageIndex: index,
                          isCurrent: index == state.currentPage,
                          onTap: () => widget.onJumpToPage(index),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _PageItemTile extends StatelessWidget {
  const _PageItemTile({
    required this.pageIndex,
    required this.isCurrent,
    required this.onTap,
  });

  final int pageIndex;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final pageNumber = pageIndex + 1;

    return Semantics(
      button: true,
      selected: isCurrent,
      label: 'Page $pageNumber',
      child: Material(
        color: isCurrent
            ? appColors.sidebarActiveBackground
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: appColors.sidebarHoverBackground,
          child: Container(
            decoration: isCurrent
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: appColors.badgeBackground ?? appColors.scheme.primary,
                        width: 3.0,
                      ),
                    ),
                  )
                : null,
            padding: EdgeInsets.fromLTRB(isCurrent ? 13 : 16, 8, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.fileText,
                  size: 16,
                  color: isCurrent
                      ? (appColors.badgeBackground ?? appColors.scheme.primary)
                      : appColors.sidebarForeground.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Page $pageNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      color: isCurrent
                          ? appColors.sidebarActiveForeground
                          : appColors.sidebarForeground,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (appColors.badgeBackground ?? appColors.scheme.primary)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'CURRENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: appColors.badgeBackground ?? appColors.scheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
