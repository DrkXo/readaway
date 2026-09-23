import '../error/failures.dart';

/// Represents a single-fire, transient feedback notification to be rendered
/// by the UI (e.g. Floating SnackBar or Toast) with optional recovery action.
class UiFeedback {
  final Failure failure;
  final String? actionLabel;
  final String? actionRoute;
  final DateTime timestamp;

  UiFeedback({
    required this.failure,
    this.actionLabel,
    this.actionRoute,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UiFeedback &&
          runtimeType == other.runtimeType &&
          failure == other.failure &&
          actionLabel == other.actionLabel &&
          actionRoute == other.actionRoute &&
          timestamp == other.timestamp);

  @override
  int get hashCode =>
      Object.hash(runtimeType, failure, actionLabel, actionRoute, timestamp);
}
