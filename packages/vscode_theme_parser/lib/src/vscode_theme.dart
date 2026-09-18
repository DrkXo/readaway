import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jsonc/jsonc.dart';

part 'vscode_theme.freezed.dart';
part 'vscode_theme.g.dart';

double? _numToDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

dynamic _doubleToNum(double? value) => value;

/// A structured representation of TextMate token scopes for syntax highlighting.
///
/// In VS Code theme files, a scope can be null (for default token settings),
/// a single string (`"comment"`), a comma-separated string (`"storage.type, keyword.operator"`),
/// or an array of strings (`["entity.name", "meta.class"]`).
@freezed
sealed class VsCodeTokenScope with _$VsCodeTokenScope {
  const VsCodeTokenScope._();

  const factory VsCodeTokenScope({
    @Default(<String>[]) List<String> selectors,
  }) = _VsCodeTokenScope;

  /// Creates a [VsCodeTokenScope] from a list of raw selector strings.
  factory VsCodeTokenScope.fromSelectors(List<String> rawSelectors) {
    final list = <String>[];
    for (final sel in rawSelectors) {
      if (sel.contains(',')) {
        for (final sub in sel.split(',')) {
          final trimmed = sub.trim();
          if (trimmed.isNotEmpty) {
            list.add(trimmed);
          }
        }
      } else {
        final trimmed = sel.trim();
        if (trimmed.isNotEmpty) {
          list.add(trimmed);
        }
      }
    }
    return VsCodeTokenScope(selectors: List.unmodifiable(list));
  }

  /// Whether this scope rule matches the given [scopeName].
  bool matches(String scopeName) {
    if (selectors.isEmpty) return false;
    for (final selector in selectors) {
      if (scopeName == selector || scopeName.startsWith('$selector.')) {
        return true;
      }
    }
    return false;
  }

  factory VsCodeTokenScope.fromJson(Map<String, dynamic> json) =>
      _$VsCodeTokenScopeFromJson(json);
}

/// JSON Converter for [VsCodeTokenScope].
class VsCodeTokenScopeConverter
    implements JsonConverter<VsCodeTokenScope?, Object?> {
  const VsCodeTokenScopeConverter();

  @override
  VsCodeTokenScope? fromJson(Object? json) {
    if (json == null) return null;
    if (json is VsCodeTokenScope) return json;
    if (json is String) {
      return VsCodeTokenScope.fromSelectors([json]);
    }
    if (json is List) {
      final list = json.map((e) => e.toString()).toList();
      return VsCodeTokenScope.fromSelectors(list);
    }
    if (json is Map<String, dynamic>) {
      return VsCodeTokenScope.fromJson(json);
    }
    return null;
  }

  @override
  Object? toJson(VsCodeTokenScope? object) {
    if (object == null) return null;
    if (object.selectors.length == 1) {
      return object.selectors.first;
    }
    return object.selectors;
  }
}

/// Font style, color, and sizing settings for a TextMate token rule.
@freezed
sealed class VsCodeTokenSettings with _$VsCodeTokenSettings {
  const VsCodeTokenSettings._();

  const factory VsCodeTokenSettings({
    String? foreground,
    String? background,
    String? fontStyle,
    String? fontFamily,
    @JsonKey(fromJson: _numToDouble, toJson: _doubleToNum) double? fontSize,
    @JsonKey(fromJson: _numToDouble, toJson: _doubleToNum) double? lineHeight,
  }) = _VsCodeTokenSettings;

  factory VsCodeTokenSettings.fromJson(Map<String, dynamic> json) =>
      _$VsCodeTokenSettingsFromJson(json);

  /// Whether the font style contains `bold`.
  bool get isBold =>
      fontStyle?.split(RegExp(r'\s+')).contains('bold') ?? false;

  /// Whether the font style contains `italic`.
  bool get isItalic =>
      fontStyle?.split(RegExp(r'\s+')).contains('italic') ?? false;

  /// Whether the font style contains `underline`.
  bool get isUnderline =>
      fontStyle?.split(RegExp(r'\s+')).contains('underline') ?? false;

  /// Whether the font style contains `strikethrough`.
  bool get isStrikethrough =>
      fontStyle?.split(RegExp(r'\s+')).contains('strikethrough') ?? false;

