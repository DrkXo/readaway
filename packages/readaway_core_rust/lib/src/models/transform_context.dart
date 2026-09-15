/// Context passed into [TextTransformer]s containing the HTML/text content
/// and reader display settings.
class TransformContext {
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

  TransformContext copyWith({
    String? content,
    String? language,
    bool? vertical,
    bool? replaceQuotationMarks,
    String? convertChineseVariant,
    bool? overrideLayout,
    Map<String, dynamic>? extra,
  }) {
    return TransformContext(
      content: content ?? this.content,
      language: language ?? this.language,
      vertical: vertical ?? this.vertical,
      replaceQuotationMarks:
          replaceQuotationMarks ?? this.replaceQuotationMarks,
      convertChineseVariant:
          convertChineseVariant ?? this.convertChineseVariant,
      overrideLayout: overrideLayout ?? this.overrideLayout,
      extra: extra ?? this.extra,
    );
  }

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
}
