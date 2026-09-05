import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_link.freezed.dart';

/// Pure domain representation of an interactive hyperlink or internal page link.
@freezed
abstract class ReaderLink with _$ReaderLink {
  const ReaderLink._();

  const factory ReaderLink({
    required double x0,
    required double y0,
    required double x1,
    required double y1,
    required String uri,
    required int pageNumber,
  }) = _ReaderLink;

  bool get isInternal => pageNumber >= 0;
}
