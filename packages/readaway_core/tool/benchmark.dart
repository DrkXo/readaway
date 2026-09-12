import 'dart:io';

import 'package:readaway_core/readaway_core.dart';

/// Benchmarks the EPUB open path vs per-section loading.
///
/// Usage:
///   dart run tool/benchmark.dart `<path-to.epub>` [`<path-to.epub>` ...]
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/benchmark.dart <file.epub> [...]');
    exitCode = 64;
    return;
  }

  for (final path in args) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('SKIP  $path (not found)');
      continue;
    }
    await _benchmark(path);
  }
}

Future<void> _benchmark(String path) async {
  stdout.writeln('=== $path ===');
  final file = File(path);
  final bytes = file.readAsBytesSync();

  // 1. ZIP decode only.
  final t0 = Stopwatch()..start();
  final container = EpubContainer.openBytes(bytes);
  t0.stop();
  stdout.writeln(
    '  EpubContainer.openBytes (ZIP decode): ${t0.elapsedMilliseconds}ms',
  );

  // 2. Full open (ZIP + XML parse).
  final t1 = Stopwatch()..start();
  final reader = await EpubDocumentReader.fromBytes(bytes);
  t1.stop();
  stdout.writeln(
    '  EpubDocumentReader.fromBytes (full open): ${t1.elapsedMilliseconds}ms',
  );

  // 3. Per-section loading.
  final t2 = Stopwatch()..start();
  for (var i = 0; i < reader.sectionCount; i++) {
    reader.loadSectionHtml(i);
  }
  t2.stop();
  stdout.writeln(
    '  loadSectionHtml x${reader.sectionCount}: ${t2.elapsedMilliseconds}ms '
    '(${t2.elapsedMicroseconds / reader.sectionCount}us/section)',
  );

  // 4. Asset loading (first section's dir).
  final t3 = Stopwatch()..start();
  if (reader.sections.isNotEmpty) {
    final first = reader.sections.first;
    final dir = first.href.contains('/')
        ? first.href.substring(0, first.href.lastIndexOf('/') + 1)
        : '';
    for (var i = 0; i < 100; i++) {
      reader.loadAsset('${dir}cover.jpg');
    }
  }
  t3.stop();
  stdout.writeln('  loadAsset x100: ${t3.elapsedMilliseconds}ms');

  container.dispose();
  reader.dispose();
  stdout.writeln();
}
