import 'dart:ffi';
import 'dart:io';

/// Resolves the native mupdf_wrapper library.
///
/// [MUPDF_WRAPPER_PATH] overrides the default lookup (dev/tests pointing at
/// a locally built wrapper).
DynamicLibrary openMupdfLib() {
  final override = Platform.environment['MUPDF_WRAPPER_PATH'];
  if (override != null && override.isNotEmpty) {
    return DynamicLibrary.open(override);
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libmupdf_wrapper.so');
  } else if (Platform.isIOS || Platform.isMacOS) {
    return DynamicLibrary.process();
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libmupdf_wrapper.so');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('mupdf_wrapper.dll');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}
