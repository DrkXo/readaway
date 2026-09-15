import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../error/exceptions/tts_exceptions.dart';

export '../../error/exceptions/tts_exceptions.dart';

part 'tts_models.freezed.dart';
part 'tts_models.g.dart';

enum TtsEngineKind {
  sherpaOnnx,
  deviceVoice,
  microsoftTts,
}

class TtsVoiceOption {
  const TtsVoiceOption({
    required this.engine,
    required this.id,
    required this.label,
    this.languageCode,
    this.sherpaSpeakerId,
    this.gender,
    this.quality,
    this.previewAudioUrl,
  });

  final TtsEngineKind engine;
  final String id;
  final String label;
  final String? languageCode;
  final int? sherpaSpeakerId;
  final String? gender;
  final String? quality;
  final String? previewAudioUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TtsVoiceOption &&
          runtimeType == other.runtimeType &&
          engine == other.engine &&
          id == other.id &&
          sherpaSpeakerId == other.sherpaSpeakerId;

  @override
  int get hashCode =>
      engine.hashCode ^ id.hashCode ^ (sherpaSpeakerId?.hashCode ?? 0);

  String get storageKey =>
      sherpaSpeakerId != null ? '$id@$sherpaSpeakerId' : id;

  bool matchesKey(String? key) {
    if (key == null || key.isEmpty) return false;
    if (key == storageKey) return true;
    if (key == id && (sherpaSpeakerId == null || sherpaSpeakerId == 0)) {
      return true;
    }
    return false;
  }

  @override
  String toString() => 'TtsVoiceOption($engine, $id, $label)';
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

enum SherpaTtsModelType {
  @JsonValue('vits')
  vits,
  @JsonValue('matcha')
  matcha,
  @JsonValue('kokoro')
  kokoro,
}

/// Model family, combining the id prefix used to strip it from a model id and
/// the human-readable label. Covers both the family prefixes found in asset
/// ids (piper-, coqui-, ...) and the type names used as the fallback family.
enum SherpaTtsModelFamily {
  @JsonValue('piper')
  piper('piper-', 'Piper'),
  @JsonValue('coqui')
  coqui('coqui-', 'Coqui'),
  @JsonValue('mimic3')
  mimic3('mimic3-', 'Mimic 3'),
  @JsonValue('mms')
  mms('mms-', 'MMS'),
  @JsonValue('icefall')
  icefall('icefall-', 'Icefall'),
  @JsonValue('tts')
  tts('tts-', 'TTS'),
  @JsonValue('melo')
  melo('melo-', 'MeloTTS'),
  @JsonValue('vits')
  vits('vits-', 'VITS'),
  @JsonValue('matcha')
  matcha('matcha-', 'Matcha'),
  @JsonValue('kokoro')
  kokoro('kokoro-', 'Kokoro');

  const SherpaTtsModelFamily(this.prefix, this.label);

  /// Prefix used to strip the family from a model id (e.g. 'piper-').
  final String prefix;

  /// Human-readable label (e.g. 'Piper').
  final String label;

  /// Family value without the trailing dash (e.g. 'piper') — what's persisted
  /// in the catalog JSON.
  String get value => prefix.substring(0, prefix.length - 1);
}

@freezed
abstract class SherpaTtsModelInfo with _$SherpaTtsModelInfo {
  const factory SherpaTtsModelInfo({
    required String id,
    required String displayName,
    required String languageCode,
    required String languageLabel,
    required SherpaTtsModelType type,
    required String downloadUrl,
    required double approxSizeMb,
    @Default(false) bool isMultiSpeaker,
    @Default(0) int speakerCount,
    @Default('') String description,
    @Default(22050) int sampleRateHint,
    String? vocoderUrl,
    @Default(false) bool needsEspeakData,
    String? previewAudioUrl,

    /// Model family derived from the asset id (e.g. 'piper', 'coqui',
    /// 'matcha', 'kokoro', 'vits'). Nullable so persisted catalogs written
    /// before this field existed still deserialize.
    SherpaTtsModelFamily? family,
  }) = _SherpaTtsModelInfo;

  factory SherpaTtsModelInfo.fromJson(Map<String, dynamic> json) =>
      _$SherpaTtsModelInfoFromJson(json);

  const SherpaTtsModelInfo._();

  String get archiveFileName => downloadUrl.split('/').last;
  String? get vocoderFileName => vocoderUrl?.split('/').last;

  /// Human-readable label for [family] (e.g. 'Piper'), derived from the enum.
  String? get familyLabel => family?.label;

