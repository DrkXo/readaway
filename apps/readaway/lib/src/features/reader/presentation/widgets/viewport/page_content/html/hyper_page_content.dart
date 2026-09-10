import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import '../../../../../../../core/theme/theme.dart';
import '../../../../extensions/hyper_html_extensions.dart';

/// Renders one reflowable HTML page with HyperRender.
class HyperPageContent extends StatefulWidget {
  const HyperPageContent({
    super.key,
    required this.html,
    required this.onLinkTap,
  });

  final String html;
  final void Function(String) onLinkTap;

  @override
  State<HyperPageContent> createState() => _HyperPageContentState();
}

class _HyperPageContentState extends State<HyperPageContent> {
  late DocumentNode _document;
  late Color _textColor;
  late Color _linkColor;
  bool _hasDependencies = false;

  final HtmlAdapter _htmlAdapter = HtmlAdapter();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final textColor = context.appColors.readerForeground;
    final linkColor = context.appColors.scheme.primary;
    if (!_hasDependencies ||
        textColor != _textColor ||
        linkColor != _linkColor) {
      _textColor = textColor;
      _linkColor = linkColor;
      _document = _parseDocument();
      _hasDependencies = true;
    }
  }

  @override
  void didUpdateWidget(HyperPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      setState(() => _document = _parseDocument());
    }
  }

  DocumentNode _parseDocument() {
    final document = _htmlAdapter.parse(widget.html);
    document.applyTextColor(
      textColor: _textColor,
      linkColor: _linkColor,
    );
    return document;
  }

  @override
  Widget build(BuildContext context) {
    return HyperSelectionOverlay(
      document: _document,
      selectable: true,
      config: const HyperRenderConfig(extraLinkSchemes: {''}),
      baseStyle: TextStyle(color: _textColor),
      onLinkTap: widget.onLinkTap,
    );
  }
}
