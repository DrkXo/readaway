import 'package:flutter/material.dart';
import 'package:readaway_core/readaway_core.dart';
import '../../../../../core/theme/theme.dart';

class OutlineItemTile extends StatelessWidget {
  const OutlineItemTile({
    super.key,
    required this.item,
    required this.isCurrent,
    required this.threadColors,
    required this.onTap,
  });

  final OutlineItem item;
  final bool isCurrent;
  final List<Color> threadColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.title;
    if (title.isEmpty) return const SizedBox.shrink();

    final appColors = context.appColors;
    final color = threadColors[item.level % threadColors.length];
    final isTopLevel = item.level == 0;

    return Semantics(
      button: true,
      selected: isCurrent,
      label: item.chapterIndex != null
          ? '$title, Chapter ${item.chapterIndex! + 1}'
          : title,
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
            padding: EdgeInsets.fromLTRB(isCurrent ? 13 : 16, 6, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var l = 0; l < item.level; l++)
                  Container(
                    width: 1.5,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    color: appColors.borderSubtle,
                  ),
                if (isTopLevel)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isTopLevel ? 13 : 12,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : isTopLevel
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: isCurrent
                          ? appColors.sidebarActiveForeground
                          : isTopLevel
                          ? appColors.sidebarForeground
                          : appColors.sidebarForeground.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
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
                      'Current',
                      style: TextStyle(
                        fontSize: 9,
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
