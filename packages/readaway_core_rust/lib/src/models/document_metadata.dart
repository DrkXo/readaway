import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'document_metadata.g.dart';

/// Bibliographic metadata for a document.
@CopyWith(constructor: '_')
class DocumentMetadata extends Equatable {
  final String? title;
  final String? author;
  final String? creator;
  final String? language;
  final String? identifier;
  final String? publisher;
  final String? description;
  final String? coverImagePath;

  const DocumentMetadata({
    this.title,
    String? author,
    String? creator,
    this.language,
    this.identifier,
    this.publisher,
    this.description,
    this.coverImagePath,
  }) : author = author ?? creator,
       creator = creator ?? author;

  /// Private constructor used by the generated `copyWith` extension so that
  /// `author` and `creator` are copied independently (the public constructor
  /// cross-normalizes them).
  const DocumentMetadata._({
    this.title,
    this.author,
    this.creator,
    this.language,
    this.identifier,
    this.publisher,
    this.description,
    this.coverImagePath,
  });

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [title, author, identifier];
}
