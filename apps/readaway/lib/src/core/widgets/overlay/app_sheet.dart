part of '../core_widgets.dart';

/// Theme-aware bottom sheet (mobile) / modal dialog card (desktop).
///
/// On compact widths it renders as an opaque bottom sheet with drag-to-dismiss,
/// top border, and safe-area handling. On wide widths (>= 600) it renders as a
/// centered modal dialog card with a 1px border, shadow, and backdrop scrim.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.maxWidth = 480,
    this.showDragHandle = true,
    this.isDialog,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final double maxWidth;
  final bool showDragHandle;

  /// Explicitly forces dialog or bottom sheet presentation.
  /// When null, adapts based on breakpoint: compact is a bottom sheet,
  /// medium/expanded/wide is a dialog.
  final bool? isDialog;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return AdaptiveLayout(
      builder: (context, bp, constraints) {
        final asDialog = isDialog ?? (bp != AppBreakpoint.compact);

        Widget buildHeader({required EdgeInsets padding}) {
          if (title == null && onClose == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: padding,
            child: Row(
              children: [
                if (title != null)
                  Expanded(
                    child: AppHeading(title!, level: 2),
                  )
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

        if (asDialog) {
          // Wide / Desktop: centered modal card with 1px border and drop shadow.
          final card = Material(
            color: appColors.editorWidgetBackground,
            elevation: 0,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appColors.editorWidgetBorder,
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  buildHeader(
                    padding: const EdgeInsets.fromLTRB(16, 12, 10, 8),
                  ),
                  Flexible(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
          );

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: appColors.shadowMd,
                ),
                child: card,
              ),
            ),
          );
        }

        // Compact / Mobile: solid bottom sheet with top border and safe area.
        return Material(
          color: appColors.editorWidgetBackground,
          elevation: 0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: appColors.editorWidgetBorder,
                  width: 1.0,
                ),
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
                  buildHeader(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  ),
                  Flexible(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shows [AppSheet] as an adaptive modal: a bottom sheet on compact screens (< 600px)
/// or a centered modal dialog card on wide screens (>= 600px).
///
/// Returns the value from [builder]'s `Navigator.pop` when dismissed.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  double maxWidth = 480,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  final isCompact = MediaQuery.sizeOf(context).width < 600;

  if (isCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      isDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
      builder: (sheetContext) => AppSheet(
        title: title,
        maxWidth: maxWidth,
        isDialog: false,
        onClose: () => Navigator.of(sheetContext).pop(),
        child: builder(sheetContext),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: AppSheet(
        title: title,
        maxWidth: maxWidth,
        isDialog: true,
        showDragHandle: false,
        onClose: () => Navigator.of(dialogContext).pop(),
        child: builder(dialogContext),
      ),
    ),
  );
}
