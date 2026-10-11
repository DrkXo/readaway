import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/metro/metro.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import 'book_cover_widget.dart';
import 'book_favorite_badge.dart';

/// A flat Metro-style book card with authentic 3D perspective tilt.
///
/// Features:
/// - Zero elevation, zero shadows, zero border radius ([BorderRadius.zero]).
/// - Integrated [MetroPressable] 3D matrix tilt on touch.
/// - Flat format badge overlay, favorite toggle, and selection state.
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

    final String statusLabel;
    final Color statusColor;
    if (document.isFinished) {
      statusLabel = 'Finished';
      statusColor = appColors.buttonBackground;
    } else if (document.readingStatus == ReadingStatus.abandoned) {
      statusLabel = 'On Hold';
      statusColor = appColors.readerForeground.withValues(alpha: 0.5);
    } else if (document.progressPercent > 0) {
      statusLabel = document.progressFormatted;
      statusColor = appColors.buttonBackground;
    } else {
      statusLabel = 'Unread';
      statusColor = appColors.readerForeground.withValues(alpha: 0.5);
    }

    return MetroPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: isSelected
            ? appColors.buttonBackground.withValues(alpha: 0.12)
            : Colors.transparent,
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cover Stack with overlays
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
                    borderRadius: BorderRadius.zero,
                  ),

                  // Flat format badge overlay (top-left)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      color: appColors.readerBackground.withValues(alpha: 0.88),
                      child: Text(
                        document.formatBadge,
                        style: TextStyle(
                          color: appColors.readerForeground,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                  // Selection mode indicator or favorite badge (top-right)
                  if (isSelectMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        color: isSelected
                            ? appColors.buttonBackground
                            : appColors.readerBackground.withValues(
                                alpha: 0.75,
                              ),
                        child: Center(
                          child: Icon(
                            isSelected ? LucideIcons.check : LucideIcons.square,
                            size: 14,
                            color: isSelected
                                ? appColors.buttonForeground
                                : appColors.readerForeground.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
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

            const SizedBox(height: 6),

            // 2. Book Title
            Text(
              document.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: appColors.readerForeground,
              ),
            ),

            if (document.displayAuthor != null) ...[
              const SizedBox(height: 2),
              Text(
                document.displayAuthor!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: appColors.readerForeground.withValues(alpha: 0.65),
                ),
              ),
            ],

            const SizedBox(height: 4),

            // 3. Status and Size Row
            Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                if (document.formattedFileSize.isNotEmpty) ...[
                  Text(
                    ' · ',
                    style: TextStyle(
                      fontSize: 10,
                      color: appColors.readerForeground.withValues(alpha: 0.35),
                    ),
                  ),
                  Text(
                    document.formattedFileSize,
                    style: TextStyle(
                      fontSize: 10,
                      color: appColors.readerForeground.withValues(alpha: 0.55),
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
