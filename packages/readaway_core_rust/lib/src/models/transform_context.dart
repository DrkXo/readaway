part of 'models.dart';

/// Context passed into [TextTransformer]s containing the HTML/text content
/// and reader display settings.
@freezed
sealed class TransformContext with _$TransformContext {
  const factory TransformContext({
    required String content,
    String? language,
    @Default(false) bool vertical,
    @Default(false) bool replaceQuotationMarks,
    String? convertChineseVariant,
    @Default(false) bool overrideLayout,
    @Default(<String, dynamic>{}) Map<String, dynamic> extra,
  }) = _TransformContext;

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

  @override
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
}
