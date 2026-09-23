import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';

extension UDTNodeExtensions on UDTNode {
  /// Enforces reader preferences (paragraph spacing, text indent, justification,
  /// line height, font overrides, and theme colors) across the entire document tree.
  void applyReaderPreferences({
    required ReaderPreferences prefs,
    required Color textColor,
    required Color linkColor,
  }) {
    _applyPreferencesRecursive(
      node: this,
      prefs: prefs,
      textColor: textColor,
      linkColor: linkColor,
      parentBlock: null,
    );
  }

  static void _applyPreferencesRecursive({
    required UDTNode node,
    required ReaderPreferences prefs,
    required Color textColor,
    required Color linkColor,
    required UDTNode? parentBlock,
  }) {
    // 0. Container sizing: Clear rigid heights/max-heights on non-atomic nodes.
    // EPubs often contain fixed height constraints on header/banner/wrapper blocks (e.g. height: 50px)
    // which overflow and throw RenderFlex layout assertion errors when rendered with custom
    // reader typography (font-size, line-height, text wrapping).
    if (node is! AtomicNode) {
      node.style.height = null;
      node.style.maxHeight = null;
      if (node.style.display == DisplayType.flex ||
          node.style.display == DisplayType.grid) {
        node.style.display = DisplayType.block;
      }
    }

    // 1. Link handling: links and their descendants always receive linkColor
    if (node.tagName == 'a') {
      node.applyColor(linkColor);
      return;
    }

    // 2. Color styling
    if (prefs.overrideColor) {
      node.style.color = textColor;
      node.style.markExplicitlySet('color');
    } else if (!node.style.isExplicitlySet('color')) {
      node.style.color = textColor;
    }

    // 3. Font override
    if (prefs.overrideFont) {
      node.style.fontFamily = prefs.resolvedFont;
      node.style.markExplicitlySet('font-family');
    }

    // 4. Block-level layout overrides
    UDTNode? currentBlock = parentBlock;
    if (node.isBlock) {
      currentBlock = node;

      if (prefs.overrideLayout) {
        final isParagraph = node.tagName == 'p' || node.tagName == 'dd';
        final isBlockquote = node.tagName == 'blockquote';
        final isListItem = node.tagName == 'li';

        if (isParagraph || isBlockquote || isListItem) {
          // Text alignment: apply the user's chosen alignment unless the book
          // explicitly set one AND keepTextAlignment is enabled.
          if (!prefs.keepTextAlignment ||
              !node.style.isExplicitlySet('text-align')) {
            node.style.textAlign = prefs.textAlign.toHyperTextAlign();
            node.style.markExplicitlySet('text-align');
          }

          // Line height, word spacing, letter spacing
          node.style.lineHeight = prefs.lineHeight;
          node.style.markExplicitlySet('line-height');
          node.style.wordSpacing = prefs.wordSpacing;
          node.style.letterSpacing = prefs.letterSpacing;
        }

        // 3. Font override or default propagation
        final effectiveFontSize =
            (node.style.isExplicitlySet('font-size') && !prefs.overrideFont)
            ? node.style.fontSize
            : prefs.fontSize;

        node.style.fontSize = effectiveFontSize;
        node.style.markExplicitlySet('font-size');

        if (prefs.overrideFont) {
          node.style.fontFamily = prefs.resolvedFont;
          node.style.markExplicitlySet('font-family');
          node.style.fontWeight = _fontWeightFromString(prefs.fontWeight);
          node.style.markExplicitlySet('font-weight');
        }

        // Minimum font size clamp: never render body text smaller than the
        // user's floor, even when the book specifies a tiny font-size.
        if (prefs.minimumFontSize > 0 &&
            node.style.fontSize < prefs.minimumFontSize) {
          node.style.fontSize = prefs.minimumFontSize;
          node.style.markExplicitlySet('font-size');
        }

        if (isParagraph) {
          // Paragraph Margin (vertical spacing between paragraphs)
          final vMargin = prefs.paragraphMargin * effectiveFontSize;
          node.style.margin = node.style.margin.copyWith(
            top: vMargin,
            bottom: vMargin,
          );
          node.style.markExplicitlySet('margin');

          // Text Indent: indent first line unless the paragraph is image-only
          final nonWhitespaceChildren = node.children.where((c) {
            if (c is TextNode) {
              return c.text.trim().isNotEmpty;
            }
            return true;
          }).toList();
          final isImageOnly =
              nonWhitespaceChildren.isNotEmpty &&
              nonWhitespaceChildren.every(
                (c) =>
                    c is AtomicNode &&
                    (c.tagName == 'img' || c.tagName == 'svg'),
              );

          if (isImageOnly) {
            node.style.textIndent = 0.0;
          } else {
            node.style.textIndent = prefs.textIndent * effectiveFontSize;
          }
          node.style.markExplicitlySet('text-indent');
        }
      }
    } else if (currentBlock != null) {
      // Child inline/text nodes: synchronize inheritable layout properties
      // so line-breaker / RenderHyperBoxLayout fragments directly receive the block's values.
      if (currentBlock.style.isExplicitlySet('text-align')) {
        node.style.textAlign = currentBlock.style.textAlign;
      }
      if (currentBlock.style.isExplicitlySet('text-indent')) {
        node.style.textIndent = currentBlock.style.textIndent;
      }
      if (currentBlock.style.isExplicitlySet('line-height')) {
        node.style.lineHeight = currentBlock.style.lineHeight;
      }

      // Font size: applyReaderPreferences sets the block font-size AFTER
      // resolveStyles, so text nodes still carry the pre-inheritance default.
      // Re-sync them with their containing block's font size (authored inline
      // sizes like `<span style="font-size:20px">` are preserved).
      if (!node.style.isExplicitlySet('font-size')) {
        node.style.fontSize = currentBlock.style.fontSize;
      }

      // CJK font: apply the user's CJK font to text runs containing CJK
      // characters (Han ideographs, kana, hangul). This is applied per text
      // node — mixed Latin/CJK nodes use the CJK font for the whole run, which
      // is visually acceptable since CJK fonts include Latin glyphs.
      if (node is TextNode &&
          prefs.defaultCjkFont.isNotEmpty &&
          _containsCjk(node.text)) {
        node.style.fontFamily = prefs.defaultCjkFont;
        node.style.markExplicitlySet('font-family');
      }
    }

    // 5. Recurse into children
    for (final child in node.children) {
      _applyPreferencesRecursive(
        node: child,
        prefs: prefs,
        textColor: textColor,
        linkColor: linkColor,
        parentBlock: currentBlock,
      );
    }
  }