  /// Parses a raw release asset into a model, or null when the asset is not
  /// a supported TTS model archive.
  static SherpaTtsModelInfo? fromAsset({
    required String name,
    required int sizeBytes,
    required String downloadUrl,
    required String hifiganUrl,
  }) {
    if (!name.endsWith('.tar.bz2')) return null;
    final id = name.substring(0, name.length - '.tar.bz2'.length);
    if (id.contains('-int8') || id.contains('-fp16') || id.contains('-fp32')) {
      return null;
    }

    final SherpaTtsModelType type;
    var rest = id;
    if (id.startsWith('vits-')) {
      type = SherpaTtsModelType.vits;
      rest = rest.substring(5);
    } else if (id.startsWith('matcha-')) {
      type = SherpaTtsModelType.matcha;
      rest = rest.substring(7);
    } else if (id.startsWith('kokoro-')) {
      type = SherpaTtsModelType.kokoro;
      rest = rest.substring(7);
    } else {
      return null;
    }
    if (_unsupportedEngines.contains(rest.split('-').first)) return null;

    SherpaTtsModelFamily? family;
    String langToken;
    String remainder;
    if (type == SherpaTtsModelType.kokoro) {
      langToken = rest.startsWith('multi-lang') ? 'multi' : 'en';
      remainder = rest;
    } else if (rest.startsWith('cantonese-')) {
      langToken = 'yue';
      remainder = rest.substring(10);
    } else {
      for (final f in SherpaTtsModelFamily.values) {
        if (rest.startsWith(f.prefix)) {
          family = f;
          rest = rest.substring(f.prefix.length);
          break;
        }
      }
      final m = _langRe.firstMatch(rest);
      if (m != null) {
        langToken = m.group(1)!;
        remainder = m.group(2) ?? '';
      } else {
        if (!RegExp(r'^[a-z0-9]+$').hasMatch(rest)) return null;
        langToken = 'en';
        remainder = rest;
      }
    }
    family ??= switch (type) {
      SherpaTtsModelType.vits => SherpaTtsModelFamily.vits,
      SherpaTtsModelType.matcha => SherpaTtsModelFamily.matcha,
      SherpaTtsModelType.kokoro => SherpaTtsModelFamily.kokoro,
    };

    final segments = remainder.split('-').where((s) => s.isNotEmpty).toList();
    String? quality;
    if (segments.length > 1 && _qualities.contains(segments.last)) {
      quality = segments.removeLast();
    }
    var displayName = segments.map((s) => s.titleCase).join(' ');
    if (displayName.isEmpty) {
      displayName = rest.replaceAll('_', ' ').titleCase;
    }
    if (quality != null) displayName += ' ($quality)';
    if (type == SherpaTtsModelType.kokoro) {
      final version = remainder.split('-').last.replaceFirst('_', '.');
      displayName = langToken == 'multi'
          ? 'Kokoro $version (multi-language)'
          : 'Kokoro $version';
    }

    final isKokoroMulti =
        type == SherpaTtsModelType.kokoro && langToken == 'multi';

    return SherpaTtsModelInfo(
      id: id,
      displayName: displayName,
      languageCode: langToken.replaceFirst('_', '-'),
      languageLabel: _langLabels[langToken.split('_').first] ?? langToken,
      type: type,
      family: family,
      downloadUrl: downloadUrl,
      approxSizeMb: sizeBytes / 1024 / 1024,
      isMultiSpeaker:
          isKokoroMulti || id.contains('vctk') || id.contains('aishell3'),
      speakerCount: isKokoroMulti ? 53 : 0,
      description: '',
      sampleRateHint: type == SherpaTtsModelType.kokoro
          ? 24000
          : (id.contains('-high') || id.contains('-medium'))
          ? 22050
          : 16000,
      vocoderUrl: type == SherpaTtsModelType.matcha ? hifiganUrl : null,
      needsEspeakData: type.needsEspeakData(id),
      previewAudioUrl: type.buildPreviewUrl(id, langToken),
    );
  }
}

@freezed
abstract class ModelDownloadProgress with _$ModelDownloadProgress {
  const factory ModelDownloadProgress({
    required String modelId,
    required ModelDownloadStage stage,
    required double fraction,

    /// Current download speed in bytes/second, when known.
    double? speedBytesPerSec,

    /// Estimated time remaining, when known.
    Duration? timeRemaining,
  }) = _ModelDownloadProgress;
}

enum ModelDownloadStage { downloading, paused, extracting, done, failed }

/// Deterministic background_downloader task id for a TTS model's archive
/// download. Shared by the downloader service (which creates the transfer)
/// and the settings bloc (which pauses/resumes/cancels it).
String ttsModelTaskId(String modelId) => 'tts-model-$modelId';

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

// ---------------------------------------------------------------------------
// Catalog parsing helpers — shared by SherpaTtsModelInfo.fromAsset.
// These are global lookup tables used only during parsing, not per-instance
// data, so they live here as private top-level members rather than fields.
// ---------------------------------------------------------------------------

const Set<String> _unsupportedEngines = {
  'inflect',
  'kitten',
  'pocket',
  'supertonic',
  'zipvoice',
};

const Set<String> _qualities = {'x-low', 'low', 'medium', 'high'};

final RegExp _langRe = RegExp(
  r'^([a-z]{2}(?:_[A-Za-z]{2})?|eng|spa|fra|ukr|rus|deu|nan)(?:-(.+))?$',
);

const Map<String, String> _langLabels = {
  'multi': 'Multiple languages',
  'en': 'English',
  'de': 'German',
  'fr': 'French',
  'es': 'Spanish',
  'zh': 'Chinese',
  'yue': 'Cantonese',
  'ru': 'Russian',
  'uk': 'Ukrainian',
  'pl': 'Polish',
  'nl': 'Dutch',
  'sv': 'Swedish',
  'da': 'Danish',
  'no': 'Norwegian',
  'fi': 'Finnish',
  'cs': 'Czech',
  'sk': 'Slovak',
  'hr': 'Croatian',
  'ga': 'Irish',
  'et': 'Estonian',
  'ro': 'Romanian',
  'pt': 'Portuguese',
  'bn': 'Bengali',
  'mt': 'Maltese',
  'lv': 'Latvian',
  'sl': 'Slovenian',
  'bg': 'Bulgarian',
  'lt': 'Lithuanian',
  'hu': 'Hungarian',
  'el': 'Greek',
  'ko': 'Korean',
  'af': 'Afrikaans',
  'gu': 'Gujarati',
  'ne': 'Nepali',
  'vi': 'Vietnamese',
  'fa': 'Persian',
  'ka': 'Georgian',
  'kk': 'Kazakh',
  'tr': 'Turkish',
  'ml': 'Malayalam',
  'sr': 'Serbian',
  'sw': 'Swahili',
  'lb': 'Luxembourgish',
  'cy': 'Welsh',
  'eu': 'Basque',
  'ar': 'Arabic',
  'hi': 'Hindi',
  'id': 'Indonesian',
  'is': 'Icelandic',
  'it': 'Italian',
  'ur': 'Urdu',
  'sq': 'Albanian',
  'ca': 'Catalan',
  'ku': 'Kurdish',
  'th': 'Thai',
  'nan': 'Min Nan',
};

extension SherpaTtsModelTypeX on SherpaTtsModelType {
  /// Whether a model of this type with [id] needs the shared espeak-ng
  /// phonemization data.
  bool needsEspeakData(String id) {
    if (this == SherpaTtsModelType.kokoro ||
        this == SherpaTtsModelType.matcha) {
      return true;
    }
    return id.contains('piper-') ||
        id.contains('mimic3-') ||
        id.contains('mms-') ||
        id.contains('melo-');
  }

