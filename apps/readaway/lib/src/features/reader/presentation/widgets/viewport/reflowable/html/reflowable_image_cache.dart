import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:readaway/src/core/utils/lru_cache.dart';

/// Page-lifetime image pipeline shared by every rendered instance of a chapter.
///
/// Pagination slices re-create page widgets whenever the layout reflows (image
/// decode, viewport resize, page turns). Without a shared layer each new page
/// re-fetched and re-decoded every image, flashing a spinner placeholder each
/// time. This cache keeps raw bytes (deduped in flight) and decoded frames so
/// a recreated page paints images on the very first frame.
class ReflowableImageCache {
  ReflowableImageCache._();

  static final ReflowableImageCache instance = ReflowableImageCache._();

  final LruCache<String, Uint8List> _bytes = LruCache(maximumSize: 40);
  final Map<String, Future<Uint8List?>> _inFlightBytes = {};
  final LruCache<String, ui.Image> _decoded = LruCache(maximumSize: 12);
  final Map<String, Future<ui.Image?>> _inFlightDecodes = {};

  String _key(String namespace, int chapterIndex, String src) =>
      '$namespace\u0000$chapterIndex\u0000$src';

  /// Resolves asset bytes once per document, deduplicating concurrent loads.
  ///
  /// [namespace] keeps separate documents from sharing keys (chapter indices
  /// and asset paths repeat across books).
  Future<Uint8List?> resolveBytes(
    String namespace,
    int chapterIndex,
    String src, {
    required Future<Uint8List?> Function() load,
  }) async {
    final key = _key(namespace, chapterIndex, src);

    final cached = _bytes[key];
    if (cached != null) return cached;

    final inFlight = _inFlightBytes[key];
    if (inFlight != null) return inFlight;

    final future = () async {
      try {
        final bytes = await load();
        if (bytes != null && bytes.isNotEmpty) {
          _bytes[key] = bytes;
          return bytes;
        }
        return null;
      } finally {
        _inFlightBytes.remove(key);
      }
    }();
    _inFlightBytes[key] = future;
    return future;
  }

  /// The decoded frame for this image, if already resident.
  Uint8List? peekBytes(String namespace, int chapterIndex, String src) =>
      _bytes[_key(namespace, chapterIndex, src)];

  /// The decoded frame for this image, if already resident.
  ui.Image? peekDecoded(String namespace, int chapterIndex, String src) =>
      _decoded[_key(namespace, chapterIndex, src)];

  /// Returns a shared decoded frame for [src], decoding it once for all
  /// consumers (widgets and HyperRender's layout pass both read the same
  /// bytes, so a decoded-frame cache makes the load a single frame instead of
  /// a spinner pop).
  ///
  /// Data URIs are decoded inline; other sources go through [load].
  ///
  /// ponytail: decoded frames are owned by this cache and never disposed on
  /// eviction (a RawImage may still be painting them). Add ref-counted
  /// disposal if the 12-frame cap proves too tight on image-heavy books.
  Future<ui.Image?> decode(
    String namespace,
    int chapterIndex,
    String src, {
    required Future<Uint8List?> Function() load,
  }) async {
    final key = _key(namespace, chapterIndex, src);

    final cached = _decoded[key];
    if (cached != null) return cached;

    final inFlight = _inFlightDecodes[key];
    if (inFlight != null) return inFlight;

    final future = _decodeNew(key, namespace, chapterIndex, src, load);
    _inFlightDecodes[key] = future;
    return future;
  }

  Future<ui.Image?> _decodeNew(
    String key,
    String namespace,
    int chapterIndex,
    String src,
    Future<Uint8List?> Function() load,
  ) async {
    try {
      Uint8List? bytes;
      if (src.startsWith('data:')) {
        final commaIndex = src.indexOf(',');
        if (commaIndex != -1) {
          try {
            bytes = Uint8List.fromList(
              base64Decode(src.substring(commaIndex + 1)),
            );
          } catch (_) {
            return null;
          }
        }
      } else {
        bytes = await resolveBytes(namespace, chapterIndex, src, load: load);
      }
      if (bytes == null || bytes.isEmpty) return null;

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      _decoded[key] = frame.image;
      return frame.image;
    } finally {
      _inFlightDecodes.remove(key);
    }
  }

  /// Releases cached frames (and their native memory). Safe only when no
  /// widget is still painting them, e.g. on viewport teardown.
  void clear() {
    _bytes.clear();
    _inFlightBytes.clear();
    _inFlightDecodes.clear();
    final images = _decoded.values.toList();
    _decoded.clear();
    for (final image in images) {
      image.dispose();
    }
  }
}
