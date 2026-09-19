import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hyper_render/hyper_render.dart';

/// Renders a single reflowable image node, resolving bytes from the
/// document/EPUB container, data URIs, or the network, with loading and
/// error placeholders.
class HyperReflowableImage extends StatefulWidget {
  const HyperReflowableImage({
    super.key,
    required this.node,
    required this.onResolveBytes,
    this.initialBytes,
  });

  final AtomicNode node;
  final Uint8List? initialBytes;
  final Future<Uint8List?> Function() onResolveBytes;

  @override
  State<HyperReflowableImage> createState() => _HyperReflowableImageState();
}

class _HyperReflowableImageState extends State<HyperReflowableImage> {
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
  void didUpdateWidget(covariant HyperReflowableImage oldWidget) {
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
      child: Center(
        child: SpinKitPulsingGrid(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          size: 20,
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