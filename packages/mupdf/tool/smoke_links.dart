// Smoke test for direct MuPDF link extraction (MuPdfDocument.pageLinks).
//
// Requires a wrapper build with MuPDF symbols exported (the hook links
// --whole-archive, so fz_* symbols are present) and LD_LIBRARY_PATH pointing
// at it. Generates its own 2-page PDF containing one internal GoTo link and
// one external URI link.
//
//   cd packages/mupdf
//   LD_LIBRARY_PATH=native/mupdf/build/release dart run tool/smoke_links.dart
import 'dart:convert';
import 'dart:io';

import 'package:mupdf/mupdf.dart';

// ignore_for_file: avoid_print
void main() {
  final pdf = File('${Directory.systemTemp.path}/mupdf_linktest.pdf');
  pdf.writeAsBytesSync(_buildTwoPagePdfWithLinks());

  final doc = MuPdfDocument.openFile(pdf.path);
  try {
    final links = doc.pageLinks(0);
    print('found ${links.length} link(s) on page 0');
    for (final l in links) {
      print('  uri=${l.uri} page=${l.pageNumber} '
          'rect=(${l.x0},${l.y0},${l.x1},${l.y1})');
    }

    assert(links.length == 2, 'expected 2 links');
    final internal = links.where((l) => l.isInternal).toList();
    assert(internal.length == 1, 'one internal link');
    assert(internal.single.pageNumber == 1,
        'GoTo dest resolves to flat page index 1');
    assert(internal.single.y0 == 600 && internal.single.y1 == 640,
        'rect matches the /Dest annot');

    final external = links.where((l) => !l.isInternal).toList();
    assert(external.length == 1, 'one external link');
    assert(external.single.uri == 'https://example.com', 'uri preserved');

    // Page without annotations returns empty.
    assert(doc.pageLinks(1).isEmpty, 'page 1 has no links');
  } finally {
    doc.dispose();
    pdf.deleteSync();
  }
  stdout.writeln('ALL PASSED');
}

/// Minimal PDF 1.4: two pages; page 0 carries a GoTo link annot targeting
/// page 1 and a URI annot.
List<int> _buildTwoPagePdfWithLinks() {
  String obj(int num, String body) => '$num 0 obj\n$body\nendobj\n';

  final objects = <String>[
    obj(1, '<< /Type /Catalog /Pages 2 0 R >>'),
    obj(2, '<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>'),
    obj(
      3,
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents 5 0 R /Annots [6 0 R 7 0 R] '
      '/Resources << /Font << /F1 8 0 R >> >> >>',
    ),
    obj(
      4,
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
      '/Contents 9 0 R /Resources << /Font << /F1 8 0 R >> >> >>',
    ),
    obj(5, _stream('BT /F1 24 Tf 72 700 Td (Target Page) Tj ET')),
    obj(
      6,
      '<< /Type /Annot /Subtype /Link /Rect [72 600 300 640] '
      '/Border [0 0 0] /Dest [4 0 R /XYZ 0 792 null] >>',
    ),
    obj(
      7,
      '<< /Type /Annot /Subtype /Link /Rect [72 500 250 540] '
      '/Border [0 0 0] /A << /S /URI /URI (https://example.com) >> >>',
    ),
    obj(8, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'),
    obj(9, _stream('BT /F1 24 Tf 72 700 Td (Second Page) Tj ET')),
  ];

  final out = StringBuffer('%PDF-1.4\n');
  final offsets = <int, int>{};
  for (var i = 0; i < objects.length; i++) {
    offsets[i + 1] = out.length;
    out.write(objects[i]);
  }
  final xrefPos = out.length;
  final count = objects.length + 1;
  out.write('xref\n0 $count\n0000000000 65535 f \n');
  for (var n = 1; n < count; n++) {
    out.write('${offsets[n]!.toString().padLeft(10, '0')} 00000 n \n');
  }
  out.write('trailer\n<< /Size $count /Root 1 0 R >>\n'
      'startxref\n$xrefPos\n%%EOF\n');
  return latin1.encode(out.toString());
}

String _stream(String content) =>
    '<< /Length ${content.length} >>\nstream\n$content\nendstream';
