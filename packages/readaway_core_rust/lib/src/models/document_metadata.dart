/// Bibliographic metadata for a document.
class DocumentMetadata {
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
  })  : author = author ?? creator,
        creator = creator ?? author;

  @override
  String toString() =>
      'DocumentMetadata(title: $title, author: $author, cover: $coverImagePath)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentMetadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          author == other.author &&
          identifier == other.identifier;

  @override
  int get hashCode => title.hashCode ^ author.hashCode ^ identifier.hashCode;
}
