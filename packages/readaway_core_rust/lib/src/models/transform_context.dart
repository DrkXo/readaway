import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';

part 'transform_context.g.dart';

/// Context passed into [TextTransformer]s containing the HTML/text content
/// and reader display settings.
@CopyWith()
class TransformContext extends Equatable {
  final String content;
  final String? language;
  final bool vertical;
  final bool replaceQuotationMarks;
  final String? convertChineseVariant;
  final bool overrideLayout;
  final Map<String, dynamic> extra;

  const TransformContext({
    required this.content,
    this.language,
    this.vertical = false,
    this.replaceQuotationMarks = false,
    this.convertChineseVariant,
    this.overrideLayout = false,
    this.extra = const {},
  });

  factory TransformContext.fromJson(Map<String, dynamic> json) =>
      TransformContext(
        content: json['content'] as String? ?? '',
        language: json['language'] as String?,
        vertical: json['vertical'] as bool? ?? false,
        replaceQuotationMarks: json['replaceQuotationMarks'] as bool? ?? false,
        convertChineseVariant: json['convertChineseVariant'] as String?,
        overrideLayout: json['overrideLayout'] as bool? ?? false,
        extra: (json['extra'] as Map<String, dynamic>?) ?? const {},
      );

  Map<String, dynamic> toJson() => {
    'content': content,
    if (language != null) 'language': language,
    'vertical': vertical,
    'replaceQuotationMarks': replaceQuotationMarks,
    if (convertChineseVariant != null)
      'convertChineseVariant': convertChineseVariant,
    'overrideLayout': overrideLayout,
    'extra': extra,
  };

  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [
    content,
    language,
    vertical,
    replaceQuotationMarks,
    convertChineseVariant,
    overrideLayout,
    extra,
  ];
}
