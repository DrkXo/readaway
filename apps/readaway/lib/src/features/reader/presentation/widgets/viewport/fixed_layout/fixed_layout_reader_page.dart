import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/features/reader/domain/repositories/reader_repository.dart';
import 'package:readaway/src/features/settings/domain/entity/reader_preferences.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../bloc/reader_bloc.dart';
import 'fixed_layout_image_cache.dart';

/// Renders an individual fixed-layout page (PDF, CBZ, CBR, CBT, CB7).
///
/// Supports interactive pinch-to-zoom (1.0x to 4.0x), animated double-tap
/// to zoom (1.0x <-> 2.5x), smooth image pre-fetching, and responsive layout.
class FixedLayoutReaderPage extends StatefulWidget {
  const FixedLayoutReaderPage({
    super.key,
    required this.index,
    required this.state,
    required this.prefs,
    this.isContinuous = false,
    this.onPageChangeRequested,
  });

  final int index;
  final ReaderState state;
  final ReaderPreferences prefs;
  final bool isContinuous;
  final ValueChanged<int>? onPageChangeRequested;

  @override
  State<FixedLayoutReaderPage> createState() => _FixedLayoutReaderPageState();
}

class _FixedLayoutReaderPageState extends State<FixedLayoutReaderPage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;

  Uint8List? _imageBytes;
  PageSize? _pageSize;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });

    final docPath = widget.state.documentPath;
    if (docPath != null) {
      final cache = FixedLayoutImageCache.instance;
      _imageBytes = cache.getCachedImage(docPath, widget.index);
      _pageSize = cache.getCachedSize(docPath, widget.index);
      _isLoading = _imageBytes == null;
    }

    _loadPageData();
  }

  @override
  void didUpdateWidget(FixedLayoutReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.state.documentPath != widget.state.documentPath) {
      final docPath = widget.state.documentPath;
      if (docPath != null) {
        final cache = FixedLayoutImageCache.instance;
        final cachedBytes = cache.getCachedImage(docPath, widget.index);
        final cachedSize = cache.getCachedSize(docPath, widget.index);
        if (cachedBytes != null) {
          _imageBytes = cachedBytes;
          _pageSize = cachedSize;
          _isLoading = false;
          _hasError = false;
        } else {
          _imageBytes = null;
          _pageSize = cachedSize;
          _isLoading = true;
          _hasError = false;
        }
      }
      _loadPageData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadPageData() async {
    final docPath = widget.state.documentPath;
    if (docPath == null) return;

    final repo = GetIt.I<ReaderRepository>();
    final cache = FixedLayoutImageCache.instance;

    // Check synchronous cache hit to avoid flashing loading UI
    final cachedBytes = cache.getCachedImage(docPath, widget.index);
    final cachedSize = cache.getCachedSize(docPath, widget.index);
    if (cachedBytes != null) {
      _imageBytes = cachedBytes;
      _pageSize = cachedSize;
      _isLoading = false;
      _hasError = false;
    } else if (mounted && _imageBytes == null) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    // Trigger pre-fetching of adjacent pages ($N-2, N-1, N+1, N+2$)
    cache.preloadAdjacent(
      repo,
      docPath,
      widget.index,
      widget.state.pageCount,
    );

    try {
      final sizeFuture = cache.getOrLoadSize(repo, docPath, widget.index);
      final imageFuture = cache.getOrLoadImage(repo, docPath, widget.index);

      final size = await sizeFuture;
      final bytes = await imageFuture;

      if (!mounted) return;

      if (bytes != null) {
        setState(() {
          _pageSize = size;
          _imageBytes = bytes;
          _isLoading = false;
          _hasError = false;
        });
      } else if (_imageBytes == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (_imageBytes == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final Matrix4 endMatrix;

    if (currentScale > 1.05) {
      // Zoom out to 1.0x
      endMatrix = Matrix4.identity();
    } else {
      // Zoom in to 2.5x centered at tap position
      const double targetScale = 2.5;
      final position = details.localPosition;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);

      endMatrix = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 1.0)
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
    }

    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading && _imageBytes == null) {
      Widget placeholder = const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

      if (_pageSize != null && _pageSize!.width > 0 && _pageSize!.height > 0) {
        placeholder = AspectRatio(
          aspectRatio: _pageSize!.aspectRatio,
          child: Container(
            color: appColors.readerBackground,
            child: placeholder,
          ),
        );
      }

      return Center(child: placeholder);
    }

    if (_hasError || _imageBytes == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.imageOff,
              size: 40,
              color: scheme.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load page ${widget.index + 1}',
              style: TextStyle(
                color: appColors.sidebarForeground.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadPageData,
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    Widget content = Image.memory(
      _imageBytes!,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => child,
    );

    if (_pageSize != null && _pageSize!.width > 0 && _pageSize!.height > 0) {
      content = AspectRatio(
        aspectRatio: _pageSize!.aspectRatio,
        child: content,
      );
    }

    if (widget.isContinuous) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        alignment: Alignment.center,
        child: content,
      );
    }

    return GestureDetector(
      onDoubleTapDown: _handleDoubleTap,
      onDoubleTap: () {}, // Required to activate onDoubleTapDown
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        clipBehavior: Clip.none,
        child: Center(
          child: content,
        ),
      ),
    );
  }
}
