import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
    this.onResolveAssetBytes,
  });

  final String html;
  final ReaderPreferences prefs;
  final void Function(String) onLinkTap;
  final Future<List<int>?> Function(String src)? onResolveAssetBytes;

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
  final Map<String, Uint8List> _assetBytesCache = {};
  final Map<String, Future<Uint8List?>> _inFlightAssetRequests = {};

  Future<Uint8List?> _resolveAssetBytes(String src) {
    final cached = _assetBytesCache[src];
    if (cached != null) return Future.value(cached);

    final inFlight = _inFlightAssetRequests[src];
    if (inFlight != null) return inFlight;

    if (widget.onResolveAssetBytes == null) {
      return Future.value(null);
    }

    final future = () async {
      try {
        final raw = await widget.onResolveAssetBytes!(src);
        if (raw != null && raw.isNotEmpty) {
          final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
          _assetBytesCache[src] = bytes;
          return bytes;
        }
        return null;
      } finally {
        _inFlightAssetRequests.remove(src);
      }
    }();

    _inFlightAssetRequests[src] = future;
    return future;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appColors =
        Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);
    final textColor = appColors.readerForeground;
    final linkColor = appColors.scheme.primary;
    final backgroundColor = appColors.readerBackground;

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

    // Pre-process HTML to convert SVG image wrappers (commonly used for EPUB covers) into <img> tags
    final processedHtml = _preprocessHtml(widget.html);

    // 1. Parse HTML into DocumentNode
    final document = _htmlAdapter.parse(processedHtml);

    // 2. Extract embedded CSS from <style> tags in the chapter HTML
    final docCss = _htmlAdapter.extractCss(processedHtml);

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

  /// Converts `<svg ...><image ... /></svg>` and standalone `<image ...>` tags
  /// (commonly generated for cover pages by Calibre, InDesign, Sigil, etc.)
  /// into standard `<img>` tags so [HtmlAdapter] parses them into image nodes.
  String _preprocessHtml(String rawHtml) {
    if (rawHtml.isEmpty) return rawHtml;

    // 1. Convert <svg ...><image ... xlink:href/href="..." .../></svg> blocks into <img> tags
    var result = rawHtml.replaceAllMapped(
      RegExp(r'<svg[^>]*>[\s\S]*?<\/svg>', caseSensitive: false),
      (svgMatch) {
        final svgContent = svgMatch.group(0)!;
        final imgMatches = RegExp(
          r'<image[^>]+(?:xlink:href|href)=[\x27\x22]([^\x27\x22]+)[\x27\x22][^>]*>',
          caseSensitive: false,
        ).allMatches(svgContent);

        if (imgMatches.isEmpty) return svgContent;

        final buffer = StringBuffer();
        for (final m in imgMatches) {
          final src = m.group(1);
          if (src != null && src.isNotEmpty) {
            buffer.write(
              '<img src="$src" style="max-width: 100%; height: auto;" />',
            );
          }
        }
        return buffer.toString();
      },
    );

    // 2. Convert any standalone <image ...> tags into <img>
    result = result.replaceAllMapped(
      RegExp(
        r'<image[^>]+(?:xlink:href|href)=[\x27\x22]([^\x27\x22]+)[\x27\x22][^>]*>(?:<\/image>)?',
        caseSensitive: false,
      ),
      (match) {
        final src = match.group(1);
        return '<img src="$src" style="max-width: 100%; height: auto;" />';
      },
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = _styleResolver.buildBaseTextStyle(
      prefs: widget.prefs,
      textColor: _textColor,
    );

    return HyperSelectionOverlay(
      key: ValueKey(
        'hyper_page_${_document.hashCode}_${widget.prefs.hashCode}',
      ),
      document: _document,
      selectable: true,
      config: const HyperRenderConfig(extraLinkSchemes: {''}),
      imageLoader: widget.onResolveAssetBytes != null ? _handleImageLoad : null,
      widgetBuilder: _buildCustomWidget,
      baseStyle: baseStyle,
      onLinkTap: widget.onLinkTap,
    );
  }

  Widget? _buildCustomWidget(UDTNode node) {
    if (node is AtomicNode && node.tagName == 'img') {
      final src = node.src;
      if (src == null || src.isEmpty) return null;

      // Float images are painted on canvas by RenderHyperBox._paintFloatImages
      if (node.style.float != HyperFloat.none) return null;

      return _HyperReflowableImage(
        key: ValueKey('hyper_img_${node.hashCode}_$src'),
        node: node,
        initialBytes: _assetBytesCache[src],
        onResolveBytes: () => _resolveAssetBytes(src),
      );
    }
    return null;
  }

  Future<void> _handleImageLoad(
    String src,
    void Function(ui.Image) onLoad,
    void Function(Object) onError,
  ) async {
    if (src.startsWith('http://') || src.startsWith('https://')) {
      defaultImageLoader(src, onLoad, onError);
      return;
    }

    if (widget.onResolveAssetBytes == null) {
      debugPrint('[HyperPageContent] No asset resolver configured for $src');
      onError('No asset resolver configured');
      return;
    }
    try {
      final bytes = await _resolveAssetBytes(src);
      if (bytes != null && bytes.isNotEmpty) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        onLoad(frame.image);
      } else {
        debugPrint('[HyperPageContent] Asset bytes empty for $src');
        onError('Asset bytes empty for $src');
      }
    } catch (e, stack) {
      debugPrint('[HyperPageContent] Failed to decode image $src: $e\n$stack');
      onError(e);
    }
  }
}

