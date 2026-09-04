import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/services.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../settings/presentation/bloc/settings/settings_bloc.dart';
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
        BlocListener<ReaderBloc, ReaderState>(
          listenWhen: (prev, curr) => prev.fileName != curr.fileName,
          listener: (context, state) {
            if (state.fileName != null) {
              settingsBloc.updateActiveDocumentPath(state.fileName);
            }
          },
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (prev, curr) =>
              prev.appSettings.screenWakeLock !=
              curr.appSettings.screenWakeLock,
          listener: (context, state) => syncSettings(state),
        ),
      ],
      child: BlocBuilder<ReaderBloc, ReaderState>(
        buildWhen: (prev, curr) => prev.fileName != curr.fileName,
        builder: (context, readerState) {
          return BlocBuilder<SettingsBloc, SettingsState>(
            buildWhen: (prev, curr) =>
                prev.resolvedReaderPrefs(readerState.fileName) !=
                curr.resolvedReaderPrefs(readerState.fileName),
            builder: (context, settingsState) {
              final prefs = settingsState.resolvedReaderPrefs(
                readerState.fileName,
              );

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
                    const SingleActivator(LogicalKeyboardKey.pageUp):
                        pageViewController.previousPage,
                    const SingleActivator(LogicalKeyboardKey.pageDown):
                        pageViewController.nextPage,
                  },
                  child: Focus(
                    autofocus: true,
                    child: Stack(
                      children: [
                        Scaffold(
                          key: _scaffoldKey,
                          drawer: ReaderDrawer(
                            onJumpToPage: pageViewController.goToPage,
                          ),
                          bottomNavigationBar: ReaderBottomBar(
                            onOpenDrawer: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            onPreviousPage: pageViewController.previousPage,
                            onNextPage: pageViewController.nextPage,
                            onSeekToPage: pageViewController.goToPage,
                          ),
                          backgroundColor: context.appColors.readerBackground,
                          body: NestedScrollView(
                            controller: scrollController,
                            headerSliverBuilder:
                                (context, innerBoxIsScrolled) => [
                                  SliverAppBar(
                                    floating: !isDesktop,
                                    snap: !isDesktop,
                                    pinned: isDesktop,
                                    automaticallyImplyLeading: false,
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    titleSpacing: 0,
                                    toolbarHeight: isDesktop
                                        ? AppTopBar.desktopHeight
                                        : AppTopBar.mobileHeight,
                                    title: ReaderTopBar(
                                      onOpenDrawer: () => _scaffoldKey
                                          .currentState
                                          ?.openDrawer(),
                                      onCloseDocument: closeReader,
                                    ),
                                  ),
                                ],
                            body: LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 900;
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
                                          onPin: () =>
                                              setState(() => _tocPinned = true),
                                          onJumpToPage:
                                              pageViewController.goToPage,
                                        ),
                                    ],
                                  ),
                                );

                                if (!isWide) return bodyContent;

                                return Row(
                                  children: [
                                    if (_tocPinned)
                                      ReaderTocSidePanel(
                                        onUnpin: () =>
                                            setState(() => _tocPinned = false),
                                        onJumpToPage:
                                            pageViewController.goToPage,
                                      ),
                                    Expanded(child: bodyContent),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const ReaderTtsPlayerOverlay(),
                      ],
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
