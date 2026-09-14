part of 'models.dart';

/// Context passed into [TextTransformer]s containing the HTML/text content
/// and reader display settings.
@freezed
abstract class TransformContext with _$TransformContext {
  const factory TransformContext({
    /// The HTML or text content to be transformed.
    required String content,

    /// BCP-47 language tag (e.g. 'en', 'ru', 'zh-Hans', 'ja').
    String? language,

    /// Whether the reading layout is vertical (top-to-bottom, right-to-left).
    @Default(false) bool vertical,

    /// Whether to replace and adapt quotation marks.
    @Default(false) bool replaceQuotationMarks,

    /// Variant translation for Chinese text: 's2t' (Simplified to Traditional),
    /// 't2s' (Traditional to Simplified), or null.
    String? convertChineseVariant,

    /// Whether the user layout override is enabled.
    @Default(false) bool overrideLayout,

    /// Optional extra parameters for specialized transformers.
    @Default(<String, dynamic>{}) Map<String, dynamic> extra,
  }) = _TransformContext;

  factory TransformContext.fromJson(Map<String, dynamic> json) =>
      _$TransformContextFromJson(json);
}
