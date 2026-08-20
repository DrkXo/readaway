part of 'services.dart';

/// Global accessor for the app logger.
Logger get logger => GetIt.I<LoggingService>().logger;

@singleton
class LoggingService {
  final Logger _log = Logger(F.title);

  Logger get logger => _log;

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    // 1. Enable hierarchical logging if fine-grained logger configuration is needed
    hierarchicalLoggingEnabled = true;

    // 2. Set root logging level (ALL allows all messages to pass through unless filtered elsewhere)
    Logger.root.level = kDebugMode ? Level.FINEST : Level.OFF;

    // 3. Listen for root log records and output them
    Logger.root.onRecord.listen(_handleRecord);

    // 4. Optionally listen for log level changes across the app
    Logger.root.onLevelChanged.listen((level) {
      debugPrint('[${F.title}]: Root log level changed to $level');
    });

    _log.info('LoggingService successfully initialized.');
  }

  void _handleRecord(LogRecord record) {
    final time = _formatTime(record.time);
    final color = _colorFor(record.level);
    const reset = '\x1B[0m';

    final errorStr = record.error != null ? ' | Error: ${record.error}' : '';
    final stackStr = record.stackTrace != null ? '\n${record.stackTrace}' : '';

    debugPrint(
      '$color[$time] ${record.level.name.padRight(7)} '
      '[${record.loggerName}]: ${record.message}$errorStr$reset$stackStr',
    );
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    String three(int n) => n.toString().padLeft(3, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${three(t.millisecond)}';
  }

  /// ANSI color per level so warnings/errors stand out in a terminal.
  /// Falls back to plain text automatically on consoles that don't
  /// interpret ANSI codes (they'll just show the raw escape sequence
  /// harmlessly, or nothing at all depending on the IDE).
  String _colorFor(Level level) {
    if (level >= Level.SEVERE) return '\x1B[31m'; // red
    if (level >= Level.WARNING) return '\x1B[33m'; // yellow
    if (level >= Level.INFO) return '\x1B[36m'; // cyan
    return '\x1B[90m'; // grey: CONFIG/FINE/FINER/FINEST
  }

  /// Convenience wrapper to access a named Logger instance.
  /// Note: `Logger(name)` is already cached internally by the `logging`
  /// package, so repeated calls with the same name return the same
  /// instance — this isn't creating duplicates.
  Logger getLogger(String name) => Logger(name);
}

/// Short, convenient logging methods, e.g. `logger.d('message')`,
/// `logger.e('failed', error, stackTrace)`.
extension LoggerX on Logger {
  /// Verbose (maps to `finest`).
  void v(Object? message, [Object? error, StackTrace? stackTrace]) =>
      finest(message, error, stackTrace);

  /// Debug (maps to `fine`).
  void d(Object? message, [Object? error, StackTrace? stackTrace]) =>
      fine(message, error, stackTrace);

  /// Info.
  void i(Object? message, [Object? error, StackTrace? stackTrace]) =>
      info(message, error, stackTrace);

  /// Warning.
  void w(Object? message, [Object? error, StackTrace? stackTrace]) =>
      warning(message, error, stackTrace);

  /// Error (maps to `severe`).
  void e(Object? message, [Object? error, StackTrace? stackTrace]) =>
      severe(message, error, stackTrace);

  /// Fatal (maps to `shout`).
  void wtf(Object? message, [Object? error, StackTrace? stackTrace]) =>
      shout(message, error, stackTrace);
}
