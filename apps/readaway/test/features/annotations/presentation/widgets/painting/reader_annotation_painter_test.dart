import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readaway/src/features/annotations/domain/entity/reader_note.dart';
import 'package:readaway/src/features/annotations/presentation/widgets/painting/reader_annotation_painter.dart';

/// A chapter-local box, as the resolver produces.
const _box = Rect.fromLTWH(20, 100, 60, 20);

const _sliceTop = 100.0;
const _pageSize = Size(300, 400);

AnnotationPaint _paint({
  String id = 'n1',
  List<Rect> rects = const [_box],
  HighlightStyle style = HighlightStyle.highlight,
  Color baseColor = const Color(0xFFF59E0B),
}) => AnnotationPaint(
  id: id,
  rects: rects,
  style: style,
  baseColor: baseColor,
);

ReaderAnnotationPainter _painter({
  List<AnnotationPaint>? paints,
  double sliceTop = _sliceTop,
  Brightness brightness = Brightness.light,
  bool highContrast = false,
}) => ReaderAnnotationPainter(
  paints: paints ?? [_paint()],
  sliceTop: sliceTop,
  brightness: brightness,
  highContrast: highContrast,
);

/// Paints into a throwaway picture, which is enough to prove the painter does
/// not throw while drawing.
void _paintOnce(ReaderAnnotationPainter painter, {Size size = _pageSize}) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  group('paint', () {
    test('draws every style without throwing', () {
      for (final style in HighlightStyle.values) {
        _paintOnce(_painter(paints: [_paint(style: style)]));
        _paintOnce(
          _painter(paints: [_paint(style: style)], highContrast: true),
          size: const Size(100, 100),
        );
      }
    });

    test('is a no-op for an empty list or an empty canvas', () {
      _paintOnce(_painter(paints: const []));
      _paintOnce(_painter(), size: Size.zero);
    });

    test('tolerates a box that lies entirely off the page', () {
      // Chapter-local y=100 with a page sliced from y=1000: nowhere near it.
      _paintOnce(
        _painter(
          paints: [
            _paint(rects: const [_box]),
          ],
          sliceTop: 1000,
        ),
      );
    });
  });

  group('noteAt', () {
    test('finds a box in page coordinates, not chapter coordinates', () {
      // The box sits at chapter-local y=100; the page starts at y=100, so on
      // screen it occupies y=0..20.
      expect(_painter().noteAt(const Offset(30, 5)), 'n1');
      expect(_painter().noteAt(const Offset(30, 105)), isNull);
      expect(_painter().noteAt(const Offset(5, 5)), isNull);
    });

    test('is forgiving around a thin stroke', () {
      // A squiggly underline is 1.5px tall; requiring the reader to hit it
      // exactly would make it unusable as a target.
      final painter = _painter(
        paints: [_paint(style: HighlightStyle.squiggly)],
      );

      expect(painter.noteAt(const Offset(30, -3)), 'n1');
      expect(painter.noteAt(const Offset(30, 23)), 'n1');
      // `Rect.contains` excludes the far edge, so one pixel past the inflated
      // box is already a miss.
      expect(painter.noteAt(const Offset(30, 25)), isNull);
    });

    test('returns the annotation drawn on top when they overlap', () {
      final painter = _painter(
        paints: [
          _paint(id: 'under'),
          _paint(id: 'over', baseColor: const Color(0xFF0EA5E9)),
        ],
      );

      expect(painter.noteAt(const Offset(30, 5)), 'over');
    });

    test('checks every box of an annotation, not just the first', () {
      final painter = _painter(
        paints: [
          _paint(
            rects: const [
              Rect.fromLTWH(20, 100, 60, 20),
              Rect.fromLTWH(20, 200, 60, 20),
            ],
          ),
        ],
      );

      // The page is sliced from chapter y=100, so the first box (chapter
      // 100..120) sits at page y 0..20 and the second (chapter 200..220) at page
      // y 100..120.
      expect(painter.noteAt(const Offset(30, 10)), 'n1');
      expect(painter.noteAt(const Offset(30, 110)), 'n1');
      expect(painter.noteAt(const Offset(30, 60)), isNull);
    });

    test('misses everything when there is nothing to paint', () {
      expect(_painter(paints: const []).noteAt(const Offset(30, 5)), isNull);
    });
  });

  group('shouldRepaint', () {
    test('is false for an identical painter', () {
      expect(_painter().shouldRepaint(_painter()), isFalse);
    });

    test('is true when the page slice moves', () {
      expect(_painter().shouldRepaint(_painter(sliceTop: 200)), isTrue);
    });

    test('is true when the theme or contrast changes', () {
      expect(
        _painter().shouldRepaint(_painter(brightness: Brightness.dark)),
        isTrue,
      );
      expect(_painter().shouldRepaint(_painter(highContrast: true)), isTrue);
    });

    test('is true when an annotation is added, removed or changed', () {
      expect(
        _painter().shouldRepaint(
          _painter(
            paints: [
              _paint(),
              _paint(id: 'n2'),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        _painter().shouldRepaint(
          _painter(paints: [_paint(style: HighlightStyle.underline)]),
        ),
        isTrue,
      );
      expect(
        _painter().shouldRepaint(
          _painter(paints: [_paint(baseColor: const Color(0xFF10B981))]),
        ),
        isTrue,
      );
    });

    test('is true when a resolved box moves', () {
      expect(
        _painter().shouldRepaint(
          _painter(
            paints: [
              _paint(rects: const [Rect.fromLTWH(20, 120, 60, 20)]),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('is true when an annotation resolves to a different box count', () {
      // A highlight that wraps onto a second line gains a box.
      expect(
        _painter().shouldRepaint(
          _painter(
            paints: [
              _paint(
                rects: const [
                  Rect.fromLTWH(20, 100, 60, 20),
                  Rect.fromLTWH(20, 120, 40, 20),
                ],
              ),
            ],
          ),
        ),
        isTrue,
      );
    });
  });
}
