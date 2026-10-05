import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import 'book_cover_widget.dart';
import 'book_favorite_badge.dart';

class BookGridCard extends StatelessWidget {
  const BookGridCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onLongPress,
    this.onToggleFavorite,
    this.isSelectMode = false,
    this.isSelected = false,
  });

  final RecentDocument document;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onToggleFavorite;
  final bool isSelectMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final scheme = appColors.scheme;

    final String statusLabel;
    final TextStyle statusStyle;
    if (document.isFinished) {
      statusLabel = 'Finished';
      statusStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: appColors.success,
      );
    } else if (document.readingStatus == ReadingStatus.abandoned) {
      statusLabel = 'On Hold';
      statusStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: appColors.warning,
      );
    } else if (document.progressPercent > 0) {
      statusLabel = document.progressFormatted;
      statusStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: scheme.primary,
      );
    } else {
      statusLabel = 'Unread';
      statusStyle = TextStyle(
        fontSize: 12,
        color: scheme.outline,
      );
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Stack
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BookCoverWidget(
                    coverPath: document.coverPath,
                    title: document.displayTitle,
                    author: document.displayAuthor,
                    format: document.format,
                    progressPercent: document.progressPercent,
                  ),

                  // Format badge overlay (top-left)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.inverseSurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        document.formatBadge,
                        style: TextStyle(
                          color: scheme.onInverseSurface,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),

                  // Top-right status / select indicator
                  if (isSelectMode)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primary
                              : scheme.inverseSurface.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? LucideIcons.check : LucideIcons.circle,
                          size: 14,
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onInverseSurface,
                        ),
                      ),
                    )
                  else if (onToggleFavorite != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: BookFavoriteBadge(
                        isFavorite: document.isFavorite,
                        onToggleFavorite: onToggleFavorite!,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Book Details
            Text(
              document.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: scheme.onSurface,
              ),
            ),

            if (document.displayAuthor != null) ...[
              const SizedBox(height: 3),
              Text(
                document.displayAuthor!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],

            const SizedBox(height: 6),

            // Progress / Status indicator text
            Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: statusStyle,
                  ),
                ),
                if (document.formattedFileSize.isNotEmpty) ...[
                  Text(
                    ' · ',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.outlineVariant,
                    ),
                  ),
                  Text(
                    document.formattedFileSize,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
