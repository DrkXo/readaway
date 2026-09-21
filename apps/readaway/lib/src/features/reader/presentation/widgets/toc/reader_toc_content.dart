library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import 'outline_item_tile.dart';

/// Shared table-of-contents UI used by the mobile drawer and the
/// desktop side panel.
///
/// Renders the outline as a collapsible tree: parent entries (that have
/// children, e.g. volume → chapter) toggle expand/collapse on tap and can be
/// drilled into; leaf entries navigate to their chapter. The ancestors of the
/// chapter covering the current page are always expanded so the reading spot
/// stays visible.
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
  /// Fixed row height so the scroll offset for any visible outline index is
  /// computable without building the item (ListView is lazy).
  static const double _itemExtent = 56;

  final _scrollController = ScrollController();
  int _lastScrolledIndex = -1;

  /// Outlines parents that the user has expanded. Parents on the path of the
  /// current chapter are force-expanded (see [_ensureCurrentVisible]).
  final Set<_TocNodeRef> _expanded = {};

  List<OutlineItem>? _outlineForIndex;
  int _currentPageForIndex = -1;
  (OutlineItem, List<OutlineItem>)? _cachedCurrent;

  OutlineItem? _currentItemForRows;
  int _cachedCurrentRow = -1;

  /// Node covering [currentPage] with its ancestor chain (root first).
  /// Memoized on (outline, currentPage); outline is shared across rebuilds.
  (OutlineItem, List<OutlineItem>)? _currentNode(
    List<OutlineItem> outline,
    int currentPage,
  ) {
    if (!identical(_outlineForIndex, outline) ||
        _currentPageForIndex != currentPage) {
      _outlineForIndex = outline;
      _currentPageForIndex = currentPage;
      _cachedCurrent = tocCurrentPath(outline, currentPage);
    }
    return _cachedCurrent;
  }

  /// Index of [item] among the visible rows, -1 if hidden behind a collapsed
  /// parent. Memoized on the target item.
  int _rowIndexOf(OutlineItem? item, List<OutlineItem> rows) {
    if (item == null) return -1;
    if (!identical(_currentItemForRows, item)) {
      _currentItemForRows = item;
      _cachedCurrentRow = rows.indexWhere((r) => identical(r, item));
    }
    return _cachedCurrentRow;
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

  List<OutlineItem>? _outlineForCount;
  int _cachedChapterCount = 0;

  int _chapterCount(List<OutlineItem> outline) {
    if (!identical(_outlineForCount, outline)) {
      _outlineForCount = outline;
      var count = 0;
      void walk(List<OutlineItem> items) {
        for (final item in items) {
          if (item.chapterIndex != null) count++;
          if (item.children.isNotEmpty) walk(item.children);
        }
      }

      walk(outline);
      _cachedChapterCount = count;
    }
    return _cachedChapterCount;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.outline != curr.outline ||
          prev.bookTitle != curr.bookTitle ||
          prev.author != curr.author ||
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount,
      builder: (context, state) {
        final outline = state.outline ?? const [];
        final hasOutline = outline.isNotEmpty;
        final bookTitle = state.bookTitle;
        final author = state.author;

        final current = hasOutline
            ? _currentNode(outline, state.currentPage)
            : null;

        // The current chapter stays reachable even under collapsed parents,
        // so force its ancestor chain open.
        if (current != null) {
          for (final node in current.$2) {
            _expanded.add(_TocNodeRef(node));
          }
        }

        final rows = hasOutline
            ? tocVisibleRows(
                outline,
                (item) => _expanded.contains(_TocNodeRef(item)),
              )
            : const <OutlineItem>[];
        final scrollIndex = _rowIndexOf(current?.$1, rows);

        // Keep the current chapter in view on initial load or when position
        // changes, without overriding user manual scrolling on unrelated
        // rebuilds.
        if (scrollIndex >= 0 && scrollIndex != _lastScrolledIndex) {
          _lastScrolledIndex = scrollIndex;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _reveal(scrollIndex),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.bookOpen,
                    size: 14,
                    color: appColors.sidebarForeground.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 9),
                  AppText(
                    'CONTENTS',
                    variant: AppTextVariant.label,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                    color: appColors.sidebarSectionHeaderForeground,
                  ),
                  const Spacer(),
                  ?widget.headerAction,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (bookTitle != null && bookTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        bookTitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: tocSerifFont,
                          fontSize: 19,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: appColors.sidebarTitleForeground,
                        ),
                      ),
                    ),
                  if (author != null && author.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      author,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: tocSerifFont,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        height: 1.25,
                        color: appColors.sidebarForeground.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                  ],
                  if (hasOutline) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: appColors.sidebarBorder.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: AppText(
                            '${_chapterCount(outline)} chapters',
                            variant: AppTextVariant.label,
                            letterSpacing: 1.6,
                            fontSize: 10,
                            color: appColors.sidebarForeground.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: appColors.sidebarBorder.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: appColors.sidebarBorder,
            ),
            Expanded(
              child: !hasOutline
                  ? const AppEmptyView(
                      icon: LucideIcons.bookOpen,
                      title: 'No contents',
                      message: 'This document has no table of contents.',
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemExtent: _itemExtent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final item = rows[index];
                        final title = item.title;
                        if (title.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final hasChildren = item.children.isNotEmpty;
                        final isCurrent =
                            current != null && identical(item, current.$1);
                        return OutlineItemTile(
                          item: item,
                          isCurrent: isCurrent,
                          isExpanded: _expanded.contains(_TocNodeRef(item)),
                          onTap: () {
                            if (hasChildren) {
                              setState(() {
                                final ref = _TocNodeRef(item);
                                if (!_expanded.remove(ref)) {
                                  _expanded.add(ref);
                                }
                              });
                            } else {
                              widget.onJumpToPage(item.chapterIndex ?? 0);
                            }
                          },
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

/// Identity-based key for a tree node, so sibling volumes with equal titles or
/// repeated hrefs never collide.
class _TocNodeRef {
  final OutlineItem item;

  _TocNodeRef(this.item);

  @override
  bool operator ==(Object other) =>
      other is _TocNodeRef && identical(item, other.item);

  @override
  int get hashCode => identityHashCode(item);
}

/// Depth-first list of outline nodes to display, skipping the children of any
/// parent for which [isExpanded] returns false.
List<OutlineItem> tocVisibleRows(
  List<OutlineItem> outline,
  bool Function(OutlineItem) isExpanded,
) {
  final rows = <OutlineItem>[];
  void walk(List<OutlineItem> items) {
    for (final item in items) {
      rows.add(item);
      if (item.children.isNotEmpty && isExpanded(item)) {
        walk(item.children);
      }
    }
  }

  walk(outline);
  return rows;
}

/// Last node (depth-first) whose [OutlineItem.chapterIndex] is within
/// [currentPage], together with its ancestor chain from a root down to the
/// node itself; null when nothing navigable covers the page.
(OutlineItem, List<OutlineItem>)? tocCurrentPath(
  List<OutlineItem> outline,
  int currentPage,
) {
  OutlineItem? best;
  List<OutlineItem>? bestPath;
  var bestTarget = -1;
  void walk(List<OutlineItem> items, List<OutlineItem> path) {
    for (final item in items) {
      final itemPath = [...path, item];
      final target = item.chapterIndex ?? -1;
      final isBetter =
          target > bestTarget ||
          (best != null && target == bestTarget && itemPath.length > bestPath!.length);
      if (target >= 0 && target <= currentPage && isBetter) {
        best = item;
        bestPath = itemPath;
        bestTarget = target;
      }
      if (item.children.isNotEmpty) walk(item.children, itemPath);
    }
  }

  walk(outline, const []);
  return best != null ? (best!, bestPath!) : null;
}