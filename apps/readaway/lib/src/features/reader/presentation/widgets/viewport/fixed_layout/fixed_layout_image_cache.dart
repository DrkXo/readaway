import 'dart:typed_data';

import 'package:cacherine/cacherine.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway_core/readaway_core.dart';

/// Floor on [FixedLayoutImageCache]'s byte budget, in bytes.
///
/// A user who picks the smallest offered cache size must still be able to read
/// an image-heavy comic: below roughly one decoded spread's worth of page
/// images, the cache would thrash and every page turn would re-decode.
const int kMinReaderCacheBytes = 16 * 1024 * 1024;

/// Default byte budget, giving ample headroom for decoded spreads and
/// multi-page preloads without thrashing (64 MB).
const int kDefaultReaderCacheBytes = 64 * 1024 * 1024;

/// [kMinReaderCacheBytes] expressed in megabytes — the smallest size offered in
/// settings, and the value the floor is derived from.
const int kMinReaderCacheMb = kMinReaderCacheBytes ~/ (1024 * 1024);

/// The default offered in settings, mirroring [kDefaultReaderCacheBytes].
const int kDefaultReaderCacheSizeMb = kDefaultReaderCacheBytes ~/ (1024 * 1024);

/// Default ceiling on the page-image entry count, enforced alongside the byte
/// budget so a book made of thousands of tiny pages cannot grow the cache
/// without bound even when it fits under the weight cap.
const int kMaxReaderCacheEntries = 400;

/// In-memory byte-budgeted LRU cache and pre-fetcher for non-reflowable
/// document page images.
///
/// Page images are the largest thing this app holds in memory, so eviction is
/// bounded by *bytes* ([configureBudget]) rather than entry count — 30 entries
/// is either trivial or catastrophic depending on whether the book is line
/// art or high-resolution scans.
class FixedLayoutImageCache {
  /// [budgetBytes] is taken verbatim — it is the *mechanism*, not the policy.
  /// The user-facing floor lives in [configureBudget], the only path settings
  /// flow through, so keeping them apart is what lets tests exercise
  /// byte-bounded eviction with kilobyte budgets instead of 16 MB ones.
  FixedLayoutImageCache({
    int budgetBytes = kDefaultReaderCacheBytes,
    this.maxEntries = kMaxReaderCacheEntries,
  }) : assert(budgetBytes > 0, 'budgetBytes must be greater than 0'),
       _budgetBytes = budgetBytes {
    _imageCache = _newImageCache(_budgetBytes);
  }

  static final FixedLayoutImageCache instance = FixedLayoutImageCache();

  /// Never mutate the fields directly: [configureBudget] replaces the whole
  /// cache when the user's setting changes.
  late SimpleWeightedLRUCache<String, Uint8List> _imageCache;

  /// Page dimensions are tiny, so a plain count-bounded LRU is the right
  /// shape here — weighting them by bytes would add cost for no benefit.
  late final SimpleLRUCache<String, PageSize> _sizeCache = SimpleLRUCache(
    maxEntries * 2,
  );

  /// Transient in-flight guards, deliberately kept out of the caches above: an
  /// entry here must disappear the moment its load settles, whereas a cached
  /// page must persist. They also wrap slow async work, which cacherine's
  /// `getOrCompute` would serialise behind a per-instance lock.
  final Map<String, Future<Uint8List?>> _inFlightImages = {};
  final Map<String, Future<PageSize?>> _inFlightSizes = {};

  /// Ceiling on page-image entries, enforced alongside the byte budget.
  final int maxEntries;

  int _budgetBytes;

  SimpleWeightedLRUCache<String, Uint8List> _newImageCache(int budget) =>
      SimpleWeightedLRUCache<String, Uint8List>(
        weigher: (_, value) => value.lengthInBytes,
        maxWeight: budget,
        maxSize: maxEntries,
      );

  /// The byte budget currently in force. When reached through
  /// [configureBudget] this is always >= [kMinReaderCacheBytes].
  int get budgetBytes => _budgetBytes;

  String _key(String docPath, int pageIndex) => '$docPath:$pageIndex';

  /// Applies a new byte budget, discarding the cached pages.
  ///
  /// This is the entry point for user settings, so it enforces the
  /// [kMinReaderCacheBytes] floor: picking the smallest offered size must not
  /// be able to starve an image-heavy book.
  ///
  /// cacherine exposes `maxWeight` as a `final` field, so the budget cannot be
  /// mutated in place — the cache is rebuilt instead. Existing pages are
  /// dropped rather than migrated because re-weighing them all would cost more
  /// than the handful of page turns it would save, and this only runs when the
  /// user actually changes the setting.
  void configureBudget(int bytes) {
    final clamped = bytes < kMinReaderCacheBytes ? kMinReaderCacheBytes : bytes;
    if (clamped == _budgetBytes) return;
    _budgetBytes = clamped;
    _imageCache = _newImageCache(clamped);
  }

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
    final cached = _imageCache.get(key);
    if (cached != null) return cached;

    if (_inFlightImages.containsKey(key)) {
      return _inFlightImages[key]!;
    }

    final future = () async {
      try {
        final result = await repository.loadPageImage(
          pageIndex,
          scale: scale ?? 2.0,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
        final bytes = result.dataOrNull;
        if (bytes != null) {
          _imageCache.set(key, bytes);
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
    final cached = _sizeCache.get(key);
    if (cached != null) return cached;

    if (_inFlightSizes.containsKey(key)) {
      return _inFlightSizes[key]!;
    }

    final future = () async {
      try {
        final result = await repository.getPageSize(pageIndex);
        final size = result.dataOrNull;
        if (size != null) {
          _sizeCache.set(key, size);
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
  ///
  /// Reads with `peek`, so a render pass asking "do I already have this page?"
  /// does not count as an access and inflate that page's recency.
  Uint8List? getCachedImage(String docPath, int pageIndex) =>
      _imageCache.peek(_key(docPath, pageIndex));

  /// Synchronously returns cached page dimensions if present in memory.
  PageSize? getCachedSize(String docPath, int pageIndex) =>
      _sizeCache.peek(_key(docPath, pageIndex));

  /// Pre-fetches adjacent pages ($N+1, N-1, N+2, N-2$) in the background sequentially.
  void preloadAdjacent(
    ReaderRepository repository,
    String docPath,
    int currentPage,
    int pageCount, {
    double? scale,
  }) async {
    for (final delta in const [1, -1, 2, -2]) {
      final target = currentPage + delta;
      if (target >= 0 && target < pageCount) {
        final key = _key(docPath, target);
        if (_imageCache.peek(key) == null) {
          await getOrLoadSize(repository, docPath, target);
          await getOrLoadImage(repository, docPath, target, scale: scale);
        }
      }
    }
  }

  /// Clears all cached images and dimensions for the given document or entirely.
  void clear([String? docPath]) {
    if (docPath == null) {
      _imageCache.clear();
      _sizeCache.clear();
      _inFlightImages.clear();
      _inFlightSizes.clear();
    } else {
      final prefix = '$docPath:';
      _imageCache.removeWhere((k, _) => k.startsWith(prefix));
      _sizeCache.removeWhere((k, _) => k.startsWith(prefix));
      _inFlightImages.removeWhere((k, _) => k.startsWith(prefix));
      _inFlightSizes.removeWhere((k, _) => k.startsWith(prefix));
    }
  }
}
