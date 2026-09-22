import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';
import 'package:readaway/src/features/reader/presentation/extensions/hyper_html_extensions.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../../../core/theme/theme.dart';
import '../../../../../../../core/utils/lru_cache.dart';
import '../../../../../../settings/domain/entity/reader_preferences.dart';
import 'reader_style_resolver.dart';
import 'reflowable_image_cache.dart';
import 'widgets/hyper_reflowable_image.dart';

/// Renders reflowable HTML content with HyperRender, fully styled according to [ReaderPreferences].
class HyperPageContent extends StatefulWidget {
  const HyperPageContent({
    super.key,
    required this.html,
    required this.prefs,
    required this.chapterIndex,
    required this.onLinkTap,
    this.cacheNamespace = '',
    this.onResolveAssetBytes,
  });

  final String html;
  final ReaderPreferences prefs;

  /// Chapter index this content belongs to. Part of the shared image-cache key.
  final int chapterIndex;

  /// Identifies the current document so cached images from one book never
  /// leak into the next (chapter indices and asset paths repeat).
  final String cacheNamespace;

  final void Function(String) onLinkTap;
  final Future<List<int>?> Function(String src)? onResolveAssetBytes;

  /// Stamps the real pixel dimensions of already-decoded images onto the
  /// (shared) document nodes so RenderHyperBox lays them out at their true
  /// size on the very first frame of a freshly created page.
  ///
  /// Without this, every new page instance creates a RenderHyperBox with an
  /// empty internal image cache, so each `<img>` is first sized at the 200×112
  /// placeholder and only jumps to its real size after an async per-instance
  /// decode + re-layout — the size jump visible as flicker on page changes.
  static void seedImageDimensions(
    DocumentNode document, {
    required String cacheNamespace,
    required int chapterIndex,
  }) {
    final cache = ReflowableImageCache.instance;
    document.traverse((node) {
      if (node is! AtomicNode || node.tagName != 'img') return;
      final src = node.src;
      if (src == null || src.isEmpty) return;
      final image = cache.peekDecoded(cacheNamespace, chapterIndex, src);
      if (image == null) return;
      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();
      // Fill only dimensions the document itself never specified; explicit
      // CSS keeps priority. Mirrors RenderHyperBox's loaded-image sizing so a
      // fresh box lays out at the real size from its first frame instead of
      // the 200×112 (or 16:9) placeholder, which jumps on every page change.
      final styleWidth = node.style.width;
      final styleHeight = node.style.height;
      if (styleWidth == null && styleHeight == null) {
        node.style.width = imgW;
        node.style.height = imgH;
      } else if (styleWidth != null && styleHeight == null) {
        node.style.height = imgW > 0 ? styleWidth * (imgH / imgW) : null;
      } else if (styleWidth == null && styleHeight != null) {
        node.style.width = imgH > 0 ? styleHeight * (imgW / imgH) : null;
      }
    });
  }

  @override
  State<HyperPageContent> createState() => _HyperPageContentState();
}

class _HyperPageContentState extends State<HyperPageContent> {
  static final LruCache<String, String> _transformedHtmlCache =
      LruCache<String, String>(maximumSize: 40);

  /// Cache of fully parsed, CSS-resolved, preference-styled documents.
  /// Multiple page instances of the same chapter (page transitions, adjacent
  /// virtual pages, continuous-scroll chapters) share one immutable
  /// [DocumentNode]; HyperRender only reads the tree during build/layout.
  static final LruCache<String, DocumentNode> _documentCache =
      LruCache<String, DocumentNode>(maximumSize: 40);

  String _buildDocumentCacheKey() {
    // prefs.hashCode is value-based (freezed). prefs.toJson().hashCode was
    // identity-based on a fresh Map, so the cache never hit and every
    // color/prefs/theme change re-parsed the document and re-created every
    // image widget.
    final prefs = widget.prefs;
    final prefsSig = prefs.hashCode;
    return '${widget.html.length}:${widget.html.hashCode}:$prefsSig:'
        '${_textColor.toARGB32()}:${_linkColor.toARGB32()}:'
        '${Theme.of(context).brightness == Brightness.dark}';
  }

  late DocumentNode _document;
  late Color _textColor;
  late Color _linkColor;
  late Color _backgroundColor;
  bool _hasDependencies = false;

  final ReaderStyleResolver _styleResolver = const ReaderStyleResolver();
  final HtmlAdapter _htmlAdapter = HtmlAdapter();

