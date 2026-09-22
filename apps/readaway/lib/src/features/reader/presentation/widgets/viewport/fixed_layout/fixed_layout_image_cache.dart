import 'dart:collection';
import 'dart:typed_data';

import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway_core/readaway_core.dart';

/// In-memory LRU cache and pre-fetcher for non-reflowable document page images.
class FixedLayoutImageCache {
  FixedLayoutImageCache({this.maxEntries = 30});

  static final FixedLayoutImageCache instance = FixedLayoutImageCache();

  final int maxEntries;

  final LinkedHashMap<String, Uint8List> _imageCache =
      LinkedHashMap<String, Uint8List>();
  final LinkedHashMap<String, PageSize> _sizeCache =
      LinkedHashMap<String, PageSize>();
  final Map<String, Future<Uint8List?>> _inFlightImages = {};
  final Map<String, Future<PageSize?>> _inFlightSizes = {};

  String _key(String docPath, int pageIndex) => '$docPath:$pageIndex';

  /// Retrieves cached page image bytes or loads them via [ReaderRepository].
  Future<Uint8List?> getOrLoadImage(
    ReaderRepository repository,
    String docPath,
    int pageIndex, {
    double? scale,
    int? targetWidth,
    int? targetHeight,
  }) async {
    final key = _key(docPath, pageIndex);
    if (_imageCache.containsKey(key)) {
      final bytes = _imageCache.remove(key)!;
      _imageCache[key] = bytes; // Move to most recently used
      return bytes;
    }

    if (_inFlightImages.containsKey(key)) {
      return _inFlightImages[key]!;
    }

    final future = () async {
      try {
        final result = await repository
            .loadPageImage(
              pageIndex,
              scale: scale ?? 1.0,
              targetWidth: targetWidth,
              targetHeight: targetHeight,
            )
            .run();
        final bytes = result.getRight().toNullable();
        if (bytes != null) {
          _putImage(key, bytes);
        }
        return bytes;
      } finally {
        _inFlightImages.remove(key);
      }
    }();

    _inFlightImages[key] = future;
    return future;
  }

  /// Retrieves cached page size (width, height) or queries via [ReaderRepository].
  Future<PageSize?> getOrLoadSize(
    ReaderRepository repository,
    String docPath,
    int pageIndex,
  ) async {
    final key = _key(docPath, pageIndex);
    if (_sizeCache.containsKey(key)) {
      final size = _sizeCache.remove(key)!;
      _sizeCache[key] = size;
      return size;
    }

    if (_inFlightSizes.containsKey(key)) {
      return _inFlightSizes[key]!;
    }

    final future = () async {
      try {
        final result = await repository.getPageSize(pageIndex).run();
        final size = result.getRight().toNullable();
        if (size != null) {
          _putSize(key, size);
        }
        return size;
      } finally {
        _inFlightSizes.remove(key);
      }
    }();

    _inFlightSizes[key] = future;
    return future;
  }

  /// Synchronously returns cached page image bytes if present in memory.
  Uint8List? getCachedImage(String docPath, int pageIndex) {
    final key = _key(docPath, pageIndex);
    return _imageCache[key];
  }

  /// Synchronously returns cached page dimensions if present in memory.
  PageSize? getCachedSize(String docPath, int pageIndex) {
    final key = _key(docPath, pageIndex);
    return _sizeCache[key];
  }

  /// Pre-fetches adjacent pages ($N-2, N-1, N+1, N+2$) in the background.
  void preloadAdjacent(
    ReaderRepository repository,
    String docPath,
    int currentPage,
    int pageCount,
  ) {
    for (final delta in const [1, -1, 2, -2]) {
      final target = currentPage + delta;
      if (target >= 0 && target < pageCount) {
        getOrLoadSize(repository, docPath, target);
        getOrLoadImage(repository, docPath, target);
      }
    }
  }

  void _putImage(String key, Uint8List bytes) {
    if (_imageCache.length >= maxEntries) {
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[key] = bytes;
  }

  void _putSize(String key, PageSize size) {
    if (_sizeCache.length >= maxEntries * 2) {
      _sizeCache.remove(_sizeCache.keys.first);
    }
    _sizeCache[key] = size;
  }

  /// Clears all cached images and dimensions for the given document or entirely.
  void clear([String? docPath]) {
    if (docPath == null) {
      _imageCache.clear();
      _sizeCache.clear();
      _inFlightImages.clear();
      _inFlightSizes.clear();
    } else {
      _imageCache.removeWhere((k, _) => k.startsWith('$docPath:'));
      _sizeCache.removeWhere((k, _) => k.startsWith('$docPath:'));
      _inFlightImages.removeWhere((k, _) => k.startsWith('$docPath:'));
      _inFlightSizes.removeWhere((k, _) => k.startsWith('$docPath:'));
    }
  }
}
