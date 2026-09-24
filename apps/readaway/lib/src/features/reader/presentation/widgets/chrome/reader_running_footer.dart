import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../settings/domain/entity/reader_preferences.dart';
import 'reader_status_widget.dart';

/// Persistent bottom footer (Running Footer) displaying reading progress, remaining pages, and status.
class ReaderRunningFooter extends StatelessWidget {
  const ReaderRunningFooter({
    super.key,
    required this.pageInChapter,
    required this.totalPagesInChapter,
    required this.globalPageIndex,
    required this.totalGlobalPages,
    this.progressStyle = ReaderProgressStyle.pageNumber,
    this.showRemainingPages = true,
    this.showCurrentTime = false,
    this.showBatteryStatus = false,
    this.showProgressBar = false,
    this.fontSize = 11.0,
    this.height = 24.0,
    this.horizontalPadding = 16.0,
    this.color,
  });

  final int pageInChapter;
  final int totalPagesInChapter;
  final int globalPageIndex;
  final int totalGlobalPages;
  final ReaderProgressStyle progressStyle;
  final bool showRemainingPages;
  final bool showCurrentTime;
  final bool showBatteryStatus;
  final bool showProgressBar;
  final double fontSize;
  final double height;
  final double horizontalPadding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? context.appColors.readerForeground.withValues(alpha: 0.55);

    final textStyle = TextStyle(
      fontSize: fontSize,
      color: resolvedColor,
      fontWeight: FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // Left zone: remaining pages in chapter
    String remainingText = '';
    if (showRemainingPages && totalPagesInChapter > 0) {
      final remaining = math.max(0, totalPagesInChapter - 1 - pageInChapter);
      if (remaining == 0) {
        remainingText = 'Last page in chapter';
      } else if (remaining == 1) {
        remainingText = '1 page left';
      } else {
        remainingText = '$remaining pages left';
      }
    }

    // Right zone: page count or percentage
    String progressText = '';
    if (progressStyle == ReaderProgressStyle.pageNumber) {
      final current = globalPageIndex + 1;
      final total = math.max(1, totalGlobalPages);
      progressText = '$current / $total';
    } else if (progressStyle == ReaderProgressStyle.percentage) {
      final fraction = (globalPageIndex + 1) / math.max(1, totalGlobalPages);
      final percent = (fraction * 100).clamp(0, 100).round();
      progressText = '$percent%';
    }

    final hasStatus = showCurrentTime || showBatteryStatus;
    final progressFraction = totalGlobalPages > 0
        ? ((globalPageIndex + 1) / totalGlobalPages).clamp(0.0, 1.0)
        : 0.0;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left zone: Remaining Pages
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: remainingText.isNotEmpty
                        ? Text(
                            remainingText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                // Center zone: Status Info (Clock, Battery)
                if (hasStatus)
                  ReaderStatusWidget(
                    showTime: showCurrentTime,
                    showBattery: showBatteryStatus,
                    fontSize: fontSize,
                    color: resolvedColor,
                  ),

                // Right zone: Progress / Page Count
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: progressText.isNotEmpty
                        ? Text(
                            progressText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),

          // Optional slim progress line at the very bottom
          if (showProgressBar)
            Positioned(
              bottom: 0,
              left: horizontalPadding,
              right: horizontalPadding,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.0),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 1.5,
                  backgroundColor: resolvedColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    resolvedColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
