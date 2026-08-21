import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mupdf/mupdf.dart';

import '../../../../core/theme/theme.dart';
import '../bloc/reader_bloc.dart';

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

  /// Index of the outline item covering [currentPage], -1 if none.
  static int _indexOfCurrent(List<OutlineItem> outline, int currentPage) {
    var index = -1;
    for (var i = 0; i < outline.length; i++) {
      final page = outline[i].page;
      if (page >= 0 && page <= currentPage) index = i;
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
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final scheme = appColors.scheme;
    final threadColors = <Color>[
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
    ];

    return BlocBuilder<ReaderBloc, ReaderState>(
      builder: (context, state) {
        final outline = state.outline;
        final bookTitle = state.bookTitle;
        final author = state.author;
        final currentIndex = outline == null || outline.isEmpty
            ? -1
            : _indexOfCurrent(outline, state.currentPage);

        // Keep the current chapter in view so it is visible whenever the
        // TOC is opened (drawer, peek or pinned panel).
        if (currentIndex >= 0) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _reveal(currentIndex),
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
                        Text(
                          'CONTENTS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (bookTitle != null && bookTitle.isNotEmpty)
                          Text(
                            bookTitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (author != null && author.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            author,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          outline == null || outline.isEmpty
                              ? 'Table of contents'
                              : '${outline.where((o) => o.level == 0).length} chapters',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?widget.headerAction,
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant,
            ),
            Expanded(
              child: outline == null || outline.isEmpty
                  ? Center(
                      child: Text(
                        'No table of contents',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
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
                        return _OutlineItemTile(
                          item: item,
                          isCurrent: index == currentIndex,
                          theme: theme,
                          threadColors: threadColors,
                          onTap: () => widget.onJumpToPage(item.page),
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

class _OutlineItemTile extends StatelessWidget {
  const _OutlineItemTile({
    required this.item,
    required this.isCurrent,
    required this.theme,
    required this.threadColors,
    required this.onTap,
  });

  final OutlineItem item;
  final bool isCurrent;
  final ThemeData theme;
  final List<Color> threadColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.title;
    if (title == null || title.isEmpty) return const SizedBox.shrink();

    final color = threadColors[item.level % threadColors.length];
    final isTopLevel = item.level == 0;

    return Material(
      color: isCurrent
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 20),
              for (var l = 0; l < item.level; l++)
                Container(
                  width: 2,
                  margin: const EdgeInsets.only(right: 10),
                  color: threadColors[l % threadColors.length].withValues(
                    alpha: 0.35,
                  ),
                ),
              if (isTopLevel)
                Container(
                  margin: const EdgeInsets.only(top: 4, right: 12),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (isTopLevel
                                ? theme.textTheme.bodyMedium
                                : theme.textTheme.bodySmall)
                            ?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : isTopLevel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : isTopLevel
                                  ? theme.textTheme.bodyMedium?.color
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
