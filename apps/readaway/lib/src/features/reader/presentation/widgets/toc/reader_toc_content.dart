library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mupdf/mupdf.dart';

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
  static int _indexOfCurrent(
    List<OutlineItem> outline,
    int currentPage, {
    bool isReflowable = false,
  }) {
    var index = -1;
    for (var i = 0; i < outline.length; i++) {
      final target = (isReflowable && outline[i].chapter >= 0)
          ? outline[i].chapter
          : outline[i].page;
      if (target >= 0 && target <= currentPage) index = i;
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
    final scheme = appColors.scheme;
    final threadColors = <Color>[
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
    ];

    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.outline != curr.outline ||
          prev.bookTitle != curr.bookTitle ||
          prev.author != curr.author ||
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount ||
          prev.isReflowable != curr.isReflowable,
      builder: (context, state) {
        final outline = state.outline;
        final bookTitle = state.bookTitle;
        final author = state.author;
        final hasOutline = outline != null && outline.isNotEmpty;
        final effectiveTab = hasOutline ? _activeTab : TocTab.pages;

        final currentIndex = hasOutline
            ? _indexOfCurrent(
                outline,
                state.currentPage,
                isReflowable: state.isReflowable,
              )
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          hasOutline
                              ? 'CONTENTS'
                              : (state.isReflowable ? 'CHAPTERS' : 'PAGES'),
                          variant: AppTextVariant.label,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: 8),
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
                                  : (state.isReflowable ? '${state.pageCount} chapters' : '${state.pageCount} pages'))
                              : (state.isReflowable ? '${state.pageCount} chapters' : '${state.pageCount} pages'),
                        ),
                      ],
                    ),
                  ),
                  ?widget.headerAction,
                ],
              ),
            ),
            if (hasOutline) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                        label: state.isReflowable ? 'All Chapters' : 'Pages',
                        icon: state.isReflowable ? LucideIcons.bookOpen : LucideIcons.files,
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
              color: scheme.outlineVariant,
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
                        if (title == null || title.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final targetPage = (state.isReflowable && item.chapter >= 0)
                            ? item.chapter
                            : item.page;
                        return OutlineItemTile(
                          item: item,
                          isCurrent: index == currentIndex,
                          isReflowable: state.isReflowable,
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
                              isReflowable: state.isReflowable,
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
    required this.isReflowable,
    required this.onTap,
  });

  final int pageIndex;
  final bool isCurrent;
  final bool isReflowable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pageNumber = pageIndex + 1;

    return Semantics(
      button: true,
      selected: isCurrent,
      label: isReflowable ? 'Chapter $pageNumber' : 'Page $pageNumber',
      child: Material(
        color: isCurrent
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? scheme.primary
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isReflowable ? LucideIcons.bookOpen : LucideIcons.image,
                    size: 18,
                    color: isCurrent ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isReflowable ? 'Chapter $pageNumber' : 'Page $pageNumber',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? scheme.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Current',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
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
