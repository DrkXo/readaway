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
    final hasAuthor = author != null && author!.trim().isNotEmpty;

    // Centered placeholder with no corner content, so it never collides with
    // the format / favorite overlays drawn by the parent cards.
    return Container(
      padding: const EdgeInsets.all(10),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.bookOpen,
            size: 16,
            color: scheme.primary.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (hasAuthor) ...[
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
    );
  }
}
