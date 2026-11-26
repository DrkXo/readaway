import 'package:equatable/equatable.dart';

/// Context provided to translation engines (especially LLMs) to improve
/// literary translation accuracy, style, and character consistency.
class TranslationContext extends Equatable {
  const TranslationContext({
    this.bookTitle,
    this.bookAuthor,
    this.chapterTitle,
    this.chapterIndex,
    this.promptId,
  });

  final String? bookTitle;
  final String? bookAuthor;
  final String? chapterTitle;
  final int? chapterIndex;
  final String? promptId;

  @override
  List<Object?> get props => [
    bookTitle,
    bookAuthor,
    chapterTitle,
    chapterIndex,
    promptId,
  ];
}
