import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_overlay_controller.dart';

import '../../../../core/routes/routes.dart';
import '../../../../router/router.dart';

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
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
          duration: 200.ms,
          curve: Curves.easeOut,
        ),
      ],
      child: controller.barsVisible
          ? _buildContent(context)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        color: scheme.surface.withValues(alpha: 0.85),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(
                Icons.more_vert_outlined,
              ),
              tooltip: 'Outline',
            ),
            const SizedBox(width: 4),
            Expanded(child: _buildTitle(context)),
            Spacer(),
            IconButton(
              onPressed: () {
                context.read<ReaderBloc>().add(
                  const ReaderEvent.closeDocument(),
                );
                appRouter.goNamed(appRoutes.library.name);
              },
              icon: Icon(
                Icons.close,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.fileName != curr.fileName ||
          prev.currentPage != curr.currentPage ||
          prev.outline != curr.outline,
      builder: (context, state) {
        final pageTitle = _pageTitleForCurrentPage(state);
        return AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              pageTitle ?? '',
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                overflow: TextOverflow.fade,
              ),
            ),
          ],
          totalRepeatCount: 1,
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
        );
      },
    );
  }

  String? _pageTitleForCurrentPage(ReaderState state) {
    if (state.outline == null || state.outline!.isEmpty) return null;
    final current = state.currentPage;
    for (final item in state.outline!) {
      if (item.page == current &&
          item.title != null &&
          item.title!.isNotEmpty) {
        return item.title;
      }
    }
    return null;
  }
}
