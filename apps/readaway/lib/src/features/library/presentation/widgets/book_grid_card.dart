import 'package:flutter/material.dart';

import '../../domain/entity/recent_document.dart';
import 'book_cover_widget.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cover Stack
            Stack(
              children: [
                BookCoverWidget(
                  coverPath: document.coverPath,
                  title: document.displayTitle,
                  author: document.displayAuthor,
                  format: document.format,
                  progressPercent: document.progressPercent,
                  aspectRatio: 2 / 3,
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
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      document.formatBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
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
                            : Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check : Icons.circle_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  )
                else ...[
                  if (document.isFavorite)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    )
                  else if (document.isFinished)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // Book Details
            Text(
              document.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: scheme.onSurface,
              ),
            ),

            if (document.displayAuthor != null) ...[
              const SizedBox(height: 2),
              Text(
                document.displayAuthor!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],

            const SizedBox(height: 4),

            // Progress / Status indicator text
            Row(
              children: [
                if (document.isFinished)
                  Text(
                    'Finished',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade600,
                    ),
                  )
                else if (document.progressPercent > 0)
                  Text(
                    document.progressFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  )
                else
                  Text(
                    'Unread',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.outline,
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
