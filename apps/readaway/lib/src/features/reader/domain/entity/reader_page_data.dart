import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/models/reader/reader_document.dart';
import 'reader_link.dart';

part 'reader_page_data.freezed.dart';

/// Loaded content, AST document, interactive links, and rendering metadata for a single reader page.
@freezed
abstract class ReaderPageData with _$ReaderPageData {
  const factory ReaderPageData({
    required int pageIndex,
    ReaderDocument? document,
    @Default([]) List<ReaderLink> links,
    Map<String, dynamic>? renderedData,
  }) = _ReaderPageData;
}
