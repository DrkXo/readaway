import 'package:freezed_annotation/freezed_annotation.dart';

import 'reading_status.dart';

part 'recent_document.freezed.dart';
part 'recent_document.g.dart';

/// Represents a document stored in the user's library.
@freezed
abstract class RecentDocument with _$RecentDocument {
  const RecentDocument._();

  const factory RecentDocument({
    required String path,
    required String fileName,
    required String title,
    String? author,
    required DateTime dateAdded,
    required DateTime lastOpened,
    required int fileSize,
    required String format,
    @Default(0) int lastReadPage,
    @Default(0) int pageCount,
    @Default(ReadingStatus.unread) ReadingStatus readingStatus,
    @Default(false) bool isFavorite,
    @Default([]) List<String> tags,
    String? coverPath,
  }) = _RecentDocument;

  factory RecentDocument.fromJson(Map<String, dynamic> json) =>
      _$RecentDocumentFromJson(json);

  String get displayTitle =>
      title.trim().isNotEmpty ? title.trim() : fileName;

  String? get displayAuthor =>
      (author != null && author!.trim().isNotEmpty) ? author!.trim() : null;

  double get progressPercent {
    if (pageCount <= 0) return 0.0;
    return ((lastReadPage + 1) / pageCount).clamp(0.0, 1.0);
  }

  String get progressFormatted =>
      '${(progressPercent * 100).toInt()}%';

  bool get isFinished =>
      readingStatus == ReadingStatus.finished ||
      (pageCount > 0 && lastReadPage >= pageCount - 1);

  String get formattedFileSize {
    if (fileSize <= 0) return '';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = fileSize.toDouble();
    var suffixIndex = 0;
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    return '${size.toStringAsFixed(suffixIndex == 0 ? 0 : 1)} ${suffixes[suffixIndex]}';
  }

  String get formatBadge => format.toUpperCase();
}
