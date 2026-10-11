import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';

/// A small, always-tappable favorite star used as a corner overlay on book
/// covers. The visible badge is intentionally small to stay out of the way,
/// while the tap target is expanded to 44x44 for accessibility.
class BookFavoriteBadge extends StatelessWidget {
  const BookFavoriteBadge({
    super.key,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Tooltip(
      message: isFavorite ? 'Remove from favorites' : 'Mark as favorite',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggleFavorite,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              color: isFavorite
                  ? appColors.buttonBackground
                  : appColors.readerBackground.withValues(alpha: 0.8),
              child: Center(
                child: Icon(
                  LucideIcons.star,
                  size: 13,
                  color: isFavorite
                      ? appColors.buttonForeground
                      : appColors.readerForeground.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
