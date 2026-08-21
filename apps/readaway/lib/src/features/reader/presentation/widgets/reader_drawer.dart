import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/theme.dart';
import 'reader_toc_content.dart';

class ReaderDrawer extends StatelessWidget {
  const ReaderDrawer({super.key, required this.onJumpToPage});

  final void Function(int page) onJumpToPage;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final scheme = appColors.scheme;

    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(-1, 0),
          end: Offset.zero,
          duration: 200.ms,
          curve: Curves.easeOut,
        ),
      ],
      child: Drawer(
        backgroundColor: appColors.readerBackground,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: appColors.shadowLg,
          ),
          child: SafeArea(
            child: ReaderTocContent(
              onJumpToPage: onJumpToPage,
              headerAction: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                splashRadius: 20,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
