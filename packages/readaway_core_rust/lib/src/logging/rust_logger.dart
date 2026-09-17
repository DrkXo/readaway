import 'dart:async';
import 'package:logging/logging.dart';
import '../rust/api/init.dart';

final _rustLogger = Logger('RustCore');

StreamSubscription<RustLogEntry>? _logSub;

/// Connects the native Rust log stream to Dart's `package:logging`.
/// All `log::info!`, `log::warn!`, and `log::error!` calls from native Rust
/// will be forwarded to the 'RustCore' logger, which feeds into `Logger.root`.
void initReadawayCoreRustLogging({Level minLevel = Level.ALL}) {
  if (_logSub != null) return;

  _logSub = createLogStream().listen(
    (entry) {
      final level = _mapRustLevel(entry.level);
      if (level >= minLevel) {
        _rustLogger.log(level, '[${entry.tag}] ${entry.msg}');
      }
    },
    onError: (Object e, StackTrace st) {
      _rustLogger.warning('Error in Rust log stream: $e\n$st');
    },
  );
}

Level _mapRustLevel(int level) {
  switch (level) {
    case 1:
      return Level.SEVERE;
    case 2:
      return Level.WARNING;
    case 3:
      return Level.INFO;
    case 4:
      return Level.FINE;
    case 5:
      return Level.FINEST;
    default:
      return Level.INFO;
  }
}
