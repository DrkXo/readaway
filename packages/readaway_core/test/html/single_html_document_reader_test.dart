import 'dart:io';
import 'dart:typed_data';

import 'package:readaway_core/readaway_core.dart';
import 'package:test/test.dart';

void main() {
  group('SingleHtmlDocumentReader', () {
    late Directory tempDir;
    late File htmlFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('readaway_core_html_');
      htmlFile = File('${tempDir.path}/sample.html')
        ..writeAsStringSync('''
<!DOCTYPE html>
<html>
  <head><title>Sample Page</title></head>
  <body>
    <h1>Hello</h1>
    <p>Some <b>bold</b> text.</p>
    <img src="images/pic.png"/>
  </body>
</html>
''');
      Directory('${tempDir.path}/images').createSync();
      File(
        '${tempDir.path}/images/pic.png',
      ).writeAsBytesSync(Uint8List.fromList([9, 8, 7]));
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('opens a standalone HTML file', () async {
      final reader = await SingleHtmlDocumentReader.fromFile(htmlFile.path);

      expect(reader.format, 'html');
      expect(reader.isReflowable, isTrue);
      expect(reader.title, 'Sample Page');
      expect(reader.sectionCount, 1);
      expect(reader.sections[0].mediaType, 'text/html');

      reader.dispose();
    });

    test('loads the single section HTML', () async {
      final reader = await SingleHtmlDocumentReader.fromFile(htmlFile.path);

      final html = reader.loadSectionHtml(0);
      expect(html, contains('<h1>Hello</h1>'));

      expect(() => reader.loadSectionHtml(1), throwsRangeError);

      reader.dispose();
    });

    test('resolves and loads assets from the file directory', () async {
      final reader = await SingleHtmlDocumentReader.fromFile(htmlFile.path);

      final resolved = reader.resolveAssetPath(0, 'images/pic.png');
      expect(resolved, endsWith('images/pic.png'));

      final asset = reader.loadAsset('images/pic.png');
      expect(asset, isNotNull);
      expect(asset, equals(Uint8List.fromList([9, 8, 7])));

      expect(reader.loadAsset('missing.png'), isNull);

      reader.dispose();
    });

    test('resolves the section index for the file itself', () async {
      final reader = await SingleHtmlDocumentReader.fromFile(htmlFile.path);

      expect(reader.resolveSectionIndex('sample.html'), 0);
      expect(reader.resolveSectionIndex('other.html'), isNull);

      reader.dispose();
    });
  });
}
