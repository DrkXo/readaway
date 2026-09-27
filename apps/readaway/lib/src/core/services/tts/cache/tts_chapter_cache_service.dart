import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';

import '../../../../features/settings/domain/entity/settings.dart';
import '../../path_service.dart';
import '../../settings_service.dart';
import '../tts_models.dart';

/// Manages chapter-level and chunk-level audio file caching on disk for TTS playback.
///
/// Directory structure:
/// `<tts_cache_dir>/<book_key>/<voice_id>__<speaker_id>__<config_hash>/chapter_<index>/`
///   ├── manifest.json
///   ├── chunk_0000.wav
///   ├── chunk_0001.wav
///   └── ...
@lazySingleton
class TtsChapterCacheService {
  final _log = AppLogger.instance.scope('TtsChapterCacheService');

  final AppPathService _pathService;
  final SettingsService _settingsService;

  TtsChapterCacheService(this._pathService, this._settingsService);

  /// Computes a stable, filesystem-safe book key from document path or ID.
  String computeBookKey(String documentPath) {
    final clean = documentPath.trim();
    if (clean.isEmpty) return 'anonymous_book';
    final bytes = utf8.encode(clean);
    final digest = md5.convert(bytes).toString();
    final name = p.basenameWithoutExtension(clean).replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final truncatedName = name.length > 24 ? name.substring(0, 24) : name;
    return '${truncatedName}_$digest';
  }

  /// Computes MD5 hash of speech text to invalidate cache if book content changes.
  String computeTextHash(String speechText) {
    final bytes = utf8.encode(speechText.trim());
    return md5.convert(bytes).toString();
  }

  /// Computes a configuration signature hash of prosody/silence settings.
  String computeConfigHash(GlobalViewSettings settings) {
    final raw = '${settings.ttsNarrationStyle}:'
        '${settings.ttsSentenceGap}:'
        '${settings.ttsParagraphGap}:'
        '${settings.ttsSilenceScale}:'
        '${settings.ttsNoiseScale}:'
        '${settings.ttsNoiseScaleW}:'
        '${settings.ttsLengthScale}:'
        '${settings.ttsNumSteps}';
    final bytes = utf8.encode(raw);
    return md5.convert(bytes).toString().substring(0, 8);
  }

  /// Resolves the root chapter cache directory for a given book, voice, and chapter.
  Future<Directory> getChapterDirectory({
    required String bookPath,
    required int chapterIndex,
    required TtsVoiceOption voice,
  }) async {
    final root = await _pathService.getTtsAudioCacheDirectory();
    final bookKey = computeBookKey(bookPath);
    final configHash = computeConfigHash(_settingsService.settings.globalViewSettings);
    final voiceDirName = '${voice.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}__'
        '${voice.sherpaSpeakerId ?? 0}__'
        '$configHash';
    final chapterDirName = 'chapter_${chapterIndex.toString().padLeft(4, '0')}';

    final chapterDir = Directory(
      p.join(root.path, bookKey, voiceDirName, chapterDirName),
    );
    if (!await chapterDir.exists()) {
      await chapterDir.create(recursive: true);
    }
    return chapterDir;
  }

  /// Resolves the target file handle for an individual chunk WAV file.
  Future<File> getChunkFile({
    required String bookPath,
    required int chapterIndex,
    required TtsVoiceOption voice,
    required int chunkIndex,
  }) async {
    final dir = await getChapterDirectory(
      bookPath: bookPath,
      chapterIndex: chapterIndex,
      voice: voice,
    );
    final fileName = 'chunk_${chunkIndex.toString().padLeft(4, '0')}.wav';
    return File(p.join(dir.path, fileName));
  }

  /// Loads the [TtsChapterCacheManifest] for the given chapter if it exists and matches [textHash].
  Future<TtsChapterCacheManifest?> getChapterManifest({
    required String bookPath,
    required int chapterIndex,
    required TtsVoiceOption voice,
    required String textHash,
  }) async {
    try {
      final dir = await getChapterDirectory(
        bookPath: bookPath,
        chapterIndex: chapterIndex,
        voice: voice,
      );
      final manifestFile = File(p.join(dir.path, 'manifest.json'));
      if (!await manifestFile.exists()) return null;

      final content = await manifestFile.readAsString();
      if (content.trim().isEmpty) return null;

      final json = jsonDecode(content) as Map<String, dynamic>;
      final manifest = TtsChapterCacheManifest.fromJson(json);

      // Verify text hash and config hash to prevent stale prosody/content playback
      final currentConfigHash = computeConfigHash(
        _settingsService.settings.globalViewSettings,
      );
      if (manifest.textHash != textHash || manifest.configHash != currentConfigHash) {
        _log.d('Manifest hash mismatch for chapter $chapterIndex. Invalidating stale cache.');
        await _clearDirectory(dir);
        return null;
      }

      // Touch access time asynchronously
      unawaited(touchChapterAccess(manifestFile, manifest));

      return manifest;
    } catch (e, st) {
      _log.w('Failed to load TTS chapter manifest: $e', error: e, stackTrace: st);
      return null;
    }
  }

