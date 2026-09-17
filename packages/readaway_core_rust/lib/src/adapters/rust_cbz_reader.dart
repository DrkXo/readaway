import 'dart:typed_data';
import '../rust/api/document.dart' as doc_api;

/// High-performance CBZ comic reader with natural alphanumeric sorting.
class RustCbzReader {
  final String path;

  const RustCbzReader(this.path);

  /// Returns total page count in the CBZ comic archive.
  Future<int> getPageCount() async {
    final count = await doc_api.getCbzPageCount(path: path);
    return count.toInt();
  }

  /// Reads the image bytes for a given page index.
  Future<Uint8List> readPageImage(int pageIndex) =>
      doc_api.readCbzPageImage(
        path: path,
        pageIndex: BigInt.from(pageIndex),
      );
}
