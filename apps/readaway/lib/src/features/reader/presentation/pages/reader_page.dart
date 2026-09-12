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
import '../../../settings/domain/entity/reader_preferences.dart';
import '../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../domain/gestures/reader_gestures.dart';
import '../bloc/reader_bloc.dart';
import '../controllers/reader_viewport_controller.dart';
import '../widgets/widgets.dart';

part 'reader_page_mixin.dart';

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
                  curr.appSettings.screenWakeLock ||
              prev.readerPrefs.engineMode !=
                  curr.readerPrefs.engineMode,
          listener: (context, state) {
            syncSettings(state);
            final bloc = context.read<ReaderBloc>();
            if (bloc.state.hasDocument &&
                bloc.state.isReflowable &&
                bloc.state.engineMode != state.readerPrefs.engineMode) {
              bloc.add(
                ReaderEvent.engineModeChanged(
                  newMode: state.readerPrefs.engineMode,
                ),
              );
            }
          },
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
                        viewportController.previousPage,
                    const SingleActivator(LogicalKeyboardKey.arrowRight):
                        viewportController.nextPage,
                    const SingleActivator(LogicalKeyboardKey.arrowUp):
                        viewportController.previousPage,
                    const SingleActivator(LogicalKeyboardKey.arrowDown):
                        viewportController.nextPage,
                    const SingleActivator(LogicalKeyboardKey.pageUp):
                        viewportController.previousPage,
                    const SingleActivator(LogicalKeyboardKey.pageDown):
                        viewportController.nextPage,
                  },
                  child: Focus(
                    autofocus: true,
                    child: Scaffold(
                      key: _scaffoldKey,
                      drawer: ReaderDrawer(onJumpToPage: jumpToPage),
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
                                      viewportController.handleDragStart,
                                  onPageDragUpdate:
                                      viewportController.handleDragUpdate,
                                  onPageDragEnd:
                                      viewportController.handleDragEnd,
                                  onPageDragCancel:
                                      viewportController.handleDragCancel,
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
                                              child: SafeArea(
                                                child: ReaderViewport(
                                                  viewportController:
                                                      viewportController,
                                                  prefs: prefs,
                                                  onScrollBoundaryChanged:
                                                      onScrollBoundaryChanged,
                                                ),
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

                                // 3b. Floating Back-to-TTS Jump Pill
                                ReaderBackToTtsPill(
                                  topOffset: isChromeVisible ? 76.0 : 24.0,
                                  onJumpToTtsPage: jumpToPage,
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
                                        child: Container(
                                          color: context
                                              .appColors
                                              .readerBackground
                                              .withValues(alpha: 0.95),
                                          child: SafeArea(
                                            bottom: false,
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
                                              viewportController.previousPage,
                                          onNextPage:
                                              viewportController.nextPage,
                                          onSeekToPage:
                                              viewportController.goToPage,
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