  /// Preview audio URL for a model of this type, or null when unavailable.
  String? buildPreviewUrl(String id, String langToken) {
    const base =
        'https://huggingface.co/csukuangfj/sherpa-onnx-tts-samples/resolve/main';
    if (id.contains('piper-')) {
      return '$base/piper/mp3/$langToken/$id/0.mp3';
    }
    if (id.contains('inflect')) {
      return '$base/inflect/$id/mp3/0.mp3';
    }
    if (this == SherpaTtsModelType.kokoro) {
      // Sample folders are version-specific and use different voice names:
      //   v0_19 -> kokoro/v0.19/mp3/0-af.mp3
      //   v1_0  -> kokoro/v1.0/mp3/0-af_alloy.mp3
      //   v1_1  -> kokoro/v1.1-zh/mp3/0-af_maple.mp3
      return switch (id.split('-').last) {
        'v0_19' => '$base/kokoro/v0.19/mp3/0-af.mp3',
        'v1_1' => '$base/kokoro/v1.1-zh/mp3/0-af_maple.mp3',
        _ => '$base/kokoro/v1.0/mp3/0-af_alloy.mp3',
      };
    }
    if (this == SherpaTtsModelType.matcha) {
      // Samples live under the icefall-* folders; the en_ljspeech/zh/zh_en
      // folders only contain docs and generator scripts.
      if (id.contains('ljspeech')) {
        return '$base/matcha/icefall-en-ljspeech/mp3/0.mp3';
      }
      if (id.contains('zh-en') || id.contains('zh_en')) {
        return '$base/matcha/icefall-zh-en/mp3/0.mp3';
      }
      if (id.contains('zh')) {
        return '$base/matcha/icefall-zh/mp3/0.mp3';
      }
    }
    return null;
  }
}

extension StringTitleCaseX on String {
  String get titleCase =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
