part of "services.dart";

/// Represents a lifecycle event with additional context
class LifecycleEvent extends Equatable {
  final LifecycleEventType type;
  final AppLifecycleState currentState;
  final AppLifecycleState? previousState;
  final DateTime timestamp;
  final Duration? duration;

  const LifecycleEvent({
    required this.type,
    required this.currentState,
    this.previousState,
    required this.timestamp,
    this.duration,
  });

  @override
  String toString() {
    return 'LifecycleEvent(type: ${type.name}, '
        'current: ${currentState.name}, '
        'previous: ${previousState?.name}, '
        'duration: ${duration?.inSeconds}s)';
  }

  @override
  List<Object?> get props => [
    type,
    currentState,
    previousState,
    timestamp,
    duration,
  ];
}

/// Types of lifecycle events
enum LifecycleEventType {
  initialized,
  foreground,
  background,
  stateChange,
}

/// Extension to add lifecycle state helpers
extension AppLifecycleStateX on AppLifecycleState {
  bool get isResumed => this == AppLifecycleState.resumed;
  bool get isPaused => this == AppLifecycleState.paused;
  bool get isInactive => this == AppLifecycleState.inactive;
  bool get isDetached => this == AppLifecycleState.detached;
  bool get isHidden => this == AppLifecycleState.hidden;
}

AppLifecycleManager get appLifecycleManager => GetIt.I.get();

/// Service that manages and broadcasts app lifecycle state changes
@singleton
class AppLifecycleManager with WidgetsBindingObserver {
  static AppLifecycleManager? _instance;

  // Private constructor for singleton
  AppLifecycleManager._();

  // Singleton instance
  factory AppLifecycleManager() {
    _instance ??= AppLifecycleManager._();
    return _instance!;
  }

  // Stream controller for lifecycle state
  final BehaviorSubject<AppLifecycleState> _lifecycleStateSubject =
      BehaviorSubject<AppLifecycleState>.seeded(AppLifecycleState.resumed);

  // Stream controller for lifecycle events
  final PublishSubject<LifecycleEvent> _lifecycleEventSubject =
      PublishSubject<LifecycleEvent>();

  // Track if the manager is initialized
  bool _isInitialized = false;

  // Track previous state for transition detection
  AppLifecycleState? _previousState;

  // Track time stamps for analytics
  DateTime? _backgroundTime;
  DateTime? _foregroundTime;

  /// Current lifecycle state
  AppLifecycleState get currentState => _lifecycleStateSubject.value;

  /// Stream of lifecycle state changes
  Stream<AppLifecycleState> get lifecycleState => _lifecycleStateSubject.stream;

  /// Stream of lifecycle events (with context about transitions)
  Stream<LifecycleEvent> get lifecycleEvents => _lifecycleEventSubject.stream;

  /// Check if app is currently in foreground
  bool get isInForeground => currentState == AppLifecycleState.resumed;

  /// Check if app is currently in background
  bool get isInBackground =>
      currentState == AppLifecycleState.paused ||
      currentState == AppLifecycleState.inactive ||
      currentState == AppLifecycleState.hidden ||
      currentState == AppLifecycleState.detached;

  /// Initialize the lifecycle manager
  void initialize() {
    if (_isInitialized) {
      // logger.d('[AppLifecycleManager] Already initialized');
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    _foregroundTime = DateTime.now();

    logger.info('[AppLifecycleManager] Initialized');

    // Emit initialization event
    _lifecycleEventSubject.add(
      LifecycleEvent(
        type: LifecycleEventType.initialized,
        currentState: currentState,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.info(
      '[AppLifecycleManager] State changed: ${_previousState?.name} -> ${state.name}',
    );

    final previousState = _previousState;
    _previousState = state;

    // Update the state stream
    _lifecycleStateSubject.add(state);

    // Determine the event type and emit appropriate event
    final event = _createLifecycleEvent(state, previousState);
    _lifecycleEventSubject.add(event);

    // Track time stamps
    _updateTimestamps(state);
  }

  /// Create a lifecycle event based on state transition
  LifecycleEvent _createLifecycleEvent(
    AppLifecycleState currentState,
    AppLifecycleState? previousState,
  ) {
    LifecycleEventType eventType;
    Duration? duration;

    // Determine event type based on transition
    if (_isTransitionToForeground(previousState, currentState)) {
      eventType = LifecycleEventType.foreground;
      if (_backgroundTime != null) {
        duration = DateTime.now().difference(_backgroundTime!);
      }
    } else if (_isTransitionToBackground(previousState, currentState)) {
      eventType = LifecycleEventType.background;
      if (_foregroundTime != null) {
        duration = DateTime.now().difference(_foregroundTime!);
      }
    } else {
      eventType = LifecycleEventType.stateChange;
    }

    return LifecycleEvent(
      type: eventType,
      currentState: currentState,
      previousState: previousState,
      timestamp: DateTime.now(),
      duration: duration,
    );
  }

  /// Check if transitioning to foreground
  bool _isTransitionToForeground(
    AppLifecycleState? previous,
    AppLifecycleState current,
  ) {
    if (previous == null) return false;

    final wasInBackground =
        previous == AppLifecycleState.paused ||
        previous == AppLifecycleState.inactive ||
        previous == AppLifecycleState.hidden ||
        previous == AppLifecycleState.detached;

    final isNowInForeground = current == AppLifecycleState.resumed;

    return wasInBackground && isNowInForeground;
  }

  /// Check if transitioning to background
  bool _isTransitionToBackground(
    AppLifecycleState? previous,
    AppLifecycleState current,
  ) {
    if (previous == null) return false;

    final wasInForeground = previous == AppLifecycleState.resumed;

    final isNowInBackground =
        current == AppLifecycleState.paused ||
        current == AppLifecycleState.inactive ||
        current == AppLifecycleState.hidden ||
        current == AppLifecycleState.detached;

    return wasInForeground && isNowInBackground;
  }

  /// Update timestamps for analytics
  void _updateTimestamps(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foregroundTime = DateTime.now();
    } else if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
    }
  }

  /// Get duration app has been in current state
  Duration? get currentStateDuration {
    if (_previousState == AppLifecycleState.resumed &&
        _foregroundTime != null) {
      return DateTime.now().difference(_foregroundTime!);
    } else if (_previousState == AppLifecycleState.paused &&
        _backgroundTime != null) {
      return DateTime.now().difference(_backgroundTime!);
    }
    return null;
  }

  /// Listen to specific lifecycle event types
  Stream<LifecycleEvent> listenToEventType(LifecycleEventType type) {
    return _lifecycleEventSubject.stream.where((event) => event.type == type);
  }

  /// Listen to foreground events only
  Stream<LifecycleEvent> get onForeground =>
      listenToEventType(LifecycleEventType.foreground);

  /// Listen to background events only
  Stream<LifecycleEvent> get onBackground =>
      listenToEventType(LifecycleEventType.background);

  /// Dispose the lifecycle manager
  void dispose() {
    if (!_isInitialized) return;

    // logger.d('[AppLifecycleManager] Disposing');

    WidgetsBinding.instance.removeObserver(this);
    _lifecycleStateSubject.close();
    _lifecycleEventSubject.close();
    _isInitialized = false;
    _instance = null;
  }

  /// Check if manager is initialized
  bool get isInitialized => _isInitialized;
}
