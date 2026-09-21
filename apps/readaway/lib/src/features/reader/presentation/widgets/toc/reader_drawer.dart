import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import 'reader_toc_content.dart';

class ReaderDrawer extends StatelessWidget {
  const ReaderDrawer({super.key, required this.onJumpToPage});

  final void Function(int page) onJumpToPage;

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
          child: ReaderTocContent(
            onJumpToPage: (page) {
              Navigator.of(context).pop();
              onJumpToPage(page);
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
