part of '../core_widgets.dart';

/// Device/form-factor breakpoints used across the app.
///
/// These mirror Material 3 window size classes but are tuned for the reader:
/// - [compact]: phones / narrow windows (< 600)
/// - [medium]: small tablets / split windows (600 – 839)
/// - [expanded]: large tablets / desktop (840 – 1199)
/// - [wide]: large desktop windows (>= 1200)
enum AppBreakpoint {
  compact,
  medium,
  expanded,
  wide;

  /// Whether this breakpoint is at least [other] in the ordering.
  bool isAtLeast(AppBreakpoint other) =>
      AppBreakpoint.values.indexOf(this) >= AppBreakpoint.values.indexOf(other);

  /// Whether this breakpoint is at most [other] in the ordering.
  bool isAtMost(AppBreakpoint other) =>
      AppBreakpoint.values.indexOf(this) <= AppBreakpoint.values.indexOf(other);

  /// Resolves [this] against a table keyed by breakpoint, falling back to
  /// the nearest smaller defined value (or the first defined value).
  T resolve<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? wide,
  }) {
    switch (this) {
      case AppBreakpoint.compact:
        return compact;
      case AppBreakpoint.medium:
        return medium ?? compact;
      case AppBreakpoint.expanded:
        return expanded ?? medium ?? compact;
      case AppBreakpoint.wide:
        return wide ?? expanded ?? medium ?? compact;
    }
  }
}

/// Resolves an [AppBreakpoint] from a [BoxConstraints] width.
AppBreakpoint breakpointFromWidth(double width) {
  if (width >= 1200) return AppBreakpoint.wide;
  if (width >= 840) return AppBreakpoint.expanded;
  if (width >= 600) return AppBreakpoint.medium;
  return AppBreakpoint.compact;
}

/// Extension exposing the current [AppBreakpoint] and common flags.
extension AppBreakpointContext on BuildContext {
  /// The current breakpoint, derived from the nearest [MediaQuery] width.
  AppBreakpoint get breakpoint =>
      breakpointFromWidth(MediaQuery.sizeOf(this).width);

  /// True on [AppBreakpoint.expanded] or [AppBreakpoint.wide].
  bool get isWide =>
      breakpoint == AppBreakpoint.expanded || breakpoint == AppBreakpoint.wide;

  /// True on [AppBreakpoint.compact] or [AppBreakpoint.medium].
  bool get isCompact => !isWide;
}

/// A [LayoutBuilder] wrapper that exposes the resolved [AppBreakpoint] and
/// common flags to its builder, avoiding repeated inline breakpoint math.
///
/// Prefer this over raw `LayoutBuilder` + `maxWidth >= 900` checks so the
/// thresholds stay consistent app-wide.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    AppBreakpoint breakpoint,
    BoxConstraints constraints,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = breakpointFromWidth(constraints.maxWidth);
        return builder(context, bp, constraints);
      },
    );
  }
}