  /// Sets the color recursively for this node and all of its descendants.
  void applyColor(Color color) {
    style.color = color;
    style.markExplicitlySet('color');

    for (final child in children) {
      child.applyColor(color);
    }
  }

  /// Legacy helper for applying primary text color and link color recursively.
  void applyTextColor({
    required Color textColor,
    required Color linkColor,
  }) {
    if (tagName == 'a') {
      applyColor(linkColor);
      return;
    }

    style.color = textColor;
    style.markExplicitlySet('color');

    for (final child in children) {
      child.applyTextColor(
        textColor: textColor,
        linkColor: linkColor,
      );
    }
  }
}

/// Maps the user-facing [ReaderTextAlign] onto hyper_render's [HyperTextAlign].
extension ReaderTextAlignX on ReaderTextAlign {
  HyperTextAlign toHyperTextAlign() {
    return switch (this) {
      ReaderTextAlign.left => HyperTextAlign.left,
      ReaderTextAlign.center => HyperTextAlign.center,
      ReaderTextAlign.right => HyperTextAlign.right,
      ReaderTextAlign.justify => HyperTextAlign.justify,
    };
  }
}

/// Resolves the effective font family, honoring the user's default-font choice
/// (serif vs sans-serif) when no explicit [ReaderPreferences.fontFamily] is set.
extension ReaderPreferencesFontX on ReaderPreferences {
  String get resolvedFont =>
      fontFamily ??
      (defaultFont == ReaderDefaultFont.serif ? serifFont : sansSerifFont);
}

/// Converts a CSS-style font-weight string (`normal`, `bold`, `lighter`,
/// `300`, `500`, …) into a Flutter [FontWeight].
FontWeight _fontWeightFromString(String weight) {
  return switch (weight) {
    'bold' || '700' => FontWeight.bold,
    'lighter' || '300' => FontWeight.w300,
    '500' => FontWeight.w500,
    '600' => FontWeight.w600,
    '200' => FontWeight.w200,
    _ => FontWeight.normal,
  };
}

/// Matches CJK ideographs (Han), kana, and hangul.
final RegExp _cjkRegex = RegExp(
  r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uac00-\ud7af\uf900-\ufaff]',
);

/// Returns true if [text] contains any CJK character.
bool _containsCjk(String text) => _cjkRegex.hasMatch(text);
