import 'dart:io';

// ignore_for_file: depend_on_referenced_packages
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

String? _findNdkDir() {
  final envVars = [
    Platform.environment['ANDROID_NDK_HOME'],
    Platform.environment['ANDROID_NDK_ROOT'],
    Platform.environment['NDK_HOME'],
  ];
  for (final v in envVars) {
    if (v != null && Directory(v).existsSync()) return v;
  }

  final sdkDirs = [
    Platform.environment['ANDROID_HOME'],
    Platform.environment['ANDROID_SDK_ROOT'],
    '${Platform.environment['HOME']}/Android/Sdk',
  ];
  for (final sdk in sdkDirs) {
    if (sdk == null) continue;
    final ndkParent = Directory('$sdk/ndk');
    if (ndkParent.existsSync()) {
      final versions = ndkParent.listSync().whereType<Directory>().toList();
      if (versions.isNotEmpty) {
        // Prefer 28.2.13676358 if present, otherwise newest
        final preferred = versions.where((d) => d.path.contains('28.2.13676358'));
        if (preferred.isNotEmpty) return preferred.first.path;
        versions.sort((a, b) => b.path.compareTo(a.path));
        return versions.first.path;
      }
    }
  }
  return null;
}

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageRoot = input.packageRoot;
    final mupdfDir = packageRoot.resolve('native/mupdf/').toFilePath();
    final targetOS = input.config.code.targetOS;
    final targetArch = input.config.code.targetArchitecture;

    final soName = targetOS == OS.windows
        ? 'mupdf_wrapper.dll'
        : 'libmupdf_wrapper.so';
    final outputPath = input.outputDirectory.resolve(soName).toFilePath();
    final includeDir = packageRoot.resolve('native/mupdf/include').toFilePath();
    final wrapperDir = packageRoot.resolve('native/wrapper').toFilePath();

    if (targetOS == OS.android) {
      final ndkDir = _findNdkDir();
      if (ndkDir == null) {
        throw StateError(
          'Android NDK not found. Please set ANDROID_NDK_HOME or install NDK in Android SDK.',
        );
      }

      // Check host prebuilt directory (linux-x86_64, darwin-x86_64, darwin-arm64, etc.)
      final prebuiltDir = Directory('$ndkDir/toolchains/llvm/prebuilt');
      final hostSubdirs = prebuiltDir.existsSync()
          ? prebuiltDir.listSync().whereType<Directory>().toList()
          : <Directory>[];
      if (hostSubdirs.isEmpty) {
        throw StateError('NDK LLVM toolchain not found at ${prebuiltDir.path}');
      }
      final llvmBin = Directory('${hostSubdirs.first.path}/bin');

      String clangPrefix;
      String archDir;
      if (targetArch == Architecture.arm64) {
        clangPrefix = 'aarch64-linux-android24';
        archDir = 'android-arm64';
      } else if (targetArch == Architecture.arm) {
        clangPrefix = 'armv7a-linux-androideabi24';
        archDir = 'android-arm';
      } else if (targetArch == Architecture.x64) {
        clangPrefix = 'x86_64-linux-android24';
        archDir = 'android-x64';
      } else if (targetArch == Architecture.ia32) {
        clangPrefix = 'i686-linux-android24';
        archDir = 'android-x86';
      } else {
        throw UnsupportedError('Unsupported Android architecture: $targetArch');
      }

      final ndkClang = '${llvmBin.path}/$clangPrefix-clang';
      final ndkClangXX = '${llvmBin.path}/$clangPrefix-clang++';
      final ndkAr = '${llvmBin.path}/llvm-ar';
      final ndkRanlib = '${llvmBin.path}/llvm-ranlib';
      final buildDir = '$mupdfDir/build/$archDir';

      // Build MuPDF static libs if not already built for this Android target
      final libFile = File('$buildDir/libmupdf.a');
      if (!await libFile.exists()) {
        stderr.writeln('Building MuPDF from source for Android $targetArch ($archDir)...');
        final result = await Process.run('make', [
          '-j${Platform.numberOfProcessors}',
          'libs',
          'OUT=build/$archDir',
          'CC=$ndkClang',
          'CXX=$ndkClangXX',
          'AR=$ndkAr',
          'RANLIB=$ndkRanlib',
          'XCFLAGS=-fPIC -Wl,-z,max-page-size=16384',
          'HAVE_OBJCOPY=no',
          'HAVE_GLUT=no',
          'HAVE_X11=no',
          'HAVE_LIBCRYPTO=no',
        ], workingDirectory: mupdfDir);
        if (result.exitCode != 0) {
          stderr.writeln('make stdout:\n${result.stdout}');
          stderr.writeln('make stderr:\n${result.stderr}');
          throw Exception('MuPDF Android build failed with exit code ${result.exitCode}');
        }
      }

      stderr.writeln('Compiling mupdf_wrapper.c for Android $targetArch (16KB aligned)...');
      final result = await Process.run(ndkClang, [
        '-shared',
        '-fPIC',
        '-Wl,-z,max-page-size=16384',
        '-o',
        outputPath,
        '$wrapperDir/mupdf_wrapper.c',
        '-I$includeDir',
        '-I$wrapperDir',
        '-L$buildDir',
        '-Wl,--whole-archive',
        '-lmupdf',
        '-lmupdf-third',
        '-Wl,--no-whole-archive',
        '-lm',
        '-llog',
      ]);

      if (result.exitCode != 0) {
        stderr.writeln('clang stdout:\n${result.stdout}');
        stderr.writeln('clang stderr:\n${result.stderr}');
        throw Exception('Clang build failed with exit code ${result.exitCode}');
      }
    } else {
      // Host / Desktop build (e.g. Linux x86_64)
      final buildDir = '$mupdfDir/build/release';
      final libFile = File('$buildDir/libmupdf.a');
      if (!await libFile.exists()) {
        stderr.writeln('Building MuPDF from source...');
        final result = await Process.run('make', [
          '-j${Platform.numberOfProcessors}',
          'XCFLAGS=-fPIC -Wl,-z,max-page-size=16384',
        ], workingDirectory: mupdfDir);
        if (result.exitCode != 0) {
          stderr.writeln('make stdout:\n${result.stdout}');
          stderr.writeln('make stderr:\n${result.stderr}');
          throw Exception('MuPDF build failed with exit code ${result.exitCode}');
        }
      }

      stderr.writeln('Compiling mupdf_wrapper.c for host (16KB aligned)...');
      final result = await Process.run('gcc', [
        '-shared',
        '-fPIC',
        '-Wl,-z,max-page-size=16384',
        '-o',
        outputPath,
        '$wrapperDir/mupdf_wrapper.c',
        '-I$includeDir',
        '-I$wrapperDir',
        '-L$buildDir',
        '-Wl,--whole-archive',
        '-lmupdf',
        '-lmupdf-third',
        '-Wl,--no-whole-archive',
        '-lm',
        '-lpthread',
      ]);

      if (result.exitCode != 0) {
        stderr.writeln('gcc stdout:\n${result.stdout}');
        stderr.writeln('gcc stderr:\n${result.stderr}');
        throw Exception('gcc build failed with exit code ${result.exitCode}');
      }
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'mupdf_wrapper.dart',
        file: input.outputDirectory.resolve(soName),
        linkMode: DynamicLoadingBundled(),
      ),
    );
  });
}
