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
    final scheme = appColors.scheme;

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
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: scheme.inverseSurface.withValues(
                  alpha: isFavorite ? 0.85 : 0.6,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.star,
                size: 13,
                color: isFavorite ? appColors.warning : scheme.onInverseSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
