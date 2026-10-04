import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';

class LibraryActionsFab extends StatelessWidget {
  const LibraryActionsFab({
    super.key,
    required this.isLoading,
    required this.onAddBooks,
    required this.onOpenBook,
  });

  final bool isLoading;
  final VoidCallback onAddBooks;
  final VoidCallback onOpenBook;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Material(
      color: appColors.buttonBackground,
      elevation: 2,
      shadowColor: appColors.shadowMd.first.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: appColors.borderSubtle, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: 'Add books to library',
              child: InkWell(
                key: const ValueKey('library-add-books'),
                onTap: isLoading ? null : onAddBooks,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: appColors.buttonForeground,
                          ),
                        )
                      else
                        Icon(
                          LucideIcons.bookPlus,
                          size: 16,
                          color: appColors.buttonForeground,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        isLoading ? 'Adding…' : 'Add Book',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: appColors.buttonForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 6,
              endIndent: 6,
              color: appColors.buttonForeground.withValues(alpha: 0.3),
            ),
            Tooltip(
              message: 'Open book directly without adding to library',
              child: InkWell(
                key: const ValueKey('library-open-book'),
                onTap: isLoading ? null : onOpenBook,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.bookOpen,
                        size: 16,
                        color: appColors.buttonForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Open Book',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: appColors.buttonForeground,
                        ),
                      ),
                    ],
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
