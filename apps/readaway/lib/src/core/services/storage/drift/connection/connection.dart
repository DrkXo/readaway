/// Platform-specific drift connection.
///
/// Native builds use a background isolate with WAL; web builds use the WASM
/// worker. Only one of the two files is ever compiled into a given build, which
/// is what allows each to use its own platform APIs without dragging
/// `dart:io` into the web build.
library;

export 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';
