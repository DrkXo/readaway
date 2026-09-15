import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_io.dart';
import 'frb_generated.dart';

bool _rustInitialized = false;

/// Ensures flutter_rust_bridge is initialized.
///
/// In Flutter app runtime, loads the default platform-bundled library.
/// In headless unit tests or standalone execution, searches known cargo build
/// directories to find the compiled dynamic library.
Future<void> ensureRustInitialized() async {
  if (_rustInitialized) return;

  try {
    await RustLib.init();
    _rustInitialized = true;
    return;
  } catch (_) {
    final candidatePaths = [
      '../../packages/readaway_core_rust/rust/target/release/libreadaway_core_rust.so',
      '../../packages/readaway_core_rust/rust/target/debug/libreadaway_core_rust.so',
      '../packages/readaway_core_rust/rust/target/release/libreadaway_core_rust.so',
      '../packages/readaway_core_rust/rust/target/debug/libreadaway_core_rust.so',
      'packages/readaway_core_rust/rust/target/release/libreadaway_core_rust.so',
      'packages/readaway_core_rust/rust/target/debug/libreadaway_core_rust.so',
      'rust/target/release/libreadaway_core_rust.so',
      'rust/target/debug/libreadaway_core_rust.so',
    ];

    for (final relPath in candidatePaths) {
      final file = File(relPath);
      if (file.existsSync()) {
        try {
          await RustLib.init(
            externalLibrary: ExternalLibrary.open(file.absolute.path),
          );
          _rustInitialized = true;
          return;
        } catch (_) {}
      }
    }
  }
}
