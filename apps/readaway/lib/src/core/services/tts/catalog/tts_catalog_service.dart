// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../http/http_service.dart';
import '../tts_model_store.dart';
import '../tts_models.dart';

class TtsCatalogSyncResult {
  const TtsCatalogSyncResult({
    required this.totalModels,
    required this.newModelsCount,
    required this.updatedModelsCount,
  });

  final int totalModels;
  final int newModelsCount;
  final int updatedModelsCount;
}

@lazySingleton
class TtsCatalogService {
  final _log = AppLogger.instance.scope('TtsCatalogService');

  TtsCatalogService({
    required HttpService httpService,
    required TtsModelStore store,
  }) : _httpService = httpService,
       _store = store;

  final HttpService _httpService;
  final TtsModelStore _store;

  /// Loads bundled catalog and checksums from app assets if Hive store is currently empty.
  Future<List<SherpaTtsModelInfo>> ensureInitialCatalog() async {
    final existing = _store.loadCatalog();
    if (existing.isNotEmpty) {
      return existing;
    }
    return loadBundledCatalog();
  }

  /// Force loads catalog from local assets into the store.
  Future<List<SherpaTtsModelInfo>> loadBundledCatalog() async {
    try {
      final catalogJsonStr = await rootBundle.loadString(
        'assets/tts/tts_catalog.json',
      );
      final rawList = jsonDecode(catalogJsonStr) as List<dynamic>;
      final models = rawList
          .map(
            (item) => SherpaTtsModelInfo.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      final checksumJsonStr = await rootBundle.loadString(
        'assets/tts/tts_checksums.json',
      );
      final checksums = (jsonDecode(checksumJsonStr) as Map<String, dynamic>)
          .cast<String, String>();

      await _store.saveCatalog(models);
      await _store.saveChecksums(checksums);
      return models;
    } catch (e, st) {
      _log.e('Failed to load bundled TTS catalog assets', error: e, stackTrace: st);
      return _store.loadCatalog();
    }
  }

  /// Syncs catalog and checksums from upstream GitHub release.
  Future<TtsCatalogSyncResult> syncFromRemote({bool force = false}) async {
    final previousCatalog = _store.loadCatalog();
    final previousIds = previousCatalog.map((m) => m.id).toSet();
    final previousChecksums = _store.loadChecksums();

    // 1. Fetch checksums
    final checksumMap = await _fetchChecksums(force: force);
    if (checksumMap.isNotEmpty) {
      await _store.saveChecksums(checksumMap);
    }

    // 2. Fetch release manifest
    final response = await _httpService.getCached<Map<String, dynamic>>(
      path: SherpaTtsUrls.manifestApiUrl,
      maxStale: force ? Duration.zero : const Duration(days: 1),
      headers: const {'User-Agent': 'readaway'},
    );

    final rawAssets = response.data?['assets'] as List? ?? const [];
    final parsed = <SherpaTtsModelInfo>[];
    for (final a in rawAssets) {
      if (a is! Map<String, dynamic>) continue;
      final name = a['name'] as String?;
      final size = (a['size'] as num?)?.toInt();
      final downloadUrl = a['browser_download_url'] as String?;
      if (name == null || size == null || downloadUrl == null) continue;
      final m = SherpaTtsModelInfo.fromAsset(
        name: name,
        sizeBytes: size,
        downloadUrl: downloadUrl,
        hifiganUrl: SherpaTtsUrls.hifiganUrl,
      );
      if (m != null) {
        final archiveChecksum = checksumMap[m.archiveFileName];
        parsed.add(
          m.copyWith(
            installedChecksum: archiveChecksum,
            installedSizeBytes: size,
          ),
        );
      }
    }

    if (parsed.isEmpty && previousCatalog.isNotEmpty) {
      return TtsCatalogSyncResult(
        totalModels: previousCatalog.length,
        newModelsCount: 0,
        updatedModelsCount: 0,
      );
    }

    parsed.sort((a, b) {
      final c = a.languageLabel.compareTo(b.languageLabel);
      return c != 0 ? c : a.displayName.compareTo(b.displayName);
    });

    int newCount = 0;
    int updatedCount = 0;
    for (final m in parsed) {
      if (!previousIds.contains(m.id)) {
        newCount++;
      } else {
        final prevChecksum = previousChecksums[m.archiveFileName];
        if (prevChecksum != null &&
            m.installedChecksum != null &&
            prevChecksum != m.installedChecksum) {
          updatedCount++;
        }
      }
    }

    await _store.saveCatalog(parsed);

    return TtsCatalogSyncResult(
      totalModels: parsed.length,
      newModelsCount: newCount,
      updatedModelsCount: updatedCount,
    );
  }

  Future<Map<String, String>> _fetchChecksums({bool force = false}) async {
    try {
      final response = await _httpService.getCached<String>(
        path: SherpaTtsUrls.checksumUrl,
        maxStale: force ? Duration.zero : const Duration(days: 1),
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
        if (parts[0].length == 64 &&
            RegExp(r'^[a-fA-F0-9]+$').hasMatch(parts[0])) {
          map[parts.sublist(1).join(' ')] = parts[0].toLowerCase();
        } else if (parts[1].length == 64 &&
            RegExp(r'^[a-fA-F0-9]+$').hasMatch(parts[1])) {
          map[parts[0]] = parts[1].toLowerCase();
        }
      }
      return map;
    } catch (e, st) {
      _log.w('Failed to fetch remote checksums: $e', error: e, stackTrace: st);
      return const {};
    }
  }
}