class _HyperReflowableImage extends StatefulWidget {
  const _HyperReflowableImage({
    super.key,
    required this.node,
    required this.onResolveBytes,
    this.initialBytes,
  });

  final AtomicNode node;
  final Uint8List? initialBytes;
  final Future<Uint8List?> Function() onResolveBytes;

  @override
  State<_HyperReflowableImage> createState() => _HyperReflowableImageState();
}

class _HyperReflowableImageState extends State<_HyperReflowableImage> {
  Uint8List? _bytes;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _bytes = widget.initialBytes;
    if (_bytes == null) {
      _resolveImageBytes();
    }
  }

  @override
  void didUpdateWidget(covariant _HyperReflowableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.src != widget.node.src) {
      _bytes = widget.initialBytes;
      _hasError = false;
      if (_bytes == null) {
        _resolveImageBytes();
      }
    } else if (_bytes == null && widget.initialBytes != null) {
      _bytes = widget.initialBytes;
    }
  }

  Future<void> _resolveImageBytes() async {
    final src = widget.node.src;
    if (src == null || src.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    // 1. External HTTP / HTTPS image (handled by Image.network)
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return;
    }

    // 2. Data URI (data:image/...;base64,...)
    if (src.startsWith('data:')) {
      final commaIndex = src.indexOf(',');
      if (commaIndex != -1) {
        try {
          final decoded = base64Decode(src.substring(commaIndex + 1));
          final uint8 = Uint8List.fromList(decoded);
          if (mounted) {
            setState(() => _bytes = uint8);
          }
          return;
        } catch (_) {
          if (mounted) setState(() => _hasError = true);
          return;
        }
      }
    }

    // 3. Document / EPUB container asset
    try {
      final bytes = await widget.onResolveBytes();
      if (bytes != null && bytes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _bytes = bytes;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  BoxFit _getBoxFit(String? objectFit) {
    switch (objectFit?.toLowerCase()) {
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'none':
        return BoxFit.none;
      case 'scale-down':
        return BoxFit.scaleDown;
      default:
        return BoxFit.contain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final src = widget.node.src;
    final borderRadius = widget.node.style.borderRadius;
    final fit = _getBoxFit(widget.node.style.objectFit);

    Widget content;

    if (src == null || src.isEmpty || _hasError) {
      content = _buildErrorPlaceholder();
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      content = Image.network(
        src,
        fit: fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else if (_bytes != null) {
      content = Image.memory(
        _bytes!,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else {
      content = _buildLoadingPlaceholder();
    }

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: content,
      );
    }

    return content;
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: const Color(0x08000000),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: const Color(0x0D000000),
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 28,
          color: Color(0x66000000),
        ),
      ),
    );
  }
}
