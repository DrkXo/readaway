part of '../services.dart';

/// Model catalog & value types for the sherpa-onnx offline TTS engine.
///
/// sherpa-onnx ships several different *model families*, each with its own
/// config shape (see OfflineTtsModelConfig in the sherpa_onnx package):
///   - VITS    (e.g. Piper voices, icefall VITS, MeloTTS)   -> single onnx + tokens (+ optional lexicon/dict)
///   - Matcha  (acoustic model + separate vocoder onnx)
///   - Kokoro  (onnx + voices.bin + tokens, many built-in speakers)
///
/// The full list of downloadable archives lives at
/// https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models and is
/// fetched live from the GitHub release API (cached for a day);
/// [SherpaTtsModelCatalog] derives the browsable model list from it.

/// Which underlying sherpa-onnx TTS architecture a model uses. This decides
/// which sub-config (`vits` / `matcha` / `kokoro`) we populate on
/// [OfflineTtsModelConfig] when loading the model.
enum SherpaTtsModelType { vits, matcha, kokoro }

/// Describes one downloadable sherpa-onnx TTS voice pack.
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

  /// Stable identifier, also used as the folder name under the app's
  /// documents directory once the model is downloaded & extracted.
  final String id;

  final String displayName;

  /// BCP-47-ish language code, e.g. `en-US`, `de-DE`, `zh-CN`.
  final String languageCode;
  final String languageLabel;

  final SherpaTtsModelType type;

  /// Direct URL to the `.tar.bz2` archive on GitHub releases.
  final String downloadUrl;

  final double approxSizeMb;
  final bool isMultiSpeaker;
  final int speakerCount;
  final String description;
  final int sampleRateHint;

  /// Matcha models ship the acoustic model separately from the vocoder
  /// (e.g. a shared HiFiGAN `.onnx`). Null for VITS/Kokoro, which are
  /// self-contained.
  final String? vocoderUrl;

  /// Whether this model needs the shared `espeak-ng-data` phonemization
  /// directory (installed once into the models root by the downloader).
  final bool needsEspeakData;

  String get archiveFileName => downloadUrl.split('/').last;
  String? get vocoderFileName => vocoderUrl?.split('/').last;

  @override
  String toString() => 'SherpaTtsModelInfo($id, $displayName, $type)';
}

@lazySingleton
class SherpaTtsModelCatalog {
  SherpaTtsModelCatalog({
    required this._httpService,
  });

  final HttpService _httpService;

  /// GitHub release whose `assets` array is the live model manifest.
  static const String _releaseApiUrl =
      'https://api.github.com/repos/k2-fsa/sherpa-onnx/releases/tags/tts-models';

  /// sha256 checksums for every release asset (one `<hash>  <name>` per line).
  static const String _checksumUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/checksum.txt';

  final String _releaseBase =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models';

  /// Matcha acoustic models ship without a vocoder; this shared HiFi-GAN
  /// vocoder is downloaded next to them (see downloadModel).
  String get _hifiganUrl => '$_releaseBase/hifigan_v2.onnx';

  /// Shared espeak-ng phonemization data required by piper-family models
  /// (piper/mimic3/mms/kokoro/matcha/melo). Downloaded once into the models
  /// root by [SherpaTtsModelDownloader].
  String get espeakDataUrl => '$_releaseBase/espeak-ng-data.tar.bz2';

  List<SherpaTtsModelInfo> _models = const [];
  List<SherpaTtsModelInfo> get models => _models;

  Map<String, String> _checksums = const {};

  /// sha256 of a release asset by file name, or null when the checksum file
  /// hasn't been fetched (or doesn't list that file).
  String? checksumFor(String fileName) => _checksums[fileName];

  /// Fetches the live release manifest (cached for a day) and derives the
  /// model list. Call once at startup ([SherpaOnnxTtsService.init] does it).
  ///
  /// Never throws: on failure the catalog stays empty (the UI surfaces the
  /// error) so a transient network problem can't take down app startup.
  Future<void> load() async {
    if (_models.isNotEmpty) return;
    try {
      final response = await _httpService.getCached<Map<String, dynamic>>(
        path: _releaseApiUrl,
        maxStale: const Duration(days: 1),
        headers: const {'User-Agent': 'readaway'},
      );
      final assets = response.data?['assets'] as List? ?? const [];
      final parsed = <SherpaTtsModelInfo>[];
      for (final a in assets) {
        final map = a as Map;
        final name = map['name'] as String?;
        final size = (map['size'] as num?)?.toInt();
        final downloadUrl = map['browser_download_url'] as String?;
        if (name == null || size == null || downloadUrl == null) continue;
        final m = _fromAsset(name, size, downloadUrl);
        if (m != null) parsed.add(m);
      }
      _models = parsed
        ..sort((a, b) {
          final c = a.languageLabel.compareTo(b.languageLabel);
          return c != 0 ? c : a.displayName.compareTo(b.displayName);
        });
      await _loadChecksums();
    } catch (e, stackTrace) {
      logger.e('Failed to load TTS model catalog', e, stackTrace);
    }
  }

