import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/services/window_service.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../router/router.dart';
import '../../../../annotations/presentation/widgets/reader_bookmark_button.dart';
import '../../bloc/reader_bloc.dart';
import '../overlay/reader_share_sheet.dart';

/// Top bar displayed when a reader document is open.
///
/// Designed with flat non-circular Lumia Metro aesthetics:
/// - Crisp typography with lowercase progress readout
/// - Flat [MetroPressable] actions (Close, Bookmark, Share, Settings)
/// - Desktop frameless window dragging and caption controls
/// - Zero border radius with 1px hairline bottom separator
class ReaderTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ReaderTopBar({
    super.key,
    this.onOpenDrawer,
    this.onCloseDocument,
  });

  final VoidCallback? onOpenDrawer;
  final VoidCallback? onCloseDocument;

  static const double desktopHeight = 42.0;
  static const double mobileHeight = 54.0;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Size get preferredSize => Size.fromHeight(
    _isDesktop ? desktopHeight : mobileHeight,
  );

  void _handleClose(BuildContext context) {
    if (onCloseDocument != null) {
      onCloseDocument!();
    } else {
      context.read<ReaderBloc>().add(const ReaderEvent.closeDocument());
      try {
        if (context.canPop()) {
          context.pop();
          return;
        }
      } catch (_) {
        if (Navigator.maybeOf(context)?.canPop() ?? false) {
          Navigator.of(context).pop();
          return;
        }
      }
      if (GetIt.I.isRegistered<AppRouter>()) {
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
          prev.displayCurrentPage != curr.displayCurrentPage ||
          prev.displayPageCount != curr.displayPageCount,
      builder: (context, state) {
        if (!state.hasDocument) return const SizedBox.shrink();

        final appColors = context.appColors;
        final isDesktop = _isDesktop;
        final barHeight = preferredSize.height;
        final windowService = GetIt.I.isRegistered<WindowService>()
            ? GetIt.I<WindowService>()
            : null;

        final title = state.bookTitle ?? state.fileName ?? 'Document';
        final progress = state.displayPageCount > 0
            ? 'page ${state.displayCurrentPage + 1} of ${state.displayPageCount}'
            : null;

        return Container(
          height: isDesktop ? barHeight : null,
          decoration: BoxDecoration(
            color: appColors.topbarBackground,
            border: Border(
              bottom: BorderSide(
                color: appColors.topbarBorder,
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            top: !isDesktop,
            child: SizedBox(
              height: barHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Leading flat close button
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Tooltip(
                      message: 'Close document',
                      child: Semantics(
                        label: 'Close document',
                        button: true,
                        child: MetroPressable(
                          onTap: () => _handleClose(context),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              LucideIcons.arrowLeft,
                              size: 18,
                              color: appColors.topbarForeground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Title and draggable window area
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: isDesktop && windowService != null
                          ? (_) => windowService.startDragging()
                          : null,
                      onDoubleTap: isDesktop && windowService != null
                          ? windowService.toggleMaximize
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isDesktop ? 13.5 : 15.0,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                                color: appColors.topbarForeground,
                              ),
                            ),
                            if (progress != null)
                              Text(
                                progress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                  color: appColors.topbarForeground.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Actions: Bookmark, Share, Settings
                  ReaderBookmarkButton(
                    isReflowable: state.isReflowable,
                    currentPage: state.currentPage,
                    currentVirtualPage: state.currentVirtualPage,
                  ),

                  Tooltip(
                    message: 'Share document or page',
                    child: Semantics(
                      label: 'Share document or page',
                      button: true,
                      child: MetroPressable(
                        onTap: () => ReaderShareSheet.show(
                          context: context,
                          state: context.read<ReaderBloc>().state,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 6.0,
                          ),
                          child: Icon(
                            LucideIcons.share2,
                            size: 18,
                            color: appColors.topbarForeground.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Tooltip(
                    message: 'Reader options',
                    child: Semantics(
                      label: 'Reader options',
                      button: true,
                      child: MetroPressable(
                        onTap: () {
                          final path = state.documentPath;
                          appRouter.push(
                            path != null
                                ? '${appRoutes.settings.path}'
                                      '?documentPath=${Uri.encodeComponent(path)}'
                                : appRoutes.settings.path,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 6.0,
                          ),
                          child: Icon(
                            LucideIcons.sliders,
                            size: 18,
                            color: appColors.topbarForeground.withValues(
                              alpha: 0.75,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Desktop Window Caption Controls
                  if (isDesktop && windowService != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      height: 18,
                      width: 1,
                      color: appColors.topbarBorder,
                    ),
                    WindowCaptionControls(
                      service: windowService,
                      height: barHeight,
                    ),
                  ] else ...[
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
