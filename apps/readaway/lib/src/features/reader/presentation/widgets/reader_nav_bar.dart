import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reader_bloc.dart';

class ReaderNavBar extends StatelessWidget {
  const ReaderNavBar({
    super.key,
    required this.pageController,
  });

  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.htmlPages != curr.htmlPages ||
          prev.pageImages != curr.pageImages,
      builder: (context, state) {
        if (!state.hasDocument) return const SizedBox.shrink();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: state.currentPage > 0
                      ? () => pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        )
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous page',
                ),
                Text(
                  'Page ${state.currentPage + 1} of ${state.pageCount}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                IconButton.filledTonal(
                  onPressed: state.currentPage < state.pageCount - 1
                      ? () => pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
