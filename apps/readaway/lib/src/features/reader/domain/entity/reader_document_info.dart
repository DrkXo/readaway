import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mupdf/mupdf.dart';

part 'reader_document_info.freezed.dart';

/// Metadata, structure, and navigation outline for an opened reader document.
@freezed
abstract class ReaderDocumentInfo with _$ReaderDocumentInfo {
  const factory ReaderDocumentInfo({
    required String path,
    required String title,
    required int pageCount,
    required bool isReflowable,
    required List<OutlineItem> outline,
  }) = _ReaderDocumentInfo;
}
