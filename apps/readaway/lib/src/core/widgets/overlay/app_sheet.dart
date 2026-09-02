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
    final scheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return AdaptiveLayout(
      builder: (context, bp, constraints) {
        final isCompact = bp == AppBreakpoint.compact;

        final surface = Material(
          color: scheme.surfaceContainerLow,
          elevation: 0,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isCompact ? 20 : 16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isCompact && showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              if (title != null || onClose != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
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
        );

        if (isCompact) {
          return surface;
        }

        // Wide: centered popover card with scrim.
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: appColors.shadowLg,
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
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => AppSheet(
      title: title,
      maxWidth: maxWidth,
      onClose: () => Navigator.of(context).pop(),
      child: builder(context),
    ),
  );
}
