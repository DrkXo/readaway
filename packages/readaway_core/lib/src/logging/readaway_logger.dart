import 'package:logging/logging.dart';

final _coreLogger = Logger('ReadAwayCore');

/// Initializes logging for the ReadAway core engine.
void initReadawayCoreLogging({Level minLevel = Level.ALL}) {
  _coreLogger.fine('ReadAway core pure Dart engine initialized');
}
