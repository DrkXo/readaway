import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/reader_bloc.dart';

/// An image-based page item widget that lazily loads page content.
class FixedImagePageItem extends StatelessWidget {
  const FixedImagePageItem({
    super.key,
    required this.index,
    required this.state,
    required this.onPageChangeRequested,
  });

  final int index;
  final ReaderState state;
  final void Function(int) onPageChangeRequested;

  @override
  Widget build(BuildContext context) {
    final image = state.pageImages != null && index < state.pageImages!.length
        ? state.pageImages![index]
        : null;

    if (image == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final bloc = context.read<ReaderBloc>();
          if (!bloc.isClosed) {
            bloc.add(ReaderEvent.loadPage(index: index));
          }
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: RawImage(image: image, fit: BoxFit.contain),
    );
  }
}
