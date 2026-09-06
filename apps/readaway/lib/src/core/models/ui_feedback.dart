import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Represents a single-fire, transient feedback notification to be rendered
/// by the UI (e.g. Floating SnackBar or Toast) with optional recovery action.
class UiFeedback extends Equatable {
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
  List<Object?> get props => [failure, actionLabel, actionRoute, timestamp];
}
