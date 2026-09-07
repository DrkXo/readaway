import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/services/services.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../library/domain/entity/reading_status.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../../settings/domain/entity/reader_preferences.dart';
import '../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../domain/gestures/reader_gestures.dart';
import '../bloc/reader_bloc.dart';
import '../controllers/reader_page_view_controller.dart';
import '../widgets/widgets.dart';

part '../mixins/reader_page_mixins.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    this.initialPath,
    this.initialFileName,
  });

  factory ReaderPage.fromRoute(GoRouterState state) {
    return ReaderPage(
      initialPath: state.uri.queryParameters['path'],
      initialFileName: state.uri.queryParameters['fileName'],
    );
  }

  final String? initialPath;
  final String? initialFileName;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with ReaderControllerMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'reader_content_key');

  bool _tocPinned = false;
  bool get isDesktop => GetIt.I<WindowService>().isDesktop;

  @override
  void initState() {
    super.initState();
    initReaderState();
  }

  @override
  void dispose() {
    disposeReaderState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (prev, curr) =>
              prev.appSettings.screenWakeLock !=
              curr.appSettings.screenWakeLock,
          listener: (context, state) => syncSettings(state),
        ),
        BlocListener<ReaderBloc, ReaderState>(
          listenWhen: (prev, curr) =>
              curr.transientFeedback != null &&
              prev.transientFeedback != curr.transientFeedback,
          listener: (context, state) {
            final feedback = state.transientFeedback;
            if (feedback != null) {
              final actionRoute = feedback.actionRoute;
              final actionLabel = feedback.actionLabel;
              context.read<ReaderBloc>().add(
                const ReaderEvent.consumeFeedback(),
              );

              context.toasts.show(
                message: feedback.failure.message,
                type: ToastType.warning,
                duration: const Duration(seconds: 5),
                action: actionLabel != null
                    ? ToastAction(
                        label: actionLabel,
                        onPressed: () {
                          if (actionRoute != null) {
                            context.push(actionRoute);
                          }
                        },
                      )
                    : null,
              );
            }
          },
        ),
      ],
      child: BlocBuilder<ReaderBloc, ReaderState>(
        buildWhen: (prev, curr) =>
            prev.failure != curr.failure || prev.fileName != curr.fileName,
        builder: (context, readerState) {
          if (readerState.failure != null) {
            return Scaffold(
              backgroundColor: context.appColors.readerBackground,
              appBar: AppTopBar(
                titleText: readerState.fileName ?? 'Document Error',
                leading: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  tooltip: 'Return to Library',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(appRoutes.library.path);
                    }
                  },
                ),
              ),
              body: const SafeArea(
                child: Center(
                  child: ReaderErrorView(),
                ),
              ),
            );
          }

          return BlocBuilder<SettingsBloc, SettingsState>(
            buildWhen: (prev, curr) =>
                prev.globalReaderPrefs != curr.globalReaderPrefs,
            builder: (context, settingsState) {
              final prefs = settingsState.globalReaderPrefs;

              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) closeReader();
                },
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowLeft):
                        pageViewController.previousPage,
                    const SingleActivator(LogicalKeyboardKey.arrowRight):
                        pageViewController.nextPage,
                    const SingleActivator(LogicalKeyboardKey.arrowUp):
                        pageViewController.previousPage,
                    const SingleActivator(LogicalKeyboardKey.arrowDown):
                        pageViewController.nextPage,
                    const SingleActivator(LogicalKeyboardKey.pageUp):
                        pageViewController.previousPage,
                    const SingleActivator(LogicalKeyboardKey.pageDown):
                        pageViewController.nextPage,
                  },
                  child: Focus(
                    autofocus: true,
                    child: Scaffold(
                      key: _scaffoldKey,
                      drawer: ReaderDrawer(
                        onJumpToPage: (page) {
                          if (_scaffoldKey.currentState?.isDrawerOpen ??
                              false) {
                            _scaffoldKey.currentState?.closeDrawer();
                          }
                          jumpToPage(page);
                        },
                      ),
                      backgroundColor: context.appColors.readerBackground,
                      body: ReaderTtsPlayerOverlay(
                        isChromeVisible: isChromeVisibleNotifier,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: isChromeVisibleNotifier,
                          builder: (context, isChromeVisible, _) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                // 1. Fullscreen Document Viewport with Gesture Arena
                                ReaderGestureArena(
                                  enabled: true,
                                  isVerticalPaging:
                                      prefs.scrollDirection ==
                                          ReaderScrollDirection.vertical &&
                                      prefs.pageSnap,
                                  isAtScrollBoundary: isAtScrollBoundary,
                                  currentSpeed: autoScrollController.speed,
                                  autoScrollActive:
                                      autoScrollController.isActive,
                                  onSpeedChange: onSpeedGestureChange,
                                  onPageDragStart:
                                      pageViewController.handleDragStart,
                                  onPageDragUpdate:
                                      pageViewController.handleDragUpdate,
                                  onPageDragEnd:
                                      pageViewController.handleDragEnd,
                                  onPageDragCancel:
                                      pageViewController.handleDragCancel,
                                  onTapAction: handleTapAction,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isWide =
                                          constraints.maxWidth >= 900;
                                      final bodyContent = KeyedSubtree(
                                        key: _contentKey,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Positioned.fill(
                                              child: ReaderViewport(
                                                pageViewController:
                                                    pageViewController,
                                                prefs: prefs,
                                                onScrollBoundaryChanged:
                                                    onScrollBoundaryChanged,
                                              ),
                                            ),
                                            ReaderBrightnessOverlay(
                                              opacity: prefs.brightnessOverlay,
                                            ),
                                            ReaderContrastOverlay(
                                              intensity: prefs.contrastOverlay,
                                            ),
                                            if (isWide && !_tocPinned)
                                              ReaderTocPeek(
                                                onPin: () => setState(
                                                  () => _tocPinned = true,
                                                ),
                                                onJumpToPage: jumpToPage,
                                              ),
                                          ],
                                        ),
                                      );

                                      if (!isWide) return bodyContent;

                                      return Row(
                                        children: [
                                          if (_tocPinned)
                                            ReaderTocSidePanel(
                                              onUnpin: () => setState(
                                                () => _tocPinned = false,
                                              ),
                                              onJumpToPage: jumpToPage,
                                            ),
                                          Expanded(child: bodyContent),
                                        ],
                                      );
                                    },
                                  ),
                                ),

                                // 3. Floating Auto-Scroll Speed HUD Capsule
                                ValueListenableBuilder<bool>(
                                  valueListenable: speedHudVisibleNotifier,
                                  builder: (context, visible, _) {
                                    return ValueListenableBuilder<double>(
                                      valueListenable: speedLevelNotifier,
                                      builder: (context, speed, _) {
                                        return Positioned(
                                          top: 80,
                                          left: 0,
                                          right: 0,
                                          child: ReaderAutoScrollHud(
                                            speed: speed,
                                            visible: visible,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),

                                // 4. Floating Top Bar (Animated Slide + Fade)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    ignoring: !isChromeVisible,
                                    child: AnimatedSlide(
                                      offset: isChromeVisible
                                          ? Offset.zero
                                          : const Offset(0, -1),
                                      duration: gestureConstants
                                          .chromeAnimationDuration,
                                      curve: Curves.easeOutCubic,
                                      child: AnimatedOpacity(
                                        opacity: isChromeVisible ? 1.0 : 0.0,
                                        duration: gestureConstants
                                            .chromeAnimationDuration,
                                        curve: Curves.easeOutCubic,
                                        child: SafeArea(
                                          bottom: false,
                                          child: Container(
                                            color: context
                                                .appColors
                                                .readerBackground
                                                .withValues(alpha: 0.95),
                                            child: ReaderTopBar(
                                              onOpenDrawer: () => _scaffoldKey
                                                  .currentState
                                                  ?.openDrawer(),
                                              onCloseDocument: closeReader,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // 5. Floating Bottom Navigation Bar (Animated Slide + Fade)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    ignoring: !isChromeVisible,
                                    child: AnimatedSlide(
                                      offset: isChromeVisible
                                          ? Offset.zero
                                          : const Offset(0, 1),
                                      duration: gestureConstants
                                          .chromeAnimationDuration,
                                      curve: Curves.easeOutCubic,
                                      child: AnimatedOpacity(
                                        opacity: isChromeVisible ? 1.0 : 0.0,
                                        duration: gestureConstants
                                            .chromeAnimationDuration,
                                        curve: Curves.easeOutCubic,
                                        child: ReaderBottomBar(
                                          onOpenDrawer: () => _scaffoldKey
                                              .currentState
                                              ?.openDrawer(),
                                          onPreviousPage:
                                              pageViewController.previousPage,
                                          onNextPage:
                                              pageViewController.nextPage,
                                          onSeekToPage:
                                              pageViewController.goToPage,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