  Future<void> _loadChecksums() async {
    try {
      final response = await _httpService.getCached<String>(
        path: _checksumUrl,
        maxStale: const Duration(days: 1),
        headers: const {'User-Agent': 'readaway'},
        responseType: ResponseType.plain,
      );
      final text = response.data;
      if (text == null) return;
      final map = <String, String>{};
      for (final line in text.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        // checksum.txt format: "<name>  <hash>" (name first, sha256 last).
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;
        final hash = parts.last.toLowerCase();
        if (hash.length != 64) continue;
        map[parts.sublist(0, parts.length - 1).join(' ')] = hash;
      }
      _checksums = map;
    } catch (e) {
      // Checksums are best-effort: downloads proceed without verification.
      logger.w('Failed to load TTS checksums; skipping verification');
      _checksums = const {};
    }
  }

  SherpaTtsModelInfo? byId(String id) {
    for (final m in _models) {
      if (m.id == id) return m;
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Manifest -> SherpaTtsModelInfo derivation
  // -------------------------------------------------------------------------

  /// Engine families whose archive layout doesn't map onto one of our three
  /// supported config shapes yet.
  // ponytail: denylist of newer engines; move them to supported when a
  // config shape exists, or flip to an allowlist if junk starts slipping in.
  final Set<String> _unsupportedEngines = {
    'inflect',
    'kitten',
    'pocket',
    'supertonic',
    'zipvoice',
  };

  /// Family words sitting between the type prefix and the language code,
  /// e.g. `vits-piper-en_US-…`, `matcha-icefall-zh-…`.
  final List<String> _families = [
    'piper-',
    'coqui-',
    'mimic3-',
    'mms-',
    'icefall-',
    'tts-',
    'melo-',
  ];

  /// Quality suffixes used by piper-style archives.
  final Set<String> _qualities = {'x-low', 'low', 'medium', 'high'};

  final RegExp _langRe = RegExp(
    r'^([a-z]{2}(?:_[A-Za-z]{2})?|eng|spa|fra|ukr|rus|deu|nan)(?:-(.+))?$',
  );

  final Map<String, String> _langLabels = {
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

  SherpaTtsModelInfo? _fromAsset(
    String name,
    int sizeBytes,
    String downloadUrl,
  ) {
    if (!name.endsWith('.tar.bz2')) return null;
    final id = name.substring(0, name.length - '.tar.bz2'.length);
    // Quantized variants duplicate the base voice; keep only the base pack.
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

    String langToken;
    String remainder;
    if (type == SherpaTtsModelType.kokoro) {
      langToken = rest.startsWith('multi-lang') ? 'multi' : 'en';
      remainder = rest;
    } else if (rest.startsWith('cantonese-')) {
      langToken = 'yue';
      remainder = rest.substring(10);
    } else {
      for (final f in _families) {
        if (rest.startsWith(f)) {
          rest = rest.substring(f.length);
          break;
        }
      }
      final m = _langRe.firstMatch(rest);
      if (m != null) {
        langToken = m.group(1)!;
        remainder = m.group(2) ?? '';
      } else {
        // Single-corpus packs like `vits-ljs` / `vits-vctk`.
        if (!RegExp(r'^[a-z0-9]+$').hasMatch(rest)) return null;
        langToken = 'en';
        remainder = rest;
      }
    }

    final segments = remainder.split('-').where((s) => s.isNotEmpty).toList();
    String? quality;
    if (segments.length > 1 && _qualities.contains(segments.last)) {
      quality = segments.removeLast();
    }
    var displayName = segments.map(_titleCase).join(' ');
    if (displayName.isEmpty) {
      displayName = _titleCase(rest.replaceAll('_', ' '));
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
      vocoderUrl: type == SherpaTtsModelType.matcha ? _hifiganUrl : null,
      needsEspeakData: _needsEspeakData(id, type),
    );
  }

  /// Whether this model needs the shared espeak-ng phonemization data.
  /// Piper-family engines (piper/mimic3/mms/melo) plus kokoro and matcha all
  /// require it; coqui and icefall VITS packs are self-contained.
  bool _needsEspeakData(String id, SherpaTtsModelType type) {
    if (type == SherpaTtsModelType.kokoro ||
        type == SherpaTtsModelType.matcha) {
      return true;
    }
    return id.contains('piper-') ||
        id.contains('mimic3-') ||
        id.contains('mms-') ||
        id.contains('melo-');
  }

  String _titleCase(String word) =>
      word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}';
}

/// Progress event emitted while a model archive is downloading/extracting.
class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.modelId,
    required this.stage,
    required this.fraction,
  });

  final String modelId;
  final ModelDownloadStage stage;

  /// 0.0 - 1.0
  final double fraction;
}

enum ModelDownloadStage { downloading, extracting, done, failed }

/// One synthesized voice sample, ready to hand to an audio player or to
/// write to disk.
class TtsAudio {
  const TtsAudio({required this.samples, required this.sampleRate});

  /// Mono PCM float samples in [-1.0, 1.0], matching sherpa's GeneratedAudio.
  final Float32List samples;
  final int sampleRate;

  Duration get duration =>
      Duration(milliseconds: (samples.length / sampleRate * 1000).round());
}

/// A single sherpa-onnx built-in speaker exposed by the currently loaded
/// model (for multi-speaker models such as Kokoro).
class SherpaTtsSpeaker {
  const SherpaTtsSpeaker({required this.id, required this.label});
  final int id;
  final String label;
}

/// Thrown for any recoverable TTS-service failure (bad archive, no model
/// loaded, unsupported model layout, etc.) so callers can show a real error
/// instead of a crash.
class SherpaTtsException implements Exception {
  SherpaTtsException(this.message);
  final String message;
  @override
  String toString() => 'SherpaTtsException: $message';
}
