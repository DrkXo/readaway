import 'dart:typed_data';

import '../../error/exceptions/tts_exceptions.dart';

export '../../error/exceptions/tts_exceptions.dart';

enum TtsEngineKind { sherpaOnnx }

class TtsVoiceOption {
  const TtsVoiceOption({
    required this.engine,
    required this.id,
    required this.label,
    this.languageCode,
    this.sherpaSpeakerId,
  });

  final TtsEngineKind engine;
  final String id;
  final String label;
  final String? languageCode;
  final int? sherpaSpeakerId;
}

enum TtsPlaybackState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  completed,
  error,
}

class TtsPlaybackEvent {
  const TtsPlaybackEvent(this.state, {this.message});
  final TtsPlaybackState state;
  final String? message;
}

enum SherpaTtsModelType { vits, matcha, kokoro }

class SherpaTtsModelInfo {
  const SherpaTtsModelInfo({
    required this.id,
    required this.displayName,
    required this.languageCode,
    required this.languageLabel,
    required this.type,
    required this.downloadUrl,
    required this.approxSizeMb,
    this.isMultiSpeaker = false,
    this.speakerCount = 0,
    this.description = '',
    this.sampleRateHint = 22050,
    this.vocoderUrl,
    this.needsEspeakData = false,
  });

  final String id;
  final String displayName;
  final String languageCode;
  final String languageLabel;
  final SherpaTtsModelType type;
  final String downloadUrl;
  final double approxSizeMb;
  final bool isMultiSpeaker;
  final int speakerCount;
  final String description;
  final int sampleRateHint;
  final String? vocoderUrl;
  final bool needsEspeakData;

  String get archiveFileName => downloadUrl.split('/').last;
  String? get vocoderFileName => vocoderUrl?.split('/').last;

  @override
  String toString() => 'SherpaTtsModelInfo($id, $displayName, $type)';
}

class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.modelId,
    required this.stage,
    required this.fraction,
  });

  final String modelId;
  final ModelDownloadStage stage;
  final double fraction;
}

enum ModelDownloadStage { downloading, extracting, done, failed }

class TtsAudio {
  const TtsAudio({
    required this.samples,
    required this.sampleRate,
    this.chunkId,
  });

  final Float32List samples;
  final int sampleRate;
  final String? chunkId;

  double get durationInSeconds => samples.length / sampleRate;
}

class SherpaTtsSpeaker {
  const SherpaTtsSpeaker({required this.id, required this.label});
  final int id;
  final String label;
}

/// Kept for backward compatibility, extends [TtsException].
class SherpaTtsException extends TtsException {
  const SherpaTtsException(super.message, [super.cause]);
}
