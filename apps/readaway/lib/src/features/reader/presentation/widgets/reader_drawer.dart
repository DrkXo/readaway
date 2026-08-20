import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mupdf/mupdf.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/reader_bloc.dart';
import 'reader_overlay_controller.dart';

class ReaderDrawer extends StatelessWidget {
  const ReaderDrawer({
    super.key,
    required this.controller,
    required this.onJumpToPage,
  });

  final ReaderOverlayController controller;
  final void Function(int page) onJumpToPage;

  static const List<Color> _threadColors = [
    Color(0xFFFF4500),
    Color(0xFF0079D3),
    Color(0xFF46D160),
    Color(0xFFFFB000),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0B1416)
        : const Color(0xFFFAFAFA);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(-1, 0),
          end: Offset.zero,
          duration: 200.ms,
          curve: Curves.easeOut,
        ),
      ],
      child: Drawer(
        backgroundColor: background,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: context.appColors.shadowLg,
          ),
          child: SafeArea(
            child: BlocBuilder<ReaderBloc, ReaderState>(
              builder: (context, state) {
                final outline = state.outline;
                final bookTitle = state.bookTitle;
                final author = state.author;

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
                                    color: _threadColors[0],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (bookTitle != null && bookTitle.isNotEmpty)
                                  Text(
                                    bookTitle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (author != null && author.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      author,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.hintColor,
                                          ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  outline == null || outline.isEmpty
                                      ? 'Table of contents'
                                      : '${outline.where((o) => o.level == 0).length} chapters',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            splashRadius: 20,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: dividerColor),
                    Expanded(
                      child: outline == null || outline.isEmpty
                          ? Center(
                              child: Text(
                                'No table of contents',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            )
                          : ListView.builder(
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
                                  theme: theme,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    onJumpToPage(item.page);
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineItemTile extends StatelessWidget {
  const _OutlineItemTile({
    required this.item,
    required this.theme,
    required this.onTap,
  });

  final OutlineItem item;
  final ThemeData theme;
  final VoidCallback onTap;

  static const List<Color> _threadColors = [
    Color(0xFFFF4500),
    Color(0xFF0079D3),
    Color(0xFF46D160),
    Color(0xFFFFB000),
  ];

  @override
  Widget build(BuildContext context) {
    final title = item.title;
    if (title == null || title.isEmpty) return const SizedBox.shrink();

    final color = _threadColors[item.level % _threadColors.length];
    final isTopLevel = item.level == 0;

    return Material(
      color: Colors.transparent,
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
                  color: _threadColors[l % _threadColors.length].withValues(
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
                              fontWeight: isTopLevel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isTopLevel
                                  ? theme.textTheme.bodyMedium?.color
                                  : theme.hintColor,
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
