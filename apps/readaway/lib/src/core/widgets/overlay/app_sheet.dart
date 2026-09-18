part of '../core_widgets.dart';

/// Theme-aware bottom sheet (mobile) / popover (desktop).
///
/// On compact widths it renders as a bottom sheet with drag-to-dismiss and
/// safe-area handling; on wide widths it renders as a centered popover card
/// with a scrim. Uses [AppColors] shadows and surface tokens.
class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.maxWidth = 480,
    this.showDragHandle = true,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final double maxWidth;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return AdaptiveLayout(
      builder: (context, bp, constraints) {
        final isCompact = bp == AppBreakpoint.compact;

        final surface = Material(
          color: appColors.editorWidgetBackground,
          elevation: 0,
          borderRadius: isCompact
              ? const BorderRadius.vertical(top: Radius.circular(8))
              : BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: isCompact
                ? BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: appColors.editorWidgetBorder,
                        width: 1.0,
                      ),
                    ),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCompact && showDragHandle)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 3,
                        decoration: BoxDecoration(
                          color: appColors.borderSubtle,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                if (title != null || onClose != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
                    child: Row(
                      children: [
                        if (title != null)
                          Expanded(
                            child: AppHeading(title!, level: 2),
                          ),
                        if (onClose != null)
                          AppIconButton(
                            icon: LucideIcons.x,
                            tooltip: 'Close',
                            onPressed: onClose,
                            size: AppIconButtonSize.small,
                          ),
                      ],
                    ),
                  ),
                Flexible(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        );

        if (isCompact) {
          return surface;
        }

        // Wide: centered command palette card with crisp 1px border.
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: appColors.editorWidgetBorder,
                  width: 1.0,
                ),
                boxShadow: appColors.shadowMd,
              ),
              child: surface,
            ),
          ),
        );
      },
    );
  }
}

/// Shows [AppSheet] as a modal bottom sheet (compact) or popover (wide).
///
/// Returns the value from [builder]'s `Navigator.pop` when dismissed.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  double maxWidth = 480,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
    builder: (context) => AppSheet(
      title: title,
      maxWidth: maxWidth,
      onClose: () => Navigator.of(context).pop(),
      child: builder(context),
    ),
  );
}
