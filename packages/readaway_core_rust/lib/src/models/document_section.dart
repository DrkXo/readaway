import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'document_section.g.dart';

/// A discrete reading section (chapter or spine item) within a reflowable document.
@CopyWith()
class DocumentSection extends Equatable {
  final String id;
  final int index;
  final String href;
  final String? title;

  const DocumentSection({
    required this.id,
    required this.index,
    required this.href,
    this.title,
  });

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [id, index, href];
}
