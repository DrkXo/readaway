part of 'models.dart';

/// A discrete reading section (chapter or spine item) within a reflowable document.
@freezed
sealed class DocumentSection with _$DocumentSection {
  const factory DocumentSection({
    required String id,
    required int index,
    required String href,
    String? title,
  }) = _DocumentSection;
}
