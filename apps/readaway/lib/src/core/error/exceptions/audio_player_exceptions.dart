class AudioPlayerException implements Exception {
  final String message;
  final Object? cause;

  const AudioPlayerException(this.message, [this.cause]);

  @override
  String toString() =>
      cause != null
          ? 'AudioPlayerException: $message (caused by: $cause)'
          : 'AudioPlayerException: $message';
}

class AudioPlaybackException extends AudioPlayerException {
  const AudioPlaybackException(super.message, [super.cause]);
}

class AudioDeviceException extends AudioPlayerException {
  const AudioDeviceException(super.message, [super.cause]);
}
