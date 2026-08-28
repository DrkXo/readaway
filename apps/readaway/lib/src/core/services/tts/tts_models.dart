part of '../services.dart';

enum TtsEngineKind { sherpaOnnx }

/// One selectable voice, regardless of which engine it comes from.
class TtsVoiceOption {
  const TtsVoiceOption({
    required this.engine,
    required this.id,
    required this.label,
    this.languageCode,
    this.sherpaSpeakerId,
  });

  final TtsEngineKind engine;

  /// For [TtsEngineKind.sherpaOnnx]: the model id (see [SherpaTtsModelInfo.id]).
  final String id;

  final String label;
  final String? languageCode;

  /// Only meaningful for sherpa-onnx multi-speaker models
  /// (e.g. Kokoro speaker index). Null / 0 for single-speaker models.
  final int? sherpaSpeakerId;
}

enum TtsPlaybackState { idle, loading, playing, paused, stopped, error }

class TtsPlaybackEvent {
  const TtsPlaybackEvent(this.state, {this.message});
  final TtsPlaybackState state;
  final String? message;
}
