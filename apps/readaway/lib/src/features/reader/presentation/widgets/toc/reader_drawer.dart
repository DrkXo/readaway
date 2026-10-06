import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../annotations/domain/entity/reader_note.dart';
import 'reader_side_panel.dart';

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
      width: 336,
      backgroundColor: appColors.sidebarBackground,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
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
            headerAction: AppIconButton(
              icon: LucideIcons.x,
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              size: AppIconButtonSize.small,
            ),
          ),
        ),
      ),
    );
  }
}
