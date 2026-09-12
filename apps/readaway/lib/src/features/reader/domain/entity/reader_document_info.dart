import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:readaway_core/readaway_core.dart';

part 'reader_document_info.freezed.dart';

/// Metadata, structure, and navigation outline for an opened reader document.
@freezed
abstract class ReaderDocumentInfo with _$ReaderDocumentInfo {
  const factory ReaderDocumentInfo({
    required String path,
    required String title,
    required int pageCount,
    required List<OutlineItem> outline,
  }) = _ReaderDocumentInfo;
}
