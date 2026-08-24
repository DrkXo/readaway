part of '../services.dart';

enum TtsEngineKind { device, sherpaOnnx }

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

  /// For [TtsEngineKind.device]: the OS voice name/identifier.
  /// For [TtsEngineKind.sherpaOnnx]: the model id (see [SherpaTtsModelInfo.id]).
  final String id;

  final String label;
  final String? languageCode;

  /// Only meaningful for sherpa-onnx multi-speaker models
  /// (e.g. Kokoro speaker index). Null / 0 for single-speaker models and
  /// for device voices.
  final int? sherpaSpeakerId;
}

enum TtsPlaybackState { idle, loading, playing, paused, stopped, error }

class TtsPlaybackEvent {
  const TtsPlaybackEvent(this.state, {this.message});
  final TtsPlaybackState state;
  final String? message;
}
