library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mupdf/mupdf.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import 'outline_item_tile.dart';

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
                        AppText(
                          'CONTENTS',
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
                          outline == null || outline.isEmpty
                              ? 'Table of contents'
                              : '${outline.where((o) => o.level == 0).length} chapters',
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
                  ? const AppEmptyView(
                      icon: LucideIcons.listTree,
                      title: 'No table of contents',
                      message: 'This document does not expose an outline.',
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
                        return OutlineItemTile(
                          item: item,
                          isCurrent: index == currentIndex,
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
