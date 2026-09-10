import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

extension UDTNodeExtensions on UDTNode {
  /// Applies primary text color and link color recursively throughout the node tree.
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

  /// Sets the color recursively for this node and all of its descendants.
  void applyColor(Color color) {
    style.color = color;
    style.markExplicitlySet('color');

    for (final child in children) {
      child.applyColor(color);
    }
  }
}
