part of '../reader_widgets.dart';

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
