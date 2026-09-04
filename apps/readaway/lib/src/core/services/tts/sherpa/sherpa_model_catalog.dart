import 'package:injectable/injectable.dart';

import '../../http/http_service.dart';
import '../../logging_service.dart';
import '../tts_models.dart';

@lazySingleton
class SherpaTtsModelCatalogService {
  SherpaTtsModelCatalogService({
    required this._httpService,
  });

  final HttpService _httpService;

  /// GitHub release whose `assets` array is the live model manifest.
  static const String _releaseApiUrl =
      'https://api.github.com/repos/k2-fsa/sherpa-onnx/releases/tags/tts-models';

  /// sha256 checksums for every release asset (one `<hash>  <name>` per line,
  /// standard `sha256sum` output format).
  static const String _checksumUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/checksum.txt';

  final String _releaseBase =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models';

  /// Matcha acoustic models ship without a vocoder; this shared HiFi-GAN
  /// vocoder is downloaded next to them (see downloadModel).
  String get _hifiganUrl => '$_releaseBase/hifigan_v2.onnx';

  /// Shared espeak-ng phonemization data required by piper-family models
  /// (piper/mimic3/mms/kokoro/matcha/melo). Downloaded once into the models
  /// root by [SherpaTtsModelDownloaderService].
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
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;
        final hash = parts.first.toLowerCase();
        if (hash.length != 64) continue;
        final name = parts.sublist(1).join(' ');
        map[name] = hash;
      }
      _checksums = map;
      if (_checksums.isEmpty) {
        logger.w(
          'Parsed 0 TTS checksums from $_checksumUrl — '
          'unexpected format? Downloads will proceed unverified.',
        );
      }
    } catch (e) {
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

  final Set<String> _unsupportedEngines = {
    'inflect',
    'kitten',
    'pocket',
    'supertonic',
    'zipvoice',
  };

  final List<String> _families = [
    'piper-',
    'coqui-',
    'mimic3-',
    'mms-',
    'icefall-',
    'tts-',
    'melo-',
  ];

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
