import 'dart:io';

import 'package:readaway_core/readaway_core.dart';

import '../test/fixtures/epub_fixture.dart';

/// Benchmarks the isolate-based EPUB open path on a synthetic large book.
///
/// Usage:
///   dart run tool/benchmark_synthetic.dart [chapterCount]
Future<void> main(List<String> args) async {
  final chapterCount = args.isNotEmpty ? int.parse(args.first) : 2000;
  stdout.writeln('Building synthetic EPUB with $chapterCount chapters...');

  final build = Stopwatch()..start();
  final bytes = EpubFixture.build(chapterCount: chapterCount);
  build.stop();
  stdout.writeln(
    '  build: ${build.elapsedMilliseconds}ms '
    '(${(bytes.length / 1024).toStringAsFixed(0)} KiB)',
  );

  // Warm-up: ensure the isolate machinery is initialized.
  final warm = await EpubDocumentReader.fromBytes(bytes);
  warm.dispose();

  // Timed open (ZIP decode + OPF/outline parse in a background isolate).
  final t = Stopwatch()..start();
  final reader = await EpubDocumentReader.fromBytes(bytes);
  t.stop();

  stdout.writeln(
    '  EpubDocumentReader.fromBytes: ${t.elapsedMilliseconds}ms '
    '(${t.elapsedMicroseconds}us)',
  );
  stdout.writeln('  sections: ${reader.sectionCount}');
  stdout.writeln('  outline: ${reader.outline.length} items');
  stdout.writeln('  title: ${reader.title}');

  // Verify a section loads.
  final html = reader.loadSectionHtml(reader.sectionCount - 1);
  stdout.writeln('  last section html: ${html.length} chars');

  reader.dispose();
  stdout.writeln('OK');
}
