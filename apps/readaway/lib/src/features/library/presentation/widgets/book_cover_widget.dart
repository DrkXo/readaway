import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BookCoverWidget extends StatelessWidget {
  const BookCoverWidget({
    super.key,
    this.coverPath,
    required this.title,
    this.author,
    required this.format,
    this.aspectRatio = 2 / 3,
    this.progressPercent,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.showSpine = true,
  });

  final String? coverPath;
  final String title;
  final String? author;
  final String format;
  final double aspectRatio;
  final double? progressPercent;
  final BorderRadius borderRadius;
  final bool showSpine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final file = (coverPath != null && coverPath!.isNotEmpty)
        ? File(coverPath!)
        : null;
    final hasImage = file != null && file.existsSync();

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
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
                  color: Colors.black.withValues(alpha: 0.2),
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
      ),
    );
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                LucideIcons.bookOpen,
                size: 16,
                color: scheme.primary.withValues(alpha: 0.75),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  format.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: scheme.onSurface,
            ),
          ),
          if (author != null && author!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              author!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
