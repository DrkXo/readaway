import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

import '../../../flavors.dart';

export 'package:logging/logging.dart';

/// Global accessor for the app logger.
Logger get logger => GetIt.I<LoggingService>().logger;

@singleton
class LoggingService {
  final Logger _log = Logger(F.title);

  Logger get logger => _log;

  @PostConstruct(preResolve: true)
  Future<void> init() async {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = kDebugMode ? Level.FINEST : Level.OFF;
    Logger.root.onRecord.listen(_handleRecord);

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

  String _colorFor(Level level) {
    if (level >= Level.SEVERE) return '\x1B[31m';
    if (level >= Level.WARNING) return '\x1B[33m';
    if (level >= Level.INFO) return '\x1B[36m';
    return '\x1B[90m';
  }

  Logger getLogger(String name) => Logger(name);
}

extension LoggerX on Logger {
  void v(Object? message, [Object? error, StackTrace? stackTrace]) =>
      finest(message, error, stackTrace);

  void d(Object? message, [Object? error, StackTrace? stackTrace]) =>
      fine(message, error, stackTrace);

  void i(Object? message, [Object? error, StackTrace? stackTrace]) =>
      info(message, error, stackTrace);

  void w(Object? message, [Object? error, StackTrace? stackTrace]) =>
      warning(message, error, stackTrace);

  void e(Object? message, [Object? error, StackTrace? stackTrace]) =>
      severe(message, error, stackTrace);

  void wtf(Object? message, [Object? error, StackTrace? stackTrace]) =>
      shout(message, error, stackTrace);
}
