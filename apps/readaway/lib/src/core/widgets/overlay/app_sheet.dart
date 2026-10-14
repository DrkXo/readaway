part of '../core_widgets.dart';

/// Theme-aware bottom sheet with a top border, drag handle, optional header
/// and safe-area handling. Always bottom-anchored, never a dialog.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.showDragHandle = true,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    Widget buildHeader() {
      if (title == null && onClose == null) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            if (title != null)
              Expanded(child: AppHeading(title!, level: 2))
            else
              const Spacer(),
            if (onClose != null)
              AppIconButton(
                icon: LucideIcons.x,
                tooltip: 'Close',
                onPressed: onClose,
                size: AppIconButtonSize.small,
              ),
          ],
        ),
      );
    }

    return Material(
      color: appColors.editorWidgetBackground,
      elevation: 0,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: appColors.editorWidgetBorder, width: 1.0),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: appColors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              buildHeader(),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [AppSheet] as a bottom-anchored modal sheet on every screen size.
///
/// Returns the value from [builder]'s `Navigator.pop` when dismissed.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    isDismissible: barrierDismissible,
    enableDrag: barrierDismissible,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(side: BorderSide.none),
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
    // Full width on tablets/desktop (Material's default caps at 640px).
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (sheetContext) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        // Lifts the sheet above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: AppSheet(
          title: title,
          onClose: () {
            onClose?.call();
            Navigator.of(sheetContext).pop();
          },
          child: builder(sheetContext),
        ),
      );
    },
  );
}
