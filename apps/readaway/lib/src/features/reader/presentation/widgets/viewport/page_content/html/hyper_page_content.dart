import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

import '../../../../../../../core/theme/theme.dart';
import '../../../../../../settings/domain/entity/reader_preferences.dart';
import 'package:readaway/src/features/reader/presentation/extensions/hyper_html_extensions.dart';
import 'reader_style_resolver.dart';


/// Renders reflowable HTML content with HyperRender, fully styled according to [ReaderPreferences].
class HyperPageContent extends StatefulWidget {
  const HyperPageContent({
    super.key,
    required this.html,
    required this.prefs,
    required this.onLinkTap,
  });

  final String html;
  final ReaderPreferences prefs;
  final void Function(String) onLinkTap;

  @override
  State<HyperPageContent> createState() => _HyperPageContentState();
}

class _HyperPageContentState extends State<HyperPageContent> {
  late DocumentNode _document;
  late Color _textColor;
  late Color _linkColor;
  late Color _backgroundColor;
  bool _hasDependencies = false;

  final ReaderStyleResolver _styleResolver = const ReaderStyleResolver();
  final HtmlAdapter _htmlAdapter = HtmlAdapter();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final textColor = context.appColors.readerForeground;
    final linkColor = context.appColors.scheme.primary;
    final backgroundColor = context.appColors.readerBackground;

    if (!_hasDependencies ||
        textColor != _textColor ||
        linkColor != _linkColor ||
        backgroundColor != _backgroundColor) {
      _textColor = textColor;
      _linkColor = linkColor;
      _backgroundColor = backgroundColor;
      _document = _parseDocument();
      _hasDependencies = true;
    }
  }

  @override
  void didUpdateWidget(HyperPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html || oldWidget.prefs != widget.prefs) {
      setState(() => _document = _parseDocument());
    }
  }

  DocumentNode _parseDocument() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customCss = _styleResolver.buildCustomCss(
      prefs: widget.prefs,
      textColor: _textColor,
      backgroundColor: _backgroundColor,
      linkColor: _linkColor,
      isDarkMode: isDark,
    );

    // 1. Parse HTML into DocumentNode
    final document = _htmlAdapter.parse(widget.html);

    // 2. Extract embedded CSS from <style> tags in the chapter HTML
    final docCss = _htmlAdapter.extractCss(widget.html);

    // 3. Resolve CSS cascade: docCss first, customCss with !important rules second
    final combinedCss = docCss.isNotEmpty ? '$docCss\n$customCss' : customCss;
    final resolver = StyleResolver()..parseCss(combinedCss);
    resolver.resolveStyles(document);

    // 4. Enforce user layout preferences and theme colors directly on AST
    document.applyReaderPreferences(
      prefs: widget.prefs,
      textColor: _textColor,
      linkColor: _linkColor,
    );

    return document;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = _styleResolver.buildBaseTextStyle(
      prefs: widget.prefs,
      textColor: _textColor,
    );

    return HyperSelectionOverlay(
      key: ValueKey('hyper_page_${_document.hashCode}_${widget.prefs.hashCode}'),
      document: _document,
      selectable: true,
      config: const HyperRenderConfig(extraLinkSchemes: {''}),
      baseStyle: baseStyle,
      onLinkTap: widget.onLinkTap,
    );
  }
}

