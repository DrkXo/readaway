part of '../reader_widgets.dart';

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
                  LucideIcons.x,
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
