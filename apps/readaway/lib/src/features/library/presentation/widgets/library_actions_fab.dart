import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';

class LibraryActionsFab extends StatelessWidget {
  const LibraryActionsFab({
    super.key,
    required this.isLoading,
    required this.isExpanded,
    required this.onToggle,
    required this.onAddBooks,
    required this.onOpenBook,
  });

  final bool isLoading;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onAddBooks;
  final VoidCallback onOpenBook;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ActionItem(
          key: const ValueKey('library-open-book'),
          label: 'Open',
          icon: LucideIcons.bookOpen,
          isVisible: isExpanded && !isLoading,
          onPressed: onOpenBook,
        ),
        if (isExpanded && !isLoading) const SizedBox(height: 8),
        _ActionItem(
          key: const ValueKey('library-add-books'),
          label: isLoading ? 'Adding…' : 'Add',
          icon: isLoading ? null : LucideIcons.bookPlus,
          isLoading: isLoading,
          isVisible: isExpanded || isLoading,
          onPressed: onAddBooks,
        ),
        if (isExpanded || isLoading) const SizedBox(height: 8),
        FloatingActionButton.small(
          key: const ValueKey('library-actions-toggle'),
          heroTag: 'library-actions-toggle',
          tooltip: isExpanded ? 'Close book actions' : 'Show book actions',
          onPressed: isLoading ? null : onToggle,
          backgroundColor: appColors.buttonBackground,
          foregroundColor: appColors.buttonForeground,
          child: AnimatedRotation(
            turns: isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(LucideIcons.plus),
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isVisible,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final bool isVisible;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: isVisible
          ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: appColors.buttonBackground,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: appColors.buttonForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: label,
                      tooltip: label,
                      onPressed: isLoading ? null : onPressed,
                      backgroundColor: appColors.buttonBackground,
                      foregroundColor: appColors.buttonForeground,
                      child: isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: appColors.buttonForeground,
                              ),
                            )
                          : Icon(icon, size: 18),
                    ),
                  ],
                )
                .animate()
                .slideY(
                  begin: 0.15,
                  duration: 180.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: 140.ms)
          : const SizedBox.shrink(),
    );
  }
}
