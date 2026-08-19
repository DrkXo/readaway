import 'dart:ffi';
import 'dart:io';

/// Resolves the native mupdf_wrapper library.
DynamicLibrary openMupdfLib() {
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
