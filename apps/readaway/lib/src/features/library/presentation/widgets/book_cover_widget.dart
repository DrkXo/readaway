import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';

class BookCoverWidget extends StatelessWidget {
  const BookCoverWidget({
    super.key,
    this.coverPath,
    required this.title,
    this.author,
    required this.format,
    this.aspectRatio,
    this.progressPercent,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.showSpine = true,
  });

  final String? coverPath;
  final String title;
  final String? author;
  final String format;
  final double? aspectRatio;
  final double? progressPercent;
  final BorderRadius borderRadius;
  final bool showSpine;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final scheme = appColors.scheme;
    final file = (coverPath != null && coverPath!.isNotEmpty)
        ? File(coverPath!)
        : null;
    final hasImage = file != null && file.existsSync();

    final coverBox = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: appColors.borderSubtle,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _FallbackCover(
                  title: title,
                  author: author,
                  format: format,
                ),
              )
            else
              _FallbackCover(
                title: title,
                author: author,
                format: format,
              ),

            // Subtle book spine overlay on left edge
            if (showSpine)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Progress bar along the bottom edge
            if (progressPercent != null && progressPercent! > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 3.5,
                child: Container(
                  color: scheme.surfaceContainerHighest,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercent!.clamp(0.0, 1.0),
                    child: Container(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

    if (aspectRatio != null) {
      return AspectRatio(
        aspectRatio: aspectRatio!,
        child: coverBox,
      );
    }

    return coverBox;
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({
    required this.title,
    this.author,
    required this.format,
  });

  final String title;
  final String? author;
  final String format;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth < 65 || constraints.maxHeight < 95;
        final hasAuthor = author != null && author!.trim().isNotEmpty;

        return Container(
          padding: EdgeInsets.all(isCompact ? 6 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surfaceContainerHigh,
                scheme.surfaceContainerHighest,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: isCompact
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (!isCompact)
                    Icon(
                      LucideIcons.bookOpen,
                      size: 14,
                      color: scheme.primary.withValues(alpha: 0.75),
                    ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 4 : 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      format.toUpperCase(),
                      style: TextStyle(
                        fontSize: isCompact ? 7.5 : 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: isCompact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (!isCompact && hasAuthor) ...[
                      const SizedBox(height: 3),
                      Text(
                        author!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
