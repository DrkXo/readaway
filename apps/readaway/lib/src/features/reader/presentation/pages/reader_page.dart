import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/services.dart';
import '../../../../core/theme/theme.dart';
import '../../../settings/domain/models/reader_preferences.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../bloc/reader_bloc.dart';
import '../controllers/auto_scroll_controller.dart';
import '../controllers/reader_page_view_controller.dart';
import '../widgets/reader_widgets.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    this.initialPath,
    this.initialFileName,
  });

  /// Lets the window caption (which lives above the Navigator) open the
  /// reader drawer.
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  factory ReaderPage.fromRoute(GoRouterState state) {
    final path = state.uri.queryParameters['path'];
    final fileName = state.uri.queryParameters['fileName'];
    return ReaderPage(
      initialPath: path,
      initialFileName: fileName,
    );
  }

  final String? initialPath;
  final String? initialFileName;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>
    with SingleTickerProviderStateMixin {
  final ReaderPageViewController _pageViewController =
      ReaderPageViewController();

  /// Keeps the reader subtree (PageView page, scroll offsets, selection)
  /// alive across the wide/narrow breakpoint switch in [_buildReaderView],
  /// which changes the tree shape above it.
  final GlobalKey _contentKey = GlobalKey();

  late final ReaderBloc _readerBloc;
  late final SettingsBloc _settingsBloc;
  late final AutoScrollController _autoScrollController;
  StreamSubscription<AppLifecycleState>? _lifecycleSub;
  bool _tocPinned = false;

  @override
  void initState() {
    super.initState();
    _readerBloc = context.read<ReaderBloc>();
    _settingsBloc = context.read<SettingsBloc>();

    // Route page-change requests from the view controller (swipes, TOC,
    // drawer, bottom bar, auto-scroll) into the BLoC, which is the single
    // source of truth for the current page.
    _pageViewController.onNavigate = (index) {
      final count = _readerBloc.state.pageCount;
      if (count <= 0) return;
      final clamped = index.clamp(0, count - 1);
      if (clamped == _readerBloc.state.currentPage) return;
      _readerBloc.add(ReaderEvent.pageChanged(index: clamped));
    };

    _autoScrollController = AutoScrollController(
      vsync: this,
      goToNextPage: () => _pageViewController.nextPage(),
    );

    // Auto-scroll only runs while the app is in the foreground (screen on).
    _lifecycleSub = appLifecycleManager.lifecycleState.listen((state) {
      if (state == AppLifecycleState.resumed) {
        _autoScrollController.resume();
      } else {
        _autoScrollController.pause();
      }
    });

    _settingsBloc.loadPrefs();

    // Apply persisted wakelock / auto-scroll settings on open (the
    // BlocListener below only fires on *changes*).
    _syncWakelock(_settingsBloc.state);
    _syncAutoScroll(_settingsBloc.state);

    if (widget.initialPath != null) {
      if (!_readerBloc.state.loading && !_readerBloc.state.hasDocument) {
        _readerBloc.add(
          ReaderEvent.openDocument(
            path: widget.initialPath!,
            fileName: widget.initialFileName,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _lifecycleSub?.cancel();
    _autoScrollController.dispose();
    // Wakelock is scoped to the reader: always release it on close.
    wakelockService.disable();
    _readerBloc.add(const ReaderEvent.closeDocument());
    _pageViewController.dispose();
    super.dispose();
  }

  void _closeReader() {
    _readerBloc.add(const ReaderEvent.closeDocument());
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) => prev.fileName != curr.fileName,
      listener: (context, state) {
        if (state.fileName != null) {
          _settingsBloc.updateActiveDocumentPath(state.fileName);
        }
      },
      child: BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (prev, curr) =>
            prev.appSettings.screenWakeLock !=
                curr.appSettings.screenWakeLock ||
            prev.appSettings.globalViewSettings.autoScrollRunning !=
                curr.appSettings.globalViewSettings.autoScrollRunning ||
            prev.appSettings.globalViewSettings.autoScrollSpeed !=
                curr.appSettings.globalViewSettings.autoScrollSpeed,
        listener: (context, settingsState) {
          _syncWakelock(settingsState);
          _syncAutoScroll(settingsState);
        },
        child: BlocBuilder<ReaderBloc, ReaderState>(
          builder: (context, readerState) {
            return BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (prev, curr) =>
                  prev.resolvedReaderPrefs(_readerBloc.state.fileName) !=
                  curr.resolvedReaderPrefs(_readerBloc.state.fileName),
              builder: (context, settingsState) {
                final prefs = settingsState.resolvedReaderPrefs(
                  _readerBloc.state.fileName,
                );

                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    _closeReader();
                  },
                  child: Scaffold(
                    key: ReaderPage.scaffoldKey,
                    drawer: ReaderDrawer(
                      onJumpToPage: _pageViewController.goToPage,
                    ),
                    body: _buildReaderView(prefs),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Applies the "keep screen on" setting while the reader is open.
  void _syncWakelock(SettingsState settingsState) {
    wakelockService.setEnabled(settingsState.appSettings.screenWakeLock);
  }

  /// Starts/stops auto-scroll and applies the speed from settings.
  void _syncAutoScroll(SettingsState settingsState) {
    final view = settingsState.appSettings.globalViewSettings;
    _autoScrollController.setSpeed(view.autoScrollSpeed);
    if (view.autoScrollRunning) {
      _autoScrollController.start();
    } else {
      _autoScrollController.stop();
    }
  }

  void _toggleTocPanel() {
    setState(() => _tocPinned = !_tocPinned);
  }

  Widget _buildReaderView(ReaderPreferences prefs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final content = Stack(
          key: _contentKey,
          children: [
            _buildBrightnessOverlay(prefs),
            _buildContrastOverlay(prefs),
            ReaderPageContent(
              pageViewController: _pageViewController,
              prefs: prefs,
              autoScrollController: _autoScrollController,
            ),
            if (isWide && !_tocPinned)
              ReaderTocPeek(
                onPin: _toggleTocPanel,
                onJumpToPage: _pageViewController.goToPage,
              ),
            _buildBottomBar(menuTogglesPanel: isWide),
            if (prefs.showStatusBar) _buildStatusBar(),
          ],
        );

        if (!isWide) {
          return TactileReaderBackground(
            appColors: context.appColors,
            child: content,
          );
        }

        return TactileReaderBackground(
          appColors: context.appColors,
          child: Row(
            children: [
              if (_tocPinned)
                ReaderTocSidePanel(
                  onUnpin: _toggleTocPanel,
                  onJumpToPage: _pageViewController.goToPage,
                ),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrightnessOverlay(ReaderPreferences prefs) {
    if (prefs.brightnessOverlay <= 0) return const SizedBox.shrink();
    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
      ],
      child: Container(
        color: Colors.black.withValues(alpha: prefs.brightnessOverlay),
      ),
    );
  }

  Widget _buildContrastOverlay(ReaderPreferences prefs) {
    if (prefs.contrastOverlay <= 0) return const SizedBox.shrink();
    final contrast = 1.0 + prefs.contrastOverlay;
    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
      ],
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(<double>[
          contrast,
          0,
          0,
          0,
          0,
          0,
          contrast,
          0,
          0,
          0,
          0,
          0,
          contrast,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildBottomBar({required bool menuTogglesPanel}) {
    return ReaderBottomBar(
      onPreviousPage: _pageViewController.previousPage,
      onNextPage: _pageViewController.nextPage,
      onSeekToPage: _pageViewController.goToPage,
      onOutlineTap: menuTogglesPanel ? _toggleTocPanel : null,
    );
  }

  Widget _buildStatusBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: _ReaderStatusBar(readerBloc: _readerBloc),
      ),
    );
  }
}

class _ReaderStatusBar extends StatelessWidget {
  const _ReaderStatusBar({required this.readerBloc});

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
