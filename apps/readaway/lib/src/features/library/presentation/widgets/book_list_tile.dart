import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import 'book_cover_widget.dart';

/// Flat Metro-style book row with authentic 3D perspective tilt on touch.
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

  /// Cover width for a row rendered at [width] logical pixels.
  static double coverWidthFor(double width) {
    return breakpointFromWidth(width).resolve(
      compact: 68.0,
      medium: 72.0,
      expanded: 76.0,
      wide: 80.0,
    );
  }

  /// Horizontal gap between the cover and the content block.
  static double contentGapFor(double width) {
    return breakpointFromWidth(width) == AppBreakpoint.compact ? 12.0 : 16.0;
  }

  /// Distance from the tile's left edge to the title text.
  static double contentIndentFor(double width) {
    return 16.0 + coverWidthFor(width) + contentGapFor(width);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    final progressText = document.isFinished
        ? 'Finished'
        : document.readingStatus == ReadingStatus.abandoned
        ? 'On Hold'
        : document.readingStatus == ReadingStatus.unread
        ? 'Unread'
        : document.pageCount > 0
        ? 'Page ${document.lastReadPage + 1} of ${document.pageCount} (${document.progressFormatted})'
        : document.readingStatus.label;

    return MetroPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compact = breakpointFromWidth(width) == AppBreakpoint.compact;
          final coverWidth = BookListTile.coverWidthFor(width);
          final coverHeight = coverWidth * 1.5;
          const actionSize = 44.0;

          return Container(
            color: isSelected
                ? appColors.buttonBackground.withValues(alpha: 0.12)
                : Colors.transparent,
            decoration: isSelected
                ? BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: appColors.buttonBackground,
                        width: 4.0,
                      ),
                    ),
                  )
                : null,
            padding: EdgeInsets.fromLTRB(isSelected ? 12 : 16, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Flat Book Cover
                SizedBox(
                  width: coverWidth,
                  height: coverHeight,
                  child: BookCoverWidget(
                    coverPath: document.coverPath,
                    title: document.displayTitle,
                    author: document.displayAuthor,
                    format: document.format,
                    progressPercent: document.progressPercent,
                    borderRadius: BorderRadius.zero,
                  ),
                ),

                SizedBox(width: contentGapFor(width)),

                // 2. Content Details
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
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: appColors.readerForeground,
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
                            color: appColors.readerForeground.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Flat format tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            color: appColors.readerForeground.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              document.formatBadge,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: appColors.readerForeground,
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
                                fontSize: 12.5,
                                color: document.isFinished
                                    ? appColors.success
                                    : document.readingStatus ==
                                          ReadingStatus.abandoned
                                    ? appColors.warning
                                    : appColors.readerForeground.withValues(
                                        alpha: 0.7,
                                      ),
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
                                color: appColors.readerForeground.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (document.progressPercent > 0 &&
                          !document.isFinished) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: document.progressPercent,
                          minHeight: 3.0,
                          backgroundColor: appColors.readerForeground
                              .withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            appColors.buttonBackground,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: compact ? 2 : 8),

                // 3. Selection or Action controls
                if (isSelectMode)
                  Container(
                    width: 24,
                    height: 24,
                    color: isSelected
                        ? appColors.buttonBackground
                        : appColors.readerForeground.withValues(alpha: 0.12),
                    child: Center(
                      child: isSelected
                          ? Icon(
                              LucideIcons.check,
                              size: 15,
                              color: appColors.buttonForeground,
                            )
                          : null,
                    ),
                  )
                else ...[
                  if (!compact && onToggleFavorite != null)
                    IconButton(
                      constraints: BoxConstraints.tightFor(
                        width: actionSize,
                        height: actionSize,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        LucideIcons.star,
                        size: 19,
                        color: document.isFavorite
                            ? appColors.warning
                            : appColors.readerForeground.withValues(
                                alpha: 0.35,
                              ),
                      ),
                      tooltip: document.isFavorite
                          ? 'Remove from favorites'
                          : 'Mark as favorite',
                      onPressed: onToggleFavorite,
                    ),
                  if (onOpenDetails != null)
                    IconButton(
                      constraints: BoxConstraints.tightFor(
                        width: actionSize,
                        height: actionSize,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        LucideIcons.ellipsisVertical,
                        size: 19,
                        color: appColors.readerForeground.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      tooltip: 'Book details & actions',
                      onPressed: onOpenDetails,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
