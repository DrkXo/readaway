import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entity/reading_status.dart';
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
    final appColors = context.appColors;
    final scheme = appColors.scheme;

    final progressText = document.isFinished
        ? 'Finished'
        : document.readingStatus == ReadingStatus.abandoned
        ? 'On Hold'
        : document.readingStatus == ReadingStatus.unread
        ? 'Unread'
        : document.pageCount > 0
        ? 'Page ${document.lastReadPage + 1} of ${document.pageCount} (${document.progressFormatted})'
        : document.readingStatus.label;

    return Material(
      color: isSelected
          ? appColors.listActiveSelectionBackground
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        hoverColor: appColors.listHoverBackground,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color:
                          appColors.badgeBackground ?? appColors.scheme.primary,
                      width: 3.5,
                    ),
                  ),
                )
              : null,
          padding: EdgeInsets.fromLTRB(isSelected ? 13 : 16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Cover thumbnail (modern reader standard 64x96)
              SizedBox(
                width: 64,
                height: 96,
                child: BookCoverWidget(
                  coverPath: document.coverPath,
                  title: document.displayTitle,
                  author: document.displayAuthor,
                  format: document.format,
                  progressPercent: document.progressPercent,
                ),
              ),

              const SizedBox(width: 16),

              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
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
                          fontSize: 13,
                          height: 1.2,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Format pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            document.formatBadge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Progress / Status text
                        Expanded(
                          child: Text(
                            progressText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: document.isFinished
                                  ? appColors.success
                                  : document.readingStatus ==
                                        ReadingStatus.abandoned
                                  ? appColors.warning
                                  : scheme.onSurfaceVariant,
                              fontWeight:
                                  document.isFinished ||
                                      document.readingStatus ==
                                          ReadingStatus.reading
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (document.formattedFileSize.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            document.formattedFileSize,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (document.progressPercent > 0 &&
                        !document.isFinished) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: document.progressPercent,
                          minHeight: 3.5,
                          backgroundColor: scheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Trailing actions or selection checkbox
              if (isSelectMode)
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(color: scheme.outline, width: 1.5),
                  ),
                  child: isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: 14,
                          color: scheme.onPrimary,
                        )
                      : null,
                )
              else ...[
                if (onToggleFavorite != null)
                  IconButton(
                    icon: Icon(
                      LucideIcons.star,
                      size: 19,
                      color: document.isFavorite
                          ? appColors.warning
                          : scheme.outline,
                    ),
                    tooltip: document.isFavorite
                        ? 'Remove from favorites'
                        : 'Mark as favorite',
                    onPressed: onToggleFavorite,
                  ),
                if (onOpenDetails != null)
                  IconButton(
                    icon: const Icon(LucideIcons.ellipsisVertical, size: 19),
                    tooltip: 'Book details & actions',
                    onPressed: onOpenDetails,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
