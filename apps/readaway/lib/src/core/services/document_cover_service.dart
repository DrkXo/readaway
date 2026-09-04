import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../utils/reader/reader_image_utils.dart';
import 'logging_service.dart';
import 'mupdf_service.dart';
import 'path_service.dart';

/// Dedicated service for extracting, white-margin trimming, and caching
/// document cover art thumbnails.
@lazySingleton
class DocumentCoverService {
  DocumentCoverService(
    this._muPdfService,
    this._pathService,
  );

  final MuPdfService _muPdfService;
  final AppPathService _pathService;

  static final Logger _log = Logger('DocumentCoverService');

  /// Retrieves a cached cover art URI or renders page 0, trims paper margins,
  /// and saves a clean cover thumbnail PNG to disk.
  Future<Uri?> getCoverArtUri({
    required String filePath,
    required String fileName,
    int pageCount = 1,
  }) async {
    if (pageCount <= 0) return null;

    try {
      final cacheDir = await _pathService.getTtsAudioCacheDirectory();
      final coverDir = Directory(p.join(cacheDir.path, 'covers'));
      if (!await coverDir.exists()) {
        await coverDir.create(recursive: true);
      }

      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final coverFile = File(p.join(coverDir.path, 'cover_$safeName.png'));
      if (await coverFile.exists()) {
        return coverFile.uri;
      }

      // Render page 0 at 1.0x scale
      final rendered =
          await _muPdfService.renderPage(0, scaleX: 1.0, scaleY: 1.0);
      if (rendered == null) return null;

      // Automatically crop white paper borders around the cover illustration
      final cropped = cropWhiteMargins(rendered);

      final img = await decodeRenderedPage(cropped);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();

      if (byteData != null) {
        await coverFile.writeAsBytes(
          byteData.buffer.asUint8List(),
          flush: true,
        );
        return coverFile.uri;
      }
    } catch (e, st) {
      _log.w(
        'DocumentCoverService: failed to extract cover for $fileName',
        e,
        st,
      );
    }
    return null;
  }

  /// Detects and trims uniform white or near-white borders surrounding the cover art.
  @visibleForTesting
  Map<String, dynamic> cropWhiteMargins(Map<String, dynamic> rendered) {
    final w = rendered['width'] as int;
    final h = rendered['height'] as int;
    final stride = rendered['stride'] as int;
    final comps = rendered['components'] as int;
    final pixels = rendered['pixels'] as Uint8List;

    if (w < 20 || h < 20 || pixels.isEmpty) return rendered;

    bool isWhiteOrTransparent(int x, int y) {
      final offset = y * stride + x * comps;
      if (offset + (comps - 1) >= pixels.length) return true;
      if (comps == 4) {
        final a = pixels[offset + 3];
        if (a < 15) return true;
      }
      final r = pixels[offset];
      final g = pixels[offset + 1];
      final b = pixels[offset + 2];
      return r > 240 && g > 240 && b > 240;
    }

    // Scan top edge
    var top = 0;
    while (top < h - 10) {
      var nonWhiteCount = 0;
      for (var x = 0; x < w; x += 2) {
        if (!isWhiteOrTransparent(x, top)) nonWhiteCount++;
      }
      if (nonWhiteCount > (w / 20)) break;
      top++;
    }

    // Scan bottom edge
    var bottom = h - 1;
    while (bottom > top + 10) {
      var nonWhiteCount = 0;
      for (var x = 0; x < w; x += 2) {
        if (!isWhiteOrTransparent(x, bottom)) nonWhiteCount++;
      }
      if (nonWhiteCount > (w / 20)) break;
      bottom--;
    }

    // Scan left edge
    var left = 0;
    while (left < w - 10) {
      var nonWhiteCount = 0;
      for (var y = top; y <= bottom; y += 2) {
        if (!isWhiteOrTransparent(left, y)) nonWhiteCount++;
      }
      if (nonWhiteCount > ((bottom - top) / 20)) break;
      left++;
    }

    // Scan right edge
    var right = w - 1;
    while (right > left + 10) {
      var nonWhiteCount = 0;
      for (var y = top; y <= bottom; y += 2) {
        if (!isWhiteOrTransparent(right, y)) nonWhiteCount++;
      }
      if (nonWhiteCount > ((bottom - top) / 20)) break;
      right--;
    }

    final newW = right - left + 1;
    final newH = bottom - top + 1;

    // Only crop if a meaningful non-white region was found (at least 30% of each dimension)
    if (newW < w * 0.3 || newH < h * 0.3 || (newW == w && newH == h)) {
      return rendered;
    }

    final croppedStride = newW * comps;
    final croppedPixels = Uint8List(newH * croppedStride);

    for (var y = 0; y < newH; y++) {
      final srcOffset = (top + y) * stride + left * comps;
      final dstOffset = y * croppedStride;
      croppedPixels.setRange(
        dstOffset,
        dstOffset + croppedStride,
        pixels.sublist(srcOffset, srcOffset + croppedStride),
      );
    }

    return {
      'width': newW,
      'height': newH,
      'stride': croppedStride,
      'components': comps,
      'pixels': croppedPixels,
    };
  }
}
