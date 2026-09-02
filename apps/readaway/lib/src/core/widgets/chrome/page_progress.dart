part of '../core_widgets.dart';

/// Theme-aware reading progress indicator.
///
/// A thin linear progress bar with an optional "x / y" page label. Generic —
/// takes [value] and [label] rather than depending on [ReaderBloc], so it can
/// be reused for any progress display.
class PageProgressIndicator extends StatelessWidget {
  const PageProgressIndicator({
    super.key,
    required this.value,
    this.label,
    this.minHeight = 2,
    this.showLabel = true,
  });

  /// Progress in the range 0.0 – 1.0.
  final double value;

  /// Optional "x / y" label shown to the right of the bar.
  final String? label;

  final double minHeight;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = value.clamp(0.0, 1.0);

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(minHeight / 2),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: minHeight,
        backgroundColor: scheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
      ),
    );

    if (!showLabel || label == null) return bar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: bar),
        const SizedBox(width: 12),
        AppCaption(label!),
      ],
    );
  }
}
