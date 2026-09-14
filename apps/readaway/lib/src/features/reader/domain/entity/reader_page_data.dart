import 'package:freezed_annotation/freezed_annotation.dart';

import 'reader_link.dart';

part 'reader_page_data.freezed.dart';

/// Loaded page content, interactive links, and rendering metadata for a single reader page.
@freezed
abstract class ReaderPageData with _$ReaderPageData {
  const factory ReaderPageData({
    required int pageIndex,
    @Default([]) List<ReaderLink> links,
    Map<String, dynamic>? renderedData,
    String? html,
  }) = _ReaderPageData;
}