  /// Whether the font style explicitly clears inherited formatting (`""` or `"none"`).
  bool get isNone => fontStyle == '' || fontStyle?.trim() == 'none';
}

/// JSON Converter for [VsCodeTokenSettings].
class VsCodeTokenSettingsConverter
    implements JsonConverter<VsCodeTokenSettings, Object?> {
  const VsCodeTokenSettingsConverter();

  @override
  VsCodeTokenSettings fromJson(Object? json) {
    if (json == null) return const VsCodeTokenSettings();
    if (json is VsCodeTokenSettings) return json;
    if (json is Map<String, dynamic>) {
      return VsCodeTokenSettings.fromJson(json);
    }
    if (json is Map) {
      return VsCodeTokenSettings.fromJson(
        json.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return const VsCodeTokenSettings();
  }

  @override
  Object? toJson(VsCodeTokenSettings object) {
    return object.toJson();
  }
}

/// A syntax highlighting rule in a VS Code theme.
@freezed
sealed class VsCodeTokenColor with _$VsCodeTokenColor {
  const factory VsCodeTokenColor({
    String? name,
    @VsCodeTokenScopeConverter() VsCodeTokenScope? scope,
    @VsCodeTokenSettingsConverter()
    @Default(VsCodeTokenSettings())
    VsCodeTokenSettings settings,
  }) = _VsCodeTokenColor;

  factory VsCodeTokenColor.fromJson(Map<String, dynamic> json) =>
      _$VsCodeTokenColorFromJson(json);
}

/// Converter for [List<VsCodeTokenColor>] supporting raw maps, deserialized items, and serialization.
class VsCodeTokenColorsConverter
    implements JsonConverter<List<VsCodeTokenColor>, Object?> {
  const VsCodeTokenColorsConverter();

  @override
  List<VsCodeTokenColor> fromJson(Object? json) {
    if (json == null) return const <VsCodeTokenColor>[];
    if (json is List) {
      final list = <VsCodeTokenColor>[];
      for (final item in json) {
        if (item is VsCodeTokenColor) {
          list.add(item);
        } else if (item is Map<String, dynamic>) {
          list.add(VsCodeTokenColor.fromJson(item));
        } else if (item is Map) {
          list.add(
            VsCodeTokenColor.fromJson(
              item.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
      return list;
    }
    return const <VsCodeTokenColor>[];
  }

  @override
  Object? toJson(List<VsCodeTokenColor> object) {
    return object.map((e) => e.toJson()).toList();
  }
}

/// Semantic token styling for languages supporting semantic highlighting.
///
/// In VS Code theme definitions, a semantic token color can be defined as:
/// - A color hex string: `"#dcdcaa"`
/// - A style object: `{"foreground": "#4ec9b0", "bold": true, "italic": false}`
/// - A boolean: `false` (disables the rule)
@freezed
sealed class VsCodeSemanticTokenStyle with _$VsCodeSemanticTokenStyle {
  const VsCodeSemanticTokenStyle._();

  const factory VsCodeSemanticTokenStyle({
    String? foreground,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? fontStyle,
  }) = _VsCodeSemanticTokenStyle;

  factory VsCodeSemanticTokenStyle.fromJson(Map<String, dynamic> json) =>
      _$VsCodeSemanticTokenStyleFromJson(json);

  bool get isBold => bold == true || (fontStyle?.contains('bold') ?? false);
  bool get isItalic =>
      italic == true || (fontStyle?.contains('italic') ?? false);
  bool get isUnderline =>
      underline == true || (fontStyle?.contains('underline') ?? false);
  bool get isStrikethrough =>
      strikethrough == true || (fontStyle?.contains('strikethrough') ?? false);
}

/// Converter for semantic token color definitions (`Map<String, VsCodeSemanticTokenStyle>`).
class VsCodeSemanticTokensConverter
    implements
        JsonConverter<Map<String, VsCodeSemanticTokenStyle>, Object?> {
  const VsCodeSemanticTokensConverter();

  @override
  Map<String, VsCodeSemanticTokenStyle> fromJson(Object? json) {
    if (json == null || json is! Map) {
      return const <String, VsCodeSemanticTokenStyle>{};
    }
    final result = <String, VsCodeSemanticTokenStyle>{};
    for (final entry in json.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is VsCodeSemanticTokenStyle) {
        result[key] = val;
      } else if (val is String) {
        result[key] = VsCodeSemanticTokenStyle(foreground: val);
      } else if (val is Map<String, dynamic>) {
        result[key] = VsCodeSemanticTokenStyle.fromJson(val);
      } else if (val is Map) {
        result[key] = VsCodeSemanticTokenStyle.fromJson(
          val.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      // Note: boolean false unsets the styling rule
    }
    return result;
  }

  @override
  Object? toJson(Map<String, VsCodeSemanticTokenStyle> object) {
    return object.map((k, v) {
      // If only foreground is set and other properties are null, serialize as simple string
      if (v.bold == null &&
          v.italic == null &&
          v.underline == null &&
          v.strikethrough == null &&
          v.fontStyle == null &&
          v.foreground != null) {
        return MapEntry(k, v.foreground);
      }
      return MapEntry(k, v.toJson());
    });
  }
}

/// Root data model for a VS Code Color Theme (`vscode://schemas/color-theme`).
@freezed
sealed class VsCodeTheme with _$VsCodeTheme {
  const VsCodeTheme._();

  const factory VsCodeTheme({
    @JsonKey(name: r'$schema') String? schema,
    String? name,
    String? type,
    String? include,
    bool? semanticHighlighting,
    @Default(<String, String>{}) Map<String, String> colors,
    @VsCodeTokenColorsConverter()
    @Default(<VsCodeTokenColor>[])
    List<VsCodeTokenColor> tokenColors,
    @VsCodeSemanticTokensConverter()
    @Default(<String, VsCodeSemanticTokenStyle>{})
    Map<String, VsCodeSemanticTokenStyle> semanticTokenColors,
  }) = _VsCodeTheme;

  factory VsCodeTheme.fromJson(Map<String, dynamic> json) =>
      _$VsCodeThemeFromJson(json);

  /// Parses a VS Code theme from a raw JSON or JSONC string (with comments and trailing commas).
  factory VsCodeTheme.parse(String rawJsonc) {
    final decoded = jsonc.decode(rawJsonc);
    if (decoded is! Map<String, dynamic>) {
      if (decoded is Map) {
        return VsCodeTheme.fromJson(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
      throw FormatException(
        'Expected a JSON object at root of VS Code theme, got ${decoded.runtimeType}',
      );
    }
    return VsCodeTheme.fromJson(decoded);
  }

  /// Returns whether this is a dark theme.
  bool get isDark =>
      type == 'dark' ||
      type == 'hcDark' ||
      (type == null && (name?.toLowerCase().contains('dark') ?? false));

  /// Returns whether this is a light theme.
  bool get isLight =>
      type == 'light' ||
      type == 'hcLight' ||
      (type == null && (name?.toLowerCase().contains('light') ?? false));

  /// Returns whether this is a high-contrast theme.
  bool get isHighContrast =>
      type == 'hcDark' ||
      type == 'hcLight' ||
      (name?.toLowerCase().contains('contrast') ?? false);

  /// Resolves this theme by merging it on top of a [parent] base theme.
  ///
  /// Properties defined in `this` take precedence over [parent].
  /// Token colors in `this` are appended to [parent.tokenColors]
  /// and colors and semantic token colors are merged.
  VsCodeTheme mergedWith(VsCodeTheme parent) {
    final mergedColors = <String, String>{
      ...parent.colors,
      ...colors,
    };
    final mergedSemanticTokens = <String, VsCodeSemanticTokenStyle>{
      ...parent.semanticTokenColors,
      ...semanticTokenColors,
    };
    final mergedTokenColors = <VsCodeTokenColor>[
      ...parent.tokenColors,
      ...tokenColors,
    ];

    return copyWith(
      name: name ?? parent.name,
      type: type ?? parent.type,
      schema: schema ?? parent.schema,
      semanticHighlighting: semanticHighlighting ?? parent.semanticHighlighting,
      colors: mergedColors,
      tokenColors: mergedTokenColors,
      semanticTokenColors: mergedSemanticTokens,
    );
  }
}
