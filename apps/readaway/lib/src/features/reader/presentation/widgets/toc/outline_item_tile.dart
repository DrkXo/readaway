import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../core/theme/theme.dart';

/// The classic serif used for reading text, so the contents list reads like
/// the book it belongs to.
const String tocSerifFont = 'Noto Serif';

class OutlineItemTile extends StatelessWidget {
  const OutlineItemTile({
    super.key,
    required this.item,
    required this.isCurrent,
    required this.onTap,
    this.isExpanded = false,
  });

  final OutlineItem item;
  final bool isCurrent;
  final VoidCallback onTap;

  /// Whether this node has children, i.e. tapping toggles instead of jumping.
  bool get _hasChildren => item.children.isNotEmpty;

  /// Whether the row's children are currently shown.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final title = item.title;
    if (title.isEmpty) return const SizedBox.shrink();

    final appColors = context.appColors;
    final accent = appColors.badgeBackground ?? appColors.scheme.primary;
    final isTopLevel = item.level == 0;
    final fg = isCurrent
        ? appColors.sidebarActiveForeground
        : appColors.sidebarForeground;

    return Semantics(
      button: true,
      toggled: _hasChildren ? isExpanded : null,
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
                      left: BorderSide(color: accent, width: 3.0),
                    ),
                  )
                : null,
            padding: EdgeInsets.fromLTRB(isCurrent ? 17 : 20, 6, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Indentation only — depth is shown by spacing, not bars.
                SizedBox(width: item.level * 16.0),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: tocSerifFont,
                      fontSize: isTopLevel ? 14 : 13,
                      height: 1.3,
                      fontWeight: isCurrent
                          ? FontWeight.w600
                          : isTopLevel
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: isCurrent
                          ? fg
                          : isTopLevel
                          ? fg
                          : fg.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                if (_hasChildren) ...[
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 15,
                      color: fg.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
