class TtsException implements Exception {
  final String message;
  final Object? cause;

  const TtsException(this.message, [this.cause]);

  @override
  String toString() =>
      cause != null
          ? 'TtsException: $message (caused by: $cause)'
          : 'TtsException: $message';
}

class TtsModelNotLoadedException extends TtsException {
  const TtsModelNotLoadedException([super.message = 'No model loaded.']);
}

class TtsSynthesisException extends TtsException {
  const TtsSynthesisException(super.message, [super.cause]);
}

class TtsModelDownloadException extends TtsException {
  const TtsModelDownloadException(super.message, [super.cause]);
}

class ChunkingException implements Exception {
  final String message;
  final Object? cause;

  const ChunkingException(this.message, [this.cause]);

  @override
  String toString() =>
      cause != null
          ? 'ChunkingException: $message (caused by: $cause)'
          : 'ChunkingException: $message';
}
