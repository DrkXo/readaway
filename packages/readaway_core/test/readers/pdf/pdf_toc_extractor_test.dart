import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';

/// Dynamically resolves a PDF file path from environment variables,
/// dart-defines, or standard user directories.
String? _resolveDynamicPdfPath() {
  const envKeys = [
    'TEST_TOC_PDF_PATH',
    'TEST_PDF_PATH',
    'PDF_PATH',
    'TEST_DOCUMENT_PATH',
  ];

  for (final key in envKeys) {
    final envVal = Platform.environment[key];
    if (envVal != null && envVal.isNotEmpty && File(envVal).existsSync()) {
      return envVal;
    }

    final defineVal = String.fromEnvironment(key);
    if (defineVal.isNotEmpty && File(defineVal).existsSync()) {
      return defineVal;
    }
  }

  // Fallback discovery in user's standard directories
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    final candidateDirs = [
      p.join(home, 'Documents', 'Ebooks'),
      p.join(home, 'Documents'),
      p.join(home, 'Downloads'),
    ];

    for (final dirPath in candidateDirs) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        final specificCandidate = File(
          p.join(dirPath, 'The-Collected-Works-of-HP-Lovecraft.pdf'),
        );
        if (specificCandidate.existsSync()) {
          return specificCandidate.path;
        }

        try {
          final firstPdf = dir
              .listSync()
              .whereType<File>()
              .where((f) => p.extension(f.path).toLowerCase() == '.pdf')
              .firstOrNull;
          if (firstPdf != null) {
            return firstPdf.path;
          }
        } catch (_) {}
      }
    }
  }

  return null;
}

void main() {
  group('PdfTocExtractor & Dynamic PDF Outline Tests', () {
    final dynamicPdfPath = _resolveDynamicPdfPath();
    final hasPdf = dynamicPdfPath != null && File(dynamicPdfPath).existsSync();

    test(
      'Extracts outline and validates TOC navigation on dynamic PDF',
      () async {
        final path = dynamicPdfPath!;
        final reader = await PdfDocumentReader.open(path);

        try {
          expect(reader.format, 'pdf');
          expect(reader.isReflowable, isFalse);
          expect(reader.pageCount, greaterThan(0));

          final outline = reader.outline;
          expect(
            outline,
            isNotEmpty,
            reason: 'Extracted outline should not be empty for $path',
          );

          // Verify every top-level outline item is well-formed
          for (final item in outline) {
            expect(item.title, isNotEmpty);
            expect(item.level, 0);

            if (item.chapterIndex != null) {
              expect(item.chapterIndex!, greaterThanOrEqualTo(0));
              expect(item.chapterIndex!, lessThan(reader.pageCount));
              expect(item.href, 'page:${item.chapterIndex}');
            }

            // Verify children if present
            for (final child in item.children) {
              expect(child.title, isNotEmpty);
              expect(child.level, 1);
              if (child.chapterIndex != null) {
                expect(child.chapterIndex!, greaterThanOrEqualTo(0));
                expect(child.chapterIndex!, lessThan(reader.pageCount));
                expect(child.href, 'page:${child.chapterIndex}');
              }
            }
          }

          // If the file is the HP Lovecraft collection, verify specific parsed chapters
          if (path.contains('Lovecraft')) {
            expect(outline.length, greaterThan(100));

            final first = outline.first;
            expect(first.title, contains('Notes On Writing Weird Fiction'));
            expect(first.chapterIndex, 11);

            final second = outline[1];
            expect(second.title, contains('History of the Necronomicon'));
            expect(second.chapterIndex, 15);

            final horrorInMuseum = outline
                .where((i) => i.title.contains('The Horror in the Museum'))
                .firstOrNull;
            expect(horrorInMuseum, isNotNull);
            expect(horrorInMuseum!.children.length, 2);
            expect(horrorInMuseum.children[0].title, '1');
            expect(horrorInMuseum.children[0].chapterIndex, 613);
            expect(horrorInMuseum.children[1].title, '2');
            expect(horrorInMuseum.children[1].chapterIndex, 624);
          }
        } finally {
          await reader.dispose();
        }
      },
      skip: !hasPdf
          ? 'No PDF file found (pass TEST_TOC_PDF_PATH or TEST_PDF_PATH to enable)'
          : null,
    );

    test(
      'IsolateDocumentSession extracts outline on dynamic PDF',
      () async {
        final path = dynamicPdfPath!;
        final session = await IsolateDocumentSession.open(path);

        try {
          expect(session.format, 'pdf');
          expect(session.isReflowable, isFalse);
          expect(session.pageCount, greaterThan(0));

          final outline = session.outline;
          expect(
            outline,
            isNotEmpty,
            reason: 'Session outline should not be empty for $path',
          );

          final first = outline.first;
          expect(first.title, isNotEmpty);
          if (first.chapterIndex != null) {
            expect(first.chapterIndex!, greaterThanOrEqualTo(0));
            expect(first.chapterIndex!, lessThan(session.pageCount));
          }
        } finally {
          await session.dispose();
        }
      },
      skip: !hasPdf
          ? 'No PDF file found (pass TEST_TOC_PDF_PATH or TEST_PDF_PATH to enable)'
          : null,
    );
  });
}
