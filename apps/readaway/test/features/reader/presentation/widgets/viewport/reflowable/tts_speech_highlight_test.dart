import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/reader/presentation/widgets/viewport/reflowable/tts_speech_highlight.dart';

/// The painted result of a highlight, read back as pixels.
///
/// Asserting on rendered output rather than on recorded draw calls keeps the
/// tests tied to what the reader actually sees, which is the thing the placement
/// and clipping rules exist to get right.
class _Painted {
  _Painted(this._data, this.width, this.height);

  final ByteData _data;
  final int width;
  final int height;

  bool _hasInk(int x, int y) {
    final i = (y * width + x) * 4;
    return _data.getUint8(i + 3) > 0;
  }

  /// Whether any pixel in [y] was painted.
  bool rowPainted(int y) {
    for (var x = 0; x < width; x++) {
      if (_hasInk(x, y)) return true;
    }
    return false;
  }

  /// The first and last painted rows, or null when nothing was painted.
  (int, int)? get paintedRows {
    int? first;
    var last = -1;
    for (var y = 0; y < height; y++) {
      if (rowPainted(y)) {
        first ??= y;
        last = y;
      }
    }
    if (first == null) return null;
    return (first, last);
  }

  /// The leftmost and rightmost painted columns within [y].
  (int, int)? spanAt(int y) {
    int? left;
    var right = -1;
    for (var x = 0; x < width; x++) {
      if (_hasInk(x, y)) {
        left ??= x;
        right = x;
      }
    }
    if (left == null) return null;
    return (left, right);
  }

  Color? colourAt(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      _data.getUint8(i + 3),
      _data.getUint8(i),
      _data.getUint8(i + 1),
      _data.getUint8(i + 2),
    );
  }
}

Future<_Painted> _render(
  TtsSpeechHighlightPainter painter, {
  Size size = const Size(400, 1000),
}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return _Painted(data!, size.width.toInt(), size.height.toInt());
}

TtsSpeechHighlightPainter _painter({
  required List<Rect> rects,
  double sliceTop = 0,
  Color color = const Color(0xFF0000FF),
  double cornerRadius = 3,
}) => TtsSpeechHighlightPainter(
  rects: rects,
  sliceTop: sliceTop,
  color: color,
  cornerRadius: cornerRadius,
);

void main() {
  group('placement', () {
    test('draws a chapter-local rect at its offset within the page', () async {
      // The page starts 1000 units into the chapter, and the rect sits at 1100,
      // so it must appear 100 units down the visible page.
      final painted = await _render(
        _painter(rects: [Rect.fromLTWH(0, 1100, 400, 20)], sliceTop: 1000),
      );

      expect(painted.paintedRows, (100, 119));
      expect(painted.spanAt(110), (0, 399));
    });

    test('draws nothing for a rect belonging to another page', () async {
      // Viewing the second page while the spoken range is on the first.
      final painted = await _render(
        _painter(rects: [Rect.fromLTWH(0, 10, 400, 20)], sliceTop: 1000),
      );

      expect(painted.paintedRows, isNull);
    });

    test('draws one box per line of a multi-line range', () async {
      final painted = await _render(
        _painter(
          rects: [
            Rect.fromLTWH(0, 1000, 400, 20),
            Rect.fromLTWH(0, 1024, 400, 20),
            Rect.fromLTWH(0, 1048, 400, 20),
          ],
          sliceTop: 1000,
        ),
      );

      // Three 20-unit lines separated by 4-unit gaps: rows 0-19, 24-43, 48-67.
      expect(painted.rowPainted(19), isTrue);
      expect(painted.rowPainted(22), isFalse);
      expect(painted.rowPainted(24), isTrue);
      expect(painted.rowPainted(43), isTrue);
      expect(painted.rowPainted(47), isFalse);
      expect(painted.rowPainted(48), isTrue);
      expect(painted.paintedRows, (0, 67));
    });

    test('draws nothing for an empty range', () async {
      expect((await _render(_painter(rects: const []))).paintedRows, isNull);
    });
  });

  group('clipping at page boundaries', () {
    test('clips a range that starts on the previous page', () async {
      // The rect runs 960-1040 and the page starts at 1000, so only its lower
      // 40 units are on screen.
      final painted = await _render(
        _painter(rects: [Rect.fromLTWH(0, 960, 400, 80)], sliceTop: 1000),
      );

      expect(painted.paintedRows, (0, 39));
    });

    test('clips a range that continues onto the next page', () async {
      // The rect runs 1980-2180, so on a page starting at 1000 only the first
      // 20 units sit above the page's lower edge.
      final painted = await _render(
        _painter(rects: [Rect.fromLTWH(0, 1980, 400, 200)], sliceTop: 1000),
      );

      expect(painted.paintedRows, (980, 999));
    });

    test('skips the lines of a range that span many pages', () async {
      // Forty lines spread over more than one page. The off-screen ones must
      // not be drawn: they would be invisible anyway, and a range this long
      // should not cost a draw call per line.
      final painted = await _render(
        _painter(
          rects: List.generate(
            40,
            (i) => Rect.fromLTWH(0, 1000 + (i * 24), 400, 20),
          ),
          sliceTop: 1000,
        ),
      );

      final rows = painted.paintedRows;
      expect(rows, isNotNull);
      expect(rows!.$2, lessThan(1000));
      expect(rows.$1, 0);
    });
  });

  group('appearance', () {
    test('uses the requested colour', () async {
      final painted = await _render(
        _painter(
          rects: const [Rect.fromLTWH(0, 0, 400, 20)],
          color: const Color(0xFFFF0000),
        ),
        size: const Size(400, 100),
      );

      expect(painted.colourAt(200, 10), const Color(0xFFFF0000));
    });

    test('rounds the corners of a highlighted line', () async {
      final painted = await _render(
        _painter(
          rects: const [Rect.fromLTWH(0, 0, 400, 20)],
          cornerRadius: 12,
        ),
        size: const Size(400, 100),
      );

      // With a corner radius the very corner pixel stays unpainted, which a
      // square box would have filled.
      expect(painted.rowPainted(0) && painted.spanAt(0) != null, isTrue);
      expect(painted.spanAt(0)!.$1, greaterThan(0));
    });
  });

  group('shouldRepaint', () {
    List<Rect> rects() => [const Rect.fromLTWH(0, 10, 400, 20)];

    test('is false for an identical delegate', () {
      expect(
        _painter(rects: rects()).shouldRepaint(_painter(rects: rects())),
        isFalse,
      );
    });

    test('is true when the range moves', () {
      expect(
        _painter(rects: rects()).shouldRepaint(
          _painter(rects: [const Rect.fromLTWH(0, 30, 400, 20)]),
        ),
        isTrue,
      );
    });

    test('is true when the range changes length', () {
      expect(
        _painter(rects: rects()).shouldRepaint(
          _painter(
            rects: const [
              Rect.fromLTWH(0, 10, 400, 20),
              Rect.fromLTWH(0, 30, 400, 20),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('is true when the page offset changes', () {
      // A page turn reuses the painter with a different slice, so the same
      // range lands somewhere else and must repaint.
      expect(
        _painter(rects: rects(), sliceTop: 0).shouldRepaint(
          _painter(rects: rects(), sliceTop: 1000),
        ),
        isTrue,
      );
    });

    test('is true when the colour changes', () {
      expect(
        _painter(
          rects: rects(),
          color: const Color(0xFF0000FF),
        ).shouldRepaint(
          _painter(rects: rects(), color: const Color(0xFFFF0000)),
        ),
        isTrue,
      );
    });
  });
}
