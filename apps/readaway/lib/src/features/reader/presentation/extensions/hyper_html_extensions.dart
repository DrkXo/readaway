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
      final font = prefs.fontFamily ?? prefs.serifFont;
      node.style.fontFamily = font;
      node.style.markExplicitlySet('font-family');
    }

    // 4. Block-level layout overrides
    UDTNode? currentBlock = parentBlock;
    if (node.isBlock) {
      currentBlock = node;

      if (prefs.overrideLayout) {
        final isParagraph = node.tagName == 'p' || node.tagName == 'dd';
        final isBlockquote = node.tagName == 'blockquote';

        if (isParagraph || isBlockquote) {
          // Text alignment / Justification
          final align = prefs.fullJustification ? HyperTextAlign.justify : HyperTextAlign.left;
          node.style.textAlign = align;
          node.style.markExplicitlySet('text-align');

          // Line height, word spacing, letter spacing
          node.style.lineHeight = prefs.lineHeight;
          node.style.markExplicitlySet('line-height');
          node.style.wordSpacing = prefs.wordSpacing;
          node.style.letterSpacing = prefs.letterSpacing;
        }

        // 3. Font override or default propagation
        final effectiveFontSize = (node.style.isExplicitlySet('font-size') && !prefs.overrideFont)
            ? node.style.fontSize
            : prefs.fontSize;

        if (prefs.overrideFont) {
          final font = prefs.fontFamily ?? prefs.serifFont;
          node.style.fontFamily = font;
          node.style.markExplicitlySet('font-family');
          node.style.fontSize = effectiveFontSize;
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
          final isImageOnly = nonWhitespaceChildren.isNotEmpty &&
              nonWhitespaceChildren.every((c) => c is AtomicNode && (c.tagName == 'img' || c.tagName == 'svg'));

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