  /// Updates last accessed timestamp on manifest for LRU eviction.
  Future<void> touchChapterAccess(File manifestFile, TtsChapterCacheManifest manifest) async {
    try {
      final touched = manifest.touch();
      await saveManifestRaw(manifestFile, touched);
    } catch (_) {}
  }

  /// Atomically writes [manifest] to [manifestFile].
  Future<void> saveManifestRaw(File manifestFile, TtsChapterCacheManifest manifest) async {
    final tmp = File('${manifestFile.path}.tmp');
    final jsonStr = jsonEncode(manifest.toJson());
    await tmp.writeAsString(jsonStr, flush: true);
    if (await manifestFile.exists()) {
      await manifestFile.delete();
    }
    await tmp.rename(manifestFile.path);
  }

  /// Saves or updates the manifest for a given chapter.
  Future<void> saveChapterManifest({
    required String bookPath,
    required int chapterIndex,
    required TtsVoiceOption voice,
    required TtsChapterCacheManifest manifest,
  }) async {
    try {
      final dir = await getChapterDirectory(
        bookPath: bookPath,
        chapterIndex: chapterIndex,
        voice: voice,
      );
      final manifestFile = File(p.join(dir.path, 'manifest.json'));
      await saveManifestRaw(manifestFile, manifest);
    } catch (e, st) {
      _log.w('Failed to save chapter manifest: $e', error: e, stackTrace: st);
    }
  }

  /// Checks if a chunk file exists and is structurally valid (has valid WAV header length > 44 bytes).
  Future<bool> isChunkFileValid(File file) async {
    try {
      if (!await file.exists()) return false;
      final len = await file.length();
      return len > 44; // Standard minimal WAV header size
    } catch (_) {
      return false;
    }
  }

  /// Calculates total size of all cached TTS audio files in bytes.
  Future<int> calculateTotalCacheSizeBytes() async {
    try {
      final root = await _pathService.getTtsAudioCacheDirectory();
      if (!await root.exists()) return 0;

      var total = 0;
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (e) {
      _log.w('Failed to calculate TTS cache size: $e');
      return 0;
    }
  }

  /// Enforces max storage limit using LRU eviction based on `lastAccessedAt`.
  Future<void> enforceCacheLimit([int? maxBytes]) async {
    try {
      final root = await _pathService.getTtsAudioCacheDirectory();
      if (!await root.exists()) return;

      final limit = maxBytes ??
          (_settingsService.settings.globalViewSettings.ttsMaxCacheSizeMb * 1024 * 1024);
      if (limit <= 0) return; // Unlimited

      var currentSize = await calculateTotalCacheSizeBytes();
      if (currentSize <= limit) return;

      _log.i('TTS cache size ($currentSize bytes) exceeds limit ($limit bytes). Evicting LRU chapters...');

      // Find all chapter directories and their manifests
      final chapterEntries = <({Directory dir, DateTime lastAccessed, int size})>[];

      await for (final bookEntity in root.list(followLinks: false)) {
        if (bookEntity is! Directory) continue;
        await for (final voiceEntity in bookEntity.list(followLinks: false)) {
          if (voiceEntity is! Directory) continue;
          await for (final chapterEntity in voiceEntity.list(followLinks: false)) {
            if (chapterEntity is! Directory) continue;

            final manifestFile = File(p.join(chapterEntity.path, 'manifest.json'));
            DateTime lastAccessed = (await chapterEntity.stat()).modified;
            if (await manifestFile.exists()) {
              try {
                final json = jsonDecode(await manifestFile.readAsString());
                final m = TtsChapterCacheManifest.fromJson(json);
                lastAccessed = m.lastAccessedAt;
              } catch (_) {}
            }

            var dirSize = 0;
            await for (final f in chapterEntity.list(recursive: true, followLinks: false)) {
              if (f is File) dirSize += await f.length();
            }

            chapterEntries.add((
              dir: chapterEntity,
              lastAccessed: lastAccessed,
              size: dirSize,
            ));
          }
        }
      }

      // Sort oldest first
      chapterEntries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

      for (final entry in chapterEntries) {
        if (currentSize <= limit) break;
        await _clearDirectory(entry.dir);
        currentSize -= entry.size;
        _log.d('Evicted TTS chapter directory: ${entry.dir.path} (${entry.size} bytes)');
      }
    } catch (e, st) {
      _log.w('Failed during TTS cache eviction: $e', error: e, stackTrace: st);
    }
  }

  /// Clears cached audio for a specific book.
  Future<void> clearBookCache(String bookPath) async {
    try {
      final root = await _pathService.getTtsAudioCacheDirectory();
      final bookKey = computeBookKey(bookPath);
      final bookDir = Directory(p.join(root.path, bookKey));
      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
        _log.i('Cleared TTS cache for book: $bookKey');
      }
    } catch (e) {
      _log.w('Failed to clear book TTS cache: $e');
    }
  }

  /// Clears all TTS audio cache on disk.
  Future<void> clearAllCache() async {
    try {
      final root = await _pathService.getTtsAudioCacheDirectory();
      if (await root.exists()) {
        await root.delete(recursive: true);
        await root.create(recursive: true);
        _log.i('Cleared entire TTS audio cache');
      }
    } catch (e) {
      _log.w('Failed to clear all TTS audio cache: $e');
    }
  }

  Future<void> _clearDirectory(Directory dir) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
