import 'dart:isolate';

import 'package:readaway_core/readaway_core.dart';

/// Throwaway probe: error sendability across isolates.
Future<void> main() async {
  // Probe A: DocumentParseException with null cause.
  try {
    await Isolate.run(() => throw const DocumentParseException('boom'));
  } catch (e) {
    print('DocumentParseException(null cause): ${e.runtimeType} -> $e');
  }

  // Probe B: DocumentParseException with a non-sendable cause.
  try {
    await Isolate.run(
      () => throw DocumentParseException('boom', cause: Object()),
    );
  } catch (e) {
    print('DocumentParseException(Object cause): ${e.runtimeType} -> $e');
  }

  // Probe C: plain Exception.
  try {
    await Isolate.run(() => throw Exception('boom'));
  } catch (e) {
    print('Exception: ${e.runtimeType} -> $e');
  }
}
