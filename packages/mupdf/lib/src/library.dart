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
    // Try standard name first, then fallback to local repo candidates for tests/CLI
    final candidates = [
      'libmupdf_wrapper.so',
      'mupdf_wrapper.so',
      'packages/mupdf/native/libmupdf_wrapper.so',
      'packages/mupdf/native/mupdf_wrapper.so',
      'native/libmupdf_wrapper.so',
      'native/mupdf_wrapper.so',
    ];
    for (final candidate in candidates) {
      try {
        return DynamicLibrary.open(candidate);
      } catch (_) {}
    }
    // Try resolving relative to Platform.script
    final scriptDir = File(Platform.script.toFilePath()).parent;
    final searchDirs = [scriptDir, scriptDir.parent, scriptDir.parent.parent];
    for (final dir in searchDirs) {
      final subCandidates = [
        '${dir.path}/packages/mupdf/native/mupdf_wrapper.so',
        '${dir.path}/native/mupdf_wrapper.so',
        '${dir.path}/mupdf_wrapper.so',
      ];
      for (final path in subCandidates) {
        if (File(path).existsSync()) {
          try {
            return DynamicLibrary.open(path);
          } catch (_) {}
        }
      }
    }
    return DynamicLibrary.open('libmupdf_wrapper.so');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('mupdf_wrapper.dll');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}
