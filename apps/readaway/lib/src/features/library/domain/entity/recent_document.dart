import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_document.freezed.dart';
part 'recent_document.g.dart';

/// Represents a document stored in the user's local reading history / library.
@freezed
abstract class RecentDocument with _$RecentDocument {
  const factory RecentDocument({
    required String path,
    required String fileName,
    @Default(0) int lastReadPage,
    @Default(0) int pageCount,
    required DateTime lastOpened,
    String? coverPath,
  }) = _RecentDocument;

  factory RecentDocument.fromJson(Map<String, dynamic> json) =>
      _$RecentDocumentFromJson(json);
}
