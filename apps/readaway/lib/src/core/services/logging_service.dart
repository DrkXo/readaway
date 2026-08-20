part of 'services.dart';

Logger get logger => GetIt.I<LoggingService>().logger;

@singleton
class LoggingService {
  final Logger _log = Logger('ReadAway');

  Logger get logger => _log;

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    // 1. Enable hierarchical logging if fine-grained logger configuration is needed
    hierarchicalLoggingEnabled = true;

    // 2. Set root logging level (ALL allows all messages to pass through unless filtered elsewhere)
    Logger.root.level = kDebugMode ? Level.FINEST : Level.OFF;

    // 3. Listen for root log records and output them
    Logger.root.onRecord.listen((record) {
      final errorStr = record.error != null ? ' | Error: ${record.error}' : '';
      final stackStr = record.stackTrace != null
          ? '\n${record.stackTrace}'
          : '';

      debugPrint(
        '[${record.time}] ${record.level.name} [${record.loggerName}]: '
        '${record.message}$errorStr$stackStr',
      );
    });

    // 4. Optionally listen for log level changes across the app
    Logger.root.onLevelChanged.listen((level) {
      debugPrint('[LoggingService]: Root log level changed to $level');
    });

    _log.info('LoggingService successfully initialized.');
  }

  /// Convenience wrapper to access a named Logger instance.
  Logger getLogger(String name) => Logger(name);
}
