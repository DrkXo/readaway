import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

/// Builds an in-memory CBZ for tests using `package:archive` and
/// `package:image`.
class CbzFixture {
  const CbzFixture._();

  /// Builds a CBZ with [pageNames] image entries plus a `ComicInfo.xml`.
  static Uint8List build({
    List<String> pageNames = const ['page1.png', 'page2.png', 'page10.png'],
    int width = 4,
    int height = 4,
  }) {
    final archive = Archive();
    for (final name in pageNames) {
      archive.addFile(ArchiveFile.bytes(name, _png(width, height)));
    }
    archive.addFile(
      ArchiveFile.string('ComicInfo.xml', '<ComicInfo></ComicInfo>'),
    );
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// A tiny solid-color PNG.
  static Uint8List _png(int width, int height) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(255, 0, 0));
    return Uint8List.fromList(img.encodePng(image));
  }
}
