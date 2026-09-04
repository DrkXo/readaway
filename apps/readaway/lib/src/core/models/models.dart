import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';
part 'settings.dart';


/// Contextual quick panels displayed above the reader bottom bar.
enum ReaderBottomPanel {
  /// Display brightness overlay and theme switcher (light/system/dark).
  brightness,

  /// Page scrubber and first/last page jump controls.
  pageNavigation,

  /// Font resizing steppers, slider, and preset scale chips.
  fontSize,
}
