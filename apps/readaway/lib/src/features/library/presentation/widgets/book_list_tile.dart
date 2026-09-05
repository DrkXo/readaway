import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entity/recent_document.dart';
import 'book_cover_widget.dart';

class BookListTile extends StatelessWidget {
  const BookListTile({
    super.key,
    required this.document,
    required this.onTap,
    required this.onLongPress,
    this.onToggleFavorite,
    this.onOpenDetails,
    this.isSelectMode = false,
    this.isSelected = false,
  });

  final RecentDocument document;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onOpenDetails;
  final bool isSelectMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final progressText = document.isFinished
        ? 'Finished'
        : document.pageCount > 0
            ? 'Page ${document.lastReadPage + 1} of ${document.pageCount} (${document.progressFormatted})'
            : document.readingStatus.label;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cover thumbnail
            SizedBox(
              width: 52,
              height: 78,
              child: BookCoverWidget(
                coverPath: document.coverPath,
                title: document.displayTitle,
                author: document.displayAuthor,
                format: document.format,
                progressPercent: document.progressPercent,
              ),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    document.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Format pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          document.formatBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Progress text
                      Expanded(
                        child: Text(
                          progressText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: document.isFinished
                                ? Colors.green.shade600
                                : scheme.onSurfaceVariant,
                            fontWeight: document.isFinished
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (document.formattedFileSize.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          document.formattedFileSize,
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (document.progressPercent > 0 && !document.isFinished) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: document.progressPercent,
                        minHeight: 3,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scheme.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Trailing actions or selection checkbox
            if (isSelectMode)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? null
                      : Border.all(color: scheme.outline, width: 1.5),
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.circle,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              )
            else ...[
              if (onToggleFavorite != null)
                IconButton(
                  icon: Icon(
                    document.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 20,
                    color: document.isFavorite ? Colors.amber : scheme.outline,
                  ),
                  tooltip: document.isFavorite
                      ? 'Remove from favorites'
                      : 'Mark as favorite',
                  onPressed: onToggleFavorite,
                ),
              if (onOpenDetails != null)
                IconButton(
                  icon: const Icon(LucideIcons.ellipsisVertical, size: 18),
                  tooltip: 'Book details & actions',
                  onPressed: onOpenDetails,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
