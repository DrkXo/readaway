import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/reader_bloc.dart';

class ReaderStatusBar extends StatelessWidget {
  const ReaderStatusBar({super.key, required this.readerBloc});

  final ReaderBloc readerBloc;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      bloc: readerBloc,
      buildWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount ||
          prev.fileName != curr.fileName ||
          prev.htmlPages != curr.htmlPages ||
          prev.pageImages != curr.pageImages,
      builder: (context, state) {
        if (!state.hasDocument) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        final progress = state.pageCount > 1
            ? state.currentPage / (state.pageCount - 1)
            : 0.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ],
        );
      },
    );
  }
}
