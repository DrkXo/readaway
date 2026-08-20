import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_overlay_controller.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_page_counter.dart';

class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.controller,
  });

  final ReaderOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 250.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, -1),
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black26,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                context.read<ReaderBloc>().add(const ReaderEvent.closeDocument());
                GoRouter.of(context).pop();
              },
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
            Expanded(
              child: BlocBuilder<ReaderBloc, ReaderState>(
                buildWhen: (prev, curr) => prev.fileName != curr.fileName,
                builder: (context, state) {
                  return Text(
                    state.fileName ?? 'ReadAway',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            const ReaderPageCounter(),
          ],
        ),
      ),
    );
  }
}
