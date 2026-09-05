import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_lookup.freezed.dart';

enum ReaderLookupKind { dictionary, translate }

@freezed
abstract class ReaderLookupRequest with _$ReaderLookupRequest {
  const factory ReaderLookupRequest({
    required ReaderLookupKind kind,
    required String text,
  }) = _ReaderLookupRequest;
}
