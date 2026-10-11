import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../annotations/domain/entity/reader_note.dart';
import 'reader_side_panel.dart';

/// Metro-styled reader navigation drawer for mobile and compact viewports.
///
/// Features edge-to-edge typography, crisp 0px border radius, flat surface
/// contrast, and authentic Lumia [MetroPivot] panoramic navigation.
class ReaderDrawer extends StatelessWidget {
  const ReaderDrawer({
    super.key,
    required this.onJumpToPage,
    required this.onJumpToNote,
  });

  final void Function(int page) onJumpToPage;

  /// Called with the bookmark or annotation whose panel row was chosen.
  final void Function(ReaderNote note) onJumpToNote;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Drawer(
      width: 340,
      backgroundColor: appColors.sidebarBackground,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: appColors.sidebarBackground,
          border: Border(
            right: BorderSide(
              color: appColors.sidebarBorder,
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          child: ReaderSidePanel(
            onJumpToChapter: (chapter) {
              Navigator.of(context).pop();
              onJumpToPage(chapter);
            },
            onJumpToNote: (note) {
              Navigator.of(context).pop();
              onJumpToNote(note);
            },
            headerAction: const MetroDrawerCloseButton(),
          ),
        ),
      ),
    );
  }
}

/// Minimalist Metro-styled close button for the reader drawer header.
class MetroDrawerCloseButton extends StatelessWidget {
  const MetroDrawerCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return MetroPressable(
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.x,
              size: 16,
              color: appColors.readerForeground.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 4),
            Text(
              'close',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: appColors.readerForeground.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
