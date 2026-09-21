import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart';

/// Renders a single reflowable image node.
///
/// Decoded frames come from [ReflowableImageCache], so a page recreated by
/// pagination reflow paints its images on the first frame instead of flashing
/// a loading placeholder. Unresolved images show a static placeholder box (no
/// animated spinner — animation churn during re-layout is itself flicker).
class HyperReflowableImage extends StatefulWidget {
  const HyperReflowableImage({
    super.key,
    required this.node,
    required this.onResolveDecoded,
    this.initialDecoded,
  });

  final AtomicNode node;
  final ui.Image? initialDecoded;
  final Future<ui.Image?> Function() onResolveDecoded;

  @override
  State<HyperReflowableImage> createState() => _HyperReflowableImageState();
}

class _HyperReflowableImageState extends State<HyperReflowableImage> {
  ui.Image? _decoded;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _decoded = widget.initialDecoded;
    if (_decoded == null) {
      _resolveDecoded();
    }
  }

  @override
  void didUpdateWidget(covariant HyperReflowableImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.src != widget.node.src) {
      _decoded = null;
      _hasError = false;
      _resolveDecoded();
    } else if (_decoded == null && widget.initialDecoded != null) {
      _decoded = widget.initialDecoded;
      if (_hasError && _decoded != null) {
        _hasError = false;
      }
    }
  }

  Future<void> _resolveDecoded() async {
    final src = widget.node.src;
    if (src == null || src.isEmpty) {
      _hasError = true;
      return;
    }

    // External HTTP / HTTPS images are handled by Image.network, which has its
    // own platform image cache.
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return;
    }

    try {
      final decoded = await widget.onResolveDecoded();
      if (mounted) {
        // Persist real dimensions on the shared document node so later page
        // instances render this image at its true size from the first frame
        // (RenderHyperBox sizes fresh boxes from node.style before its
        // per-instance async decode lands). Mirrors HyperPageContent
        // seedImageDimensions — fills only the implicit dimensions.
        if (decoded != null) {
          final imgW = decoded.width.toDouble();
          final imgH = decoded.height.toDouble();
          if (widget.node.style.width == null &&
              widget.node.style.height == null) {
            widget.node.style.width = imgW;
            widget.node.style.height = imgH;
          } else if (widget.node.style.width != null &&
              widget.node.style.height == null) {
            widget.node.style.height = imgW > 0
                ? widget.node.style.width! * (imgH / imgW)
                : null;
          } else if (widget.node.style.width == null &&
              widget.node.style.height != null) {
            widget.node.style.width = imgH > 0
                ? widget.node.style.height! * (imgW / imgH)
                : null;
          }
        }
        setState(() {
          if (decoded != null) {
            _decoded = decoded;
          } else {
            _hasError = true;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
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
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _buildLoadingPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder();
        },
      );
    } else if (_decoded != null) {
      content = RawImage(
        image: _decoded!,
        fit: fit,
        filterQuality: FilterQuality.medium,
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

  /// Static, non-animated placeholder so pending images never pulse during the
  /// pagination re-layout that follows a decode.
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: const Color(0x08000000),
      child: const SizedBox.expand(),
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