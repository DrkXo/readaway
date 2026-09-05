import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/reader_bloc.dart';

/// An image-based page item widget that lazily loads and renders fixed page content (PDF, CBZ, CBR).
///
/// Features:
/// - Lazy background page loading.
/// - Interactive pinch-to-zoom and pan support with bounded constraints.
class FixedImagePageItem extends StatefulWidget {
  const FixedImagePageItem({
    super.key,
    required this.index,
    required this.state,
    required this.onPageChangeRequested,
    this.isContinuous = false,
  });

  final int index;
  final ReaderState state;
  final void Function(int) onPageChangeRequested;
  final bool isContinuous;

  @override
  State<FixedImagePageItem> createState() => _FixedImagePageItemState();
}

class _FixedImagePageItemState extends State<FixedImagePageItem> {
  late final TransformationController _transformationController;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.state.pageImages != null &&
            widget.index < widget.state.pageImages!.length
        ? widget.state.pageImages![widget.index]
        : null;

    if (image == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final bloc = context.read<ReaderBloc>();
          if (!bloc.isClosed) {
            bloc.add(ReaderEvent.loadPage(index: widget.index));
          }
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    final imageWidget = RawImage(
      image: image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (widget.isContinuous) {
      final imageAspectRatio = image.width > 0 && image.height > 0
          ? image.width / image.height
          : 1.0;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: AspectRatio(
            aspectRatio: imageAspectRatio,
            child: imageWidget,
          ),
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: ClipRect(
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 1.0,
          maxScale: 4.0,
          panEnabled: _isZoomed,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: imageWidget,
            ),
          ),
        ),
      ),
    );
  }
}
