import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:readaway_core_rust/readaway_core_rust.dart';

part 'reader_document_info.freezed.dart';

/// Metadata, structure, and navigation outline for an opened reader document.
@freezed
abstract class ReaderDocumentInfo with _$ReaderDocumentInfo {
  const factory ReaderDocumentInfo({
    required String path,
    required String title,
    String? author,
    required int pageCount,
    required List<OutlineItem> outline,
  }) = _ReaderDocumentInfo;
}
