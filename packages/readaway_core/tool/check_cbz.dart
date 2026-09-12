import 'dart:io';

import 'package:readaway_core/readaway_core.dart';

/// Exercises [CbzDocumentReader] against real CBZ files.
///
/// Usage:
///   `dart run tool/check_cbz.dart <path-to.cbz> [<path-to.cbz> ...]`
///
/// File paths are passed on the command line so no document paths are
/// hardcoded into the repository.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/check_cbz.dart <file.cbz> [...]');
    exitCode = 64;
    return;
  }

  var failures = 0;
  for (final path in args) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('SKIP  $path (not found)');
      failures++;
      continue;
    }
    try {
      await _checkCbz(path);
    } catch (e, st) {
      failures++;
      stderr.writeln('FAIL  $path\n  $e\n$st');
    }
  }

  if (failures > 0) {
    stderr.writeln('\n$failures file(s) failed.');
    exitCode = 1;
  } else {
    stdout.writeln('\nAll files OK.');
  }
}

Future<void> _checkCbz(String path) async {
  stdout.writeln('=== $path ===');
  final reader = await DocumentReaderFactory().open(path);
  if (reader is! CbzDocumentReader) {
    throw StateError('Expected CbzDocumentReader, got ${reader.runtimeType}');
  }
  try {
    stdout.writeln('  format:        ${reader.format}');
    stdout.writeln('  isReflowable:  ${reader.isReflowable}');
    stdout.writeln('  title:         ${reader.title}');
    stdout.writeln('  pageCount:     ${reader.pageCount}');
    stdout.writeln('  cover:         ${reader.coverImagePath}');

    final page = await reader.renderPage(0);
    stdout.writeln(
      '  page[0]:       ${page.width}x${page.height} '
      'components=${page.components} stride=${page.stride} '
      'bytes=${page.pixels.length}',
    );
  } finally {
    reader.dispose();
  }
}
