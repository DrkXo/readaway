import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_overlay_controller.dart';

class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.pageController,
    required this.controller,
    this.onSettingsTap,
  });

  final PageController pageController;
  final ReaderOverlayController controller;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 250.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, 1),
          end: Offset.zero,
          duration: 250.ms,
          curve: Curves.easeOut,
        ),
      ],
      child: controller.barsVisible
          ? _buildContent(context)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) => prev.htmlPages != curr.htmlPages,
      builder: (context, state) {
        if (state.htmlPages == null) return const SizedBox.shrink();
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black26,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
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
                Expanded(
                  child: Text(
                    'Page ${state.currentPage + 1} of ${state.pageCount}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
                if (onSettingsTap != null)
                  IconButton.filledTonal(
                    onPressed: onSettingsTap,
                    icon: const Icon(Icons.settings),
                    tooltip: 'Reader settings',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
