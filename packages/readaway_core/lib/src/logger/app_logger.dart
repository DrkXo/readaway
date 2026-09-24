import 'dart:io' as io;

import 'package:logger/logger.dart';

/// SimplePrinter, but with a short HH:mm:ss timestamp instead of the
/// full DateTime.now().toString().
class ShortTimePrinter extends LogPrinter {
  final SimplePrinter _inner;
  ShortTimePrinter({bool colors = false})
    : _inner = SimplePrinter(colors: colors, printTime: false);

  @override
  List<String> log(LogEvent event) {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
    return _inner.log(event).map((line) => '$time $line').toList();
  }
}

/// AppLogger.instance.d("msg")            -> plain single-line
/// AppLogger.instance.scope('Auth').w(..) -> "[Auth] msg" prefix
/// Errors/fatals get the boxed, colored PrettyPrinter treatment; everything
/// else stays minimal via ShortTimePrinter.
class AppLogger {
  AppLogger._()
    : _logger = Logger(
        filter: DevelopmentFilter(),
        printer: HybridPrinter(
          ShortTimePrinter(colors: false),
          error: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 8,
            colors: io.stdout.hasTerminal && io.stdout.supportsAnsiEscapes,
            printEmojis: false,
            levelColors: {Level.error: const AnsiColor.fg(196)},
          ),
          fatal: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 8,
            colors: io.stdout.hasTerminal && io.stdout.supportsAnsiEscapes,
            printEmojis: false,
            levelColors: {Level.fatal: const AnsiColor.fg(196)},
          ),
        ),
        output: ConsoleOutput(),
      );

  static final AppLogger instance = AppLogger._();
  final Logger _logger;
  final Map<String, ScopedLogger> _scopes = {};

  void t(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.t(message, error: error, stackTrace: stackTrace);
  void d(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(message, error: error, stackTrace: stackTrace);
  void i(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);
  void w(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);
  void e(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
  void f(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);

  ScopedLogger scope(String name) =>
      _scopes.putIfAbsent(name, () => ScopedLogger._(this, name));
}

class ScopedLogger {
  ScopedLogger._(this._parent, this.name);
  final AppLogger _parent;
  final String name;
  dynamic _tag(dynamic message) =>
      message is String ? '[$name] $message' : message;

  void t(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _parent.t(_tag(message), error: error, stackTrace: stackTrace);
  void d(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _parent.d(_tag(message), error: error, stackTrace: stackTrace);
  void i(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _parent.i(_tag(message), error: error, stackTrace: stackTrace);
  void w(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _parent.w(_tag(message), error: error, stackTrace: stackTrace);
  void e(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _parent.e(_tag(message), error: error, stackTrace: stackTrace);
  void f(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _parent.f(_tag(message), error: error, stackTrace: stackTrace);
}