  Future<Uint8List?> _loadBytesFor(String src) async {
    final onResolve = widget.onResolveAssetBytes;
    if (onResolve == null) return null;
    final raw = await onResolve(src);
    if (raw == null) return null;
    return raw is Uint8List ? raw : Uint8List.fromList(raw);
  }

  Future<Uint8List?> _resolveAssetBytes(String src) {
    // Shared, namespace-scoped cache: a page recreated by pagination reflow
    // resolves bytes synchronously instead of re-fetching from the container.
    return ReflowableImageCache.instance.resolveBytes(
      widget.cacheNamespace,
      widget.chapterIndex,
      src,
      load: () => _loadBytesFor(src),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appColors = context.appColors;
    final textColor = appColors.readerForeground;
    final linkColor = appColors.badgeBackground ?? appColors.scheme.primary;
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
    final cacheKey = _buildDocumentCacheKey();
    final cached = _documentCache[cacheKey];
    if (cached != null) return cached;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customCss = _styleResolver.buildCustomCss(
      prefs: widget.prefs,
      textColor: _textColor,
      backgroundColor: _backgroundColor,
      linkColor: _linkColor,
      isDarkMode: isDark,
    );

    final cachedKey =
        '${widget.html.length}:${widget.html.hashCode}_${widget.prefs.overrideLayout}';
    var processedHtml = _transformedHtmlCache[cachedKey];
    if (processedHtml == null) {
      // Pre-process HTML to convert SVG image wrappers (commonly used for EPUB covers) into <img> tags
      final preprocessedHtml = _preprocessHtml(widget.html);

      // Apply pre-render natural reading text transformations
      final transformCtx = TransformContext(
        content: preprocessedHtml,
        overrideLayout: widget.prefs.overrideLayout,
      );
      processedHtml = TextTransformPipeline.defaultPipeline.transform(
        transformCtx,
      );
      _transformedHtmlCache[cachedKey] = processedHtml;
    }

    // 1. Parse HTML into DocumentNode
    final document = _htmlAdapter.parse(processedHtml);

    // 2. Extract embedded CSS from <style> tags in the chapter HTML
    final docCss = _htmlAdapter.extractCss(processedHtml);

    // 3. Resolve CSS cascade: base (px element sizes derived from the reader's
    // font size) first, then doc CSS so authored rules win at equal
    // specificity, then customCss (with !important overrides), then the
    // user's custom stylesheet with highest precedence.
    final baseCss = _styleResolver.buildBaseCss(prefs: widget.prefs);
    final userCss = widget.prefs.userStylesheet.trim();
    final combinedCss = [
      baseCss,
      if (docCss.isNotEmpty) docCss,
      customCss,
      if (userCss.isNotEmpty) userCss,
    ].join('\n');
    final resolver = StyleResolver()..parseCss(combinedCss);
    resolver.resolveStyles(document);

    // 4. Enforce user layout preferences and theme colors directly on AST
    document.applyReaderPreferences(
      prefs: widget.prefs,
      textColor: _textColor,
      linkColor: _linkColor,
    );

    HyperPageContent.seedImageDimensions(
      document,
      cacheNamespace: widget.cacheNamespace,
      chapterIndex: widget.chapterIndex,
    );
    _documentCache[cacheKey] = document;
    return document;
  }

  /// Converts `<svg ...><image ... /></svg>` and standalone `<image ...>` tags
  /// (commonly generated for cover pages by Calibre, InDesign, Sigil, etc.)
  /// into standard `<img>` tags so [HtmlAdapter] parses them into image nodes.
  String _preprocessHtml(String rawHtml) {
    if (rawHtml.isEmpty) return rawHtml;
    final lower = rawHtml.toLowerCase();
    if (!lower.contains('<svg') && !lower.contains('<image')) {
      return rawHtml;
    }

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

      final cache = ReflowableImageCache.instance;
      final chapterIndex = widget.chapterIndex;
      return HyperReflowableImage(
        // node.id (not hashCode) is stable for the lifetime of the cached
        // DocumentNode, so image state survives rebuilds within a chapter.
        key: ValueKey('hyper_img_${node.id}_$src'),
        node: node,
        initialDecoded: cache.peekDecoded(
          widget.cacheNamespace,
          chapterIndex,
          src,
        ),
        onResolveDecoded: () => cache.decode(
          widget.cacheNamespace,
          chapterIndex,
          src,
          load: () => _loadBytesFor(src),
        ),
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
