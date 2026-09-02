part of '../core_widgets.dart';

/// A value that adapts to the current [AppBreakpoint].
///
/// Use for spacing, sizes, and other numeric/object values that should scale
/// with the available width. Values cascade: a value defined for a larger
/// breakpoint falls back to the nearest smaller defined value.
class AdaptiveValue<T> {
  const AdaptiveValue({
    required this.compact,
    this.medium,
    this.expanded,
    this.wide,
  });

  /// Value used on [AppBreakpoint.compact].
  final T compact;

  /// Value used on [AppBreakpoint.medium]; falls back to [compact].
  final T? medium;

  /// Value used on [AppBreakpoint.expanded]; falls back to [medium].
  final T? expanded;

  /// Value used on [AppBreakpoint.wide]; falls back to [expanded].
  final T? wide;

  /// Resolves the value for [breakpoint].
  T resolve(AppBreakpoint breakpoint) => breakpoint.resolve(
    compact: compact,
    medium: medium,
    expanded: expanded,
    wide: wide,
  );

  /// Resolves the value for the current context's breakpoint.
  T of(BuildContext context) => resolve(context.breakpoint);
}

/// Applies adaptive horizontal gutters based on the current breakpoint.
///
/// Uses the standard 4/8dp spacing rhythm: compact 16, medium 24,
/// expanded 32, wide 48. Override any tier via the constructor.
class AdaptiveGutter extends StatelessWidget {
  const AdaptiveGutter({
    super.key,
    required this.child,
    this.compact = 16,
    this.medium = 24,
    this.expanded = 32,
    this.wide = 48,
    this.vertical = 0,
  });

  final Widget child;
  final double compact;
  final double medium;
  final double expanded;
  final double wide;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final bp = context.breakpoint;
    final h = bp.resolve(
      compact: compact,
      medium: medium,
      expanded: expanded,
      wide: wide,
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: vertical),
      child: child,
    );
  }
}

/// Applies adaptive padding from an [AdaptiveValue<EdgeInsetsGeometry>].
class AdaptivePadding extends StatelessWidget {
  const AdaptivePadding({
    super.key,
    required this.padding,
    required this.child,
  });

  final AdaptiveValue<EdgeInsetsGeometry> padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding.of(context), child: child);
  }
}
