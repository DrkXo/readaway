import 'package:flutter/material.dart';

/// One selectable preset for the TTS speech-highlight color.
///
/// A `null` [color] means "follow the active theme's primary color" (the
/// `primary` preset), resolved at paint time from the [ColorScheme].
@immutable
class TtsHighlightColorOption {
  const TtsHighlightColorOption({
    required this.key,
    required this.label,
    this.color,
  });

  /// Stable identifier persisted in `GlobalViewSettings.ttsHighlightColor`.
  final String key;

  /// Human-readable name shown in the color picker.
  final String label;

  /// The swatch color, or null to follow the theme's primary color.
  final Color? color;
}

/// The built-in TTS speech-highlight palette.
///
/// This is the single source of truth for the preset keys, their labels, and
/// their colors, shared by the settings picker and the reader highlight
/// painter.
const List<TtsHighlightColorOption> kTtsHighlightColorOptions = [
  TtsHighlightColorOption(key: 'primary', label: 'Primary'),
  TtsHighlightColorOption(
    key: 'amber',
    label: 'Amber',
    color: Color(0xFFF59E0B),
  ),
  TtsHighlightColorOption(
    key: 'emerald',
    label: 'Emerald',
    color: Color(0xFF10B981),
  ),
  TtsHighlightColorOption(
    key: 'sky',
    label: 'Sky',
    color: Color(0xFF0EA5E9),
  ),
  TtsHighlightColorOption(
    key: 'violet',
    label: 'Violet',
    color: Color(0xFF8B5CF6),
  ),
  TtsHighlightColorOption(
    key: 'rose',
    label: 'Rose',
    color: Color(0xFFF43F5E),
  ),
];

/// Whether [value] is a preset key rather than a custom hex color.
bool isPresetTtsHighlightColor(String? value) =>
    value != null && kTtsHighlightColorOptions.any((o) => o.key == value);

/// Whether [value] is a custom hex color rather than a preset key.
bool isCustomTtsHighlightColor(String? value) =>
    !isPresetTtsHighlightColor(value) &&
    value != null &&
    parseHexColor(value) != null;

/// Resolves the persisted [value] (a preset key or a hex string) to a [Color].
///
/// Falls back to [scheme]'s primary color for an unknown or malformed value.
Color resolveTtsHighlightColor(String? value, ColorScheme scheme) {
  if (value != null && value.isNotEmpty) {
    for (final option in kTtsHighlightColorOptions) {
      if (option.key == value) return option.color ?? scheme.primary;
    }
    final custom = parseHexColor(value);
    if (custom != null) return custom;
  }
  return scheme.primary;
}

/// Parses `#RGB`, `#RRGGBB`, or `#AARRGGBB` (with or without `#`) into a
/// [Color], or returns null when [value] is not a valid hex color.
Color? parseHexColor(String value) {
  final hex = value.trim().replaceFirst('#', '');
  if (hex.isEmpty || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) return null;

  return switch (hex.length) {
    3 => Color(
      int.parse(
        'FF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}',
        radix: 16,
      ),
    ),
    6 => Color(int.parse('FF$hex', radix: 16)),
    8 => Color(int.parse(hex, radix: 16)),
    _ => null,
  };
}

/// Normalises a user-entered hex color to opaque `#RRGGBB`, or null when
/// [value] is not a valid hex color.
String? normalizeHexColor(String value) {
  final parsed = parseHexColor(value);
  return parsed == null ? null : colorToHex(parsed);
}

/// Formats [color] as an opaque upper-case `#RRGGBB` string.
String colorToHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}'
        .toUpperCase();
