import 'dart:typed_data';
import '../rust/api/document.dart' as doc_api;
import '../rust/api/models.dart';

/// Fast EPUB reader backed by `rbook` in native Rust.
class RustEpubReader {
  final String path;

  const RustEpubReader(this.path);

  /// Retrieves book metadata (title, author, publisher, etc.).
  Future<RustDocumentMetadata> getMetadata() =>
      doc_api.getEpubMetadata(path: path);

  /// Returns the number of sections (spine items).
  Future<int> getSectionCount() async {
    final count = await doc_api.getEpubSectionCount(path: path);
    return count.toInt();
  }

  /// Reads the XHTML/HTML string for a given spine section index.
  Future<String> readSectionHtml(int sectionIndex) =>
      doc_api.readEpubSection(
        path: path,
        sectionIndex: BigInt.from(sectionIndex),
      );

  /// Reads an asset (image, stylesheet, font) from inside the EPUB archive.
  Future<Uint8List> readAsset(String assetPath) =>
      doc_api.readEpubResource(path: path, resourcePath: assetPath);
}
