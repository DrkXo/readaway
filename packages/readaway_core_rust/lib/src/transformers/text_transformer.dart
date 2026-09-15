import '../models/transform_context.dart';

/// Abstract contract for modular HTML and text transformers.
abstract interface class TextTransformer {
  /// Unique identifier of this transformer (e.g. 'nbsp', 'punctuation', 'footnote').
  String get name;

  /// Transforms the input content provided in [context] and returns the transformed string.
  String transform(TransformContext context);
}
