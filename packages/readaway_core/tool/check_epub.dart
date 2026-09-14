import 'dart:io';

import 'package:readaway_core/readaway_core.dart';

/// Exercises [EpubDocumentReader] against real EPUB files.
///
/// Usage:
///   `dart run tool/check_epub.dart <path-to.epub> [<path-to.epub> ...]`
///
/// File paths are passed on the command line so no document paths are
/// hardcoded into the repository.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/check_epub.dart <file.epub> [...]');
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
      await _checkEpub(path);
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

Future<void> _checkEpub(String path) async {
  stdout.writeln('=== $path ===');
  final reader = await EpubDocumentReader.fromFile(path);
  try {
    stdout.writeln('  format:        ${reader.format}');
    stdout.writeln('  isReflowable:  ${reader.isReflowable}');
    stdout.writeln('  title:         ${reader.title}');

    final meta = reader.metadata;
    if (meta != null) {
      stdout.writeln('  creator:       ${meta.creator}');
      stdout.writeln('  language:      ${meta.language}');
      stdout.writeln('  identifier:    ${meta.identifier}');
      stdout.writeln('  publisher:     ${meta.publisher}');
      stdout.writeln('  modified:      ${meta.modified}');
    } else {
      stdout.writeln('  metadata:      <none>');
    }

    final sections = reader.sections;
    stdout.writeln('  sections:      ${reader.sectionCount}');
    final preview = sections.take(3).map((s) => s.title ?? s.href).toList();
    stdout.writeln('  first sections: $preview');

    // Load HTML for first, middle, and last sections.
    final indices = <int>{
      0,
      if (sections.length > 1) sections.length ~/ 2,
      if (sections.length > 1) sections.length - 1,
    };
    for (final i in indices) {
      final html = reader.loadSectionHtml(i);
      stdout.writeln('  section[$i] html: ${html.length} chars');
    }

    // Asset resolution + loading (first section's directory).
    if (sections.isNotEmpty) {
      final first = sections.first;
      final dir = first.href.contains('/')
          ? first.href.substring(0, first.href.lastIndexOf('/') + 1)
          : '';
      final resolved = reader.resolveAssetPath(0, '${dir}cover.jpg');
      final asset = reader.loadAsset(resolved);
      stdout.writeln(
        '  asset cover.jpg: ${asset == null ? 'missing' : '${asset.length} bytes'}',
      );
    }

    // Outline / TOC.
    final outline = reader.outline;
    final flat = outline.expand((o) => o.flatten()).toList();
    stdout.writeln(
      '  outline:       ${outline.length} top-level, ${flat.length} total',
    );
    for (final o in outline.take(5)) {
      stdout.writeln('    - ${o.title} (${o.href ?? 'no href'})');
    }

    // Internal link resolution.
    if (sections.isNotEmpty) {
      final target = sections.first.href;
      final resolvedIndex = reader.resolveSectionIndex(target);
      stdout.writeln('  resolveSectionIndex($target) -> $resolvedIndex');
    }
  } finally {
    reader.dispose();
  }
  stdout.writeln();
}
