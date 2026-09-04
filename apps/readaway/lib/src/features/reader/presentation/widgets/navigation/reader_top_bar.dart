import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/services.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../router/router.dart';
import '../../bloc/reader_bloc.dart';

/// Top bar displayed when a reader document is open.
///
/// Automatically adapts to:
/// - Android: Close document + Title/Progress + Reader options (Outline, TTS) + Settings
/// - Desktop: Close document + Title/Progress + Draggable window area + Reader options + Settings + Window caption icons
class ReaderTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ReaderTopBar({
    super.key,
    this.onOpenDrawer,
    this.onCloseDocument,
  });

  final VoidCallback? onOpenDrawer;
  final VoidCallback? onCloseDocument;

  bool get _isDesktop => GetIt.I<WindowService>().isDesktop;

  @override
  Size get preferredSize => Size.fromHeight(
    _isDesktop ? AppTopBar.desktopHeight : AppTopBar.mobileHeight,
  );

  void _handleClose(BuildContext context) {
    if (onCloseDocument != null) {
      onCloseDocument!();
    } else {
      context.read<ReaderBloc>().add(const ReaderEvent.closeDocument());
      if (context.canPop()) {
        context.pop();
      } else {
        appRouter.goNamed(appRoutes.library.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.hasDocument != curr.hasDocument ||
          prev.bookTitle != curr.bookTitle ||
          prev.fileName != curr.fileName ||
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount ||
          prev.isReflowable != curr.isReflowable ||
          prev.ttsActive != curr.ttsActive,
      builder: (context, state) {
        if (!state.hasDocument) return const SizedBox.shrink();

        final title = state.bookTitle ?? state.fileName ?? 'Document';
        final progress = state.pageCount > 0
            ? 'Page ${state.currentPage + 1} of ${state.pageCount}'
            : null;

        return AppTopBar(
          height: preferredSize.height,
          leading: AppIconButton(
            icon: LucideIcons.x,
            tooltip: 'Close document',
            size: AppIconButtonSize.small,
            onPressed: () => _handleClose(context),
          ),
          titleText: title,
          subtitleText: progress,
          settingsTooltip: 'Reader options',
          actions: [],
        );
      },
    );
  }
}
