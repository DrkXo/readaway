import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

/// Process-wide holder for the transient highlight that shows the currently
/// selected in-document search match.
///
/// A ValueNotifier rather than BLoC state because every virtual page listens to
/// it independently, and the dialog that owns the match selection is transient.
class ReaderSearchHighlightController {
  final ValueNotifier<({int chapterIndex, List<Rect> rects})?> current =
      ValueNotifier(null);

  void set(int chapterIndex, List<Rect> rects) {
    current.value = (chapterIndex: chapterIndex, rects: rects);
  }

  void clear() => current.value = null;

  void dispose() => current.dispose();
}
