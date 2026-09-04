import 'dart:io';

// ignore_for_file: depend_on_referenced_packages
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final packageRoot = input.packageRoot;
    final mupdfDir = packageRoot.resolve('native/mupdf/').toFilePath();
    final buildDir = '$mupdfDir/build/release';

    // Build MuPDF static libs if not already built
    final libFile = File('$buildDir/libmupdf.a');
    if (!await libFile.exists()) {
      stderr.writeln('Building MuPDF from source...');
      final result = await Process.run('make', [
        '-j${Platform.numberOfProcessors}',
        'XCFLAGS=-fPIC',
      ], workingDirectory: mupdfDir);
      if (result.exitCode != 0) {
        stderr.writeln('make stdout:\n${result.stdout}');
        stderr.writeln('make stderr:\n${result.stderr}');
        throw Exception('MuPDF build failed with exit code ${result.exitCode}');
      }
    }

    // Always rebuild the wrapper — it's fast and avoids stale-symbol issues
    final soName = 'libmupdf_wrapper.so';
    final outputPath = input.outputDirectory.resolve(soName).toFilePath();

    final includeDir = packageRoot.resolve('native/mupdf/include').toFilePath();
    final wrapperDir = packageRoot.resolve('native/wrapper').toFilePath();

    stderr.writeln('Compiling mupdf_wrapper.c ...');
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
