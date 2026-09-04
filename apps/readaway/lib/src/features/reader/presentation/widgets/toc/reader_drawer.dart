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
      backgroundColor: appColors.readerBackground,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: appColors.shadowLg,
        ),
        child: SafeArea(
          child: ReaderTocContent(
            onJumpToPage: onJumpToPage,
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
