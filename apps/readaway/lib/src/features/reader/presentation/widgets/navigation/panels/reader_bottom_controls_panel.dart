import 'package:flutter/material.dart';

import '../../../../../../core/models/models.dart';
import '../../../../../../core/theme/theme.dart';
import 'reader_brightness_quick_view.dart';
import 'reader_font_size_quick_view.dart';
import 'reader_page_navigation_quick_view.dart';

/// Contextual controls panel that extends upward from the reader bottom bar.
///
/// Features customizable width/constraints, synchronized background theming,
/// grab handle indicator, and smooth contextual panel switching.
class ReaderBottomControlsPanel extends StatelessWidget {
  const ReaderBottomControlsPanel({
    super.key,
    required this.panelNotifier,
    required this.onClose,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSeekToPage,
    this.width = double.infinity,
    this.maxWidth = double.infinity,
    this.constraints,
    this.backgroundColor,
    this.decoration,
    this.borderRadius,
    this.showHandle = true,
  });

  final ValueNotifier<ReaderBottomPanel?> panelNotifier;
  final VoidCallback onClose;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onSeekToPage;

  /// Optional fixed width. Defaults to [double.infinity] to fill max available width.
  final double? width;

  /// Maximum allowed width for the panel. Defaults to [double.infinity].
  final double? maxWidth;

  /// Optional explicit box constraints overriding [width] and [maxWidth].
  final BoxConstraints? constraints;

  /// Optional background color for the panel.
  /// Controlled by parent. Defaults to [ColorScheme.surface] with alpha 0.95,
  /// matching the reader bottom bar.
  final Color? backgroundColor;

  /// Optional custom container decoration.
  final Decoration? decoration;

  /// Optional custom border radius when using default decoration.
  final BorderRadiusGeometry? borderRadius;

  /// Whether to display a subtle grab handle indicator at the top of the panel.
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = theme.extension<AppColors>() ?? AppColors.light;
    final panelBgColor =
        backgroundColor ?? scheme.surface.withValues(alpha: 0.95);

    final effectiveConstraints =
        constraints ??
        (maxWidth != null
            ? BoxConstraints(maxWidth: maxWidth!)
            : const BoxConstraints(maxWidth: double.infinity));

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        constraints: effectiveConstraints,
        decoration:
            decoration ??
            BoxDecoration(
              color: panelBgColor,
              borderRadius:
                  borderRadius ??
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: appColors.shadowLg,
            ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHandle)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 2),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ValueListenableBuilder<ReaderBottomPanel?>(
              valueListenable: panelNotifier,
              builder: (context, panel, _) {
                if (panel == null) return const SizedBox.shrink();

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: switch (panel) {
                    ReaderBottomPanel.brightness => ReaderBrightnessQuickView(
                      key: const ValueKey('brightness'),
                      onClose: onClose,
                    ),
                    ReaderBottomPanel.pageNavigation =>
                      ReaderPageNavigationQuickView(
                        key: const ValueKey('pageNavigation'),
                        onClose: onClose,
                        onPreviousPage: onPreviousPage,
                        onNextPage: onNextPage,
                        onSeekToPage: onSeekToPage,
                      ),
                    ReaderBottomPanel.fontSize => ReaderFontSizeQuickView(
                      key: const ValueKey('fontSize'),
                      onClose: onClose,
                    ),
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
