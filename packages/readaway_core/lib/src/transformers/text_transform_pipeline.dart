import '../models/models.dart';
import 'bidi_sanitizer_transformer.dart';
import 'footnote_transformer.dart';
import 'html_cleanup_transformer.dart';
import 'nbsp_transformer.dart';
import 'punctuation_transformer.dart';
import 'text_transformer.dart';
import 'whitespace_transformer.dart';

/// Callback for reporting transformer exceptions during pipeline execution.
typedef TransformerErrorCallback = void Function(
  TextTransformer transformer,
  Object error,
  StackTrace stackTrace,
);

/// Executes a sequential chain of [TextTransformer]s across document text or HTML.
class TextTransformPipeline {
  final List<TextTransformer> transformers;
  final TransformerErrorCallback? onError;

  const TextTransformPipeline({
    required this.transformers,
    this.onError,
  });

  /// Standard natural reading pipeline including BiDi repair, whitespace collapse,
  /// quotation rotation, footnote tagging, hanging preposition glue, and HTML cleanup.
  static const TextTransformPipeline defaultPipeline = TextTransformPipeline(
    transformers: [
      HtmlCleanupTransformer(),
      BidiSanitizerTransformer(),
      WhitespaceTransformer(),
      PunctuationTransformer(),
      FootnoteTransformer(),
      NbspTransformer(),
    ],
  );

  /// Executes all active transformers sequentially on [context].
  String transform(TransformContext context) {
    var currentContent = context.content;

    for (final transformer in transformers) {
      try {
        final stepContext = context.copyWith(content: currentContent);
        currentContent = transformer.transform(stepContext);
      } catch (error, stackTrace) {
        onError?.call(transformer, error, stackTrace);
      }
    }

    return currentContent;
  }
}
