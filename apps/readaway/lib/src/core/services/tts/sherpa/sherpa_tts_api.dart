import 'package:injectable/injectable.dart';

import '../../http/http_service.dart';
import '../../logging_service.dart';

/// Transport layer for the sherpa-onnx TTS model catalog: owns the GitHub
/// base URLs and performs the HTTP calls. Returns raw data only — parsing
/// into [SherpaTtsModelInfo] happens in the model itself.
@lazySingleton
class SherpaTtsApi {
  SherpaTtsApi({required this._httpService});

  final HttpService _httpService;

  /// GitHub release whose `assets` array is the live model manifest.
  static const String _releaseApiUrl =
      'https://api.github.com/repos/k2-fsa/sherpa-onnx/releases/tags/tts-models';

  /// sha256 checksums for every release asset (one `<hash>  <name>` per line,
  /// standard `sha256sum` output format).
  static const String _checksumUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/checksum.txt';

  static const String _releaseBase =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models';

  /// Shared espeak-ng phonemization data required by piper-family models
  /// (piper/mimic3/mms/kokoro/matcha/melo). Downloaded once into the models
  /// root by [SherpaTtsModelDownloaderService].
  String get espeakDataUrl => '$_releaseBase/espeak-ng-data.tar.bz2';

  /// Matcha acoustic models ship without a vocoder; this shared HiFi-GAN
  /// vocoder is downloaded next to them (see downloadModel).
  String get hifiganUrl => '$_releaseBase/hifigan_v2.onnx';

  /// Fetches the raw release manifest assets. Never throws — returns an empty
  /// list on failure so a transient network problem can't take down startup.
  Future<List<Map<String, dynamic>>> fetchManifest() async {
    try {
      final response = await _httpService.getCached<Map<String, dynamic>>(
        path: _releaseApiUrl,
        maxStale: const Duration(days: 1),
        headers: const {'User-Agent': 'readaway'},
      );
      final assets = response.data?['assets'] as List? ?? const [];
      return assets.whereType<Map<String, dynamic>>().toList();
    } catch (e, stackTrace) {
      logger.e('Failed to load TTS model catalog', e, stackTrace);
      return const [];
    }
  }

  /// Fetches the sha256 checksums as a `{fileName: hash}` map. Never throws —
  /// returns an empty map on failure so downloads proceed unverified.
  Future<Map<String, String>> fetchChecksums() async {
    try {
      final response = await _httpService.getCached<String>(
        path: _checksumUrl,
        maxStale: const Duration(days: 1),
        headers: const {'User-Agent': 'readaway'},
        responseType: ResponseType.plain,
      );
      final text = response.data;
      if (text == null) return const {};
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
      if (map.isEmpty) {
        logger.w(
          'Parsed 0 TTS checksums from $_checksumUrl — '
          'unexpected format? Downloads will proceed unverified.',
        );
      }
      return map;
    } catch (e) {
      logger.w('Failed to load TTS checksums; skipping verification');
      return const {};
    }
  }
}
