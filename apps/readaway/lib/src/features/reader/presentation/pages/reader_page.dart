import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/reader_bloc.dart';
import '../widgets/reader_bottom_bar.dart';
import '../widgets/reader_drawer.dart';
import '../widgets/reader_gesture_detector.dart';
import '../widgets/reader_overlay_controller.dart';
import '../widgets/reader_page_content.dart';
import '../widgets/reader_top_bar.dart';
import '../../../settings/domain/models/reader_preferences.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    this.initialPath,
    this.initialFileName,
  });

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

class _ReaderPageState extends State<ReaderPage> {
  final PageController _pageController = PageController();
  late final ReaderBloc _readerBloc;
  late final SettingsBloc _settingsBloc;
  late final ReaderOverlayController _overlayController;

  @override
  void initState() {
    super.initState();
    _readerBloc = context.read<ReaderBloc>();
    _settingsBloc = context.read<SettingsBloc>();
    _overlayController = ReaderOverlayController();

    _settingsBloc.loadPrefs();

    if (widget.initialPath != null) {
      if (!_readerBloc.state.loading && _readerBloc.state.htmlPages == null) {
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
    _readerBloc.add(const ReaderEvent.closeDocument());
    _pageController.dispose();
    _overlayController.dispose();
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
      child: BlocBuilder<ReaderBloc, ReaderState>(
        builder: (context, readerState) {
          return BlocBuilder<SettingsBloc, SettingsState>(
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
                  drawer: ReaderDrawer(
                    controller: _overlayController,
                    onJumpToPage: (page) {
                      _pageController.jumpToPage(page);
                    },
                  ),
                  body: _buildReaderView(prefs),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReaderView(ReaderPreferences prefs) {
    return ListenableBuilder(
      listenable: _overlayController,
      builder: (context, _) {
        return TactileReaderBackground(
          appColors: context.appColors,
          child: Stack(
            children: [
              _buildBrightnessOverlay(prefs),
              _buildContrastOverlay(prefs),
              ReaderGestureDetector(
                controller: _overlayController,
                child: ReaderPageContent(pageController: _pageController),
              ),
              _buildTopBar(),
              _buildBottomBar(),
              if (prefs.showStatusBar && _overlayController.barsVisible)
                _buildStatusBar(),
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

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ReaderTopBar(controller: _overlayController),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ReaderBottomBar(
        pageController: _pageController,
        controller: _overlayController,
        onSettingsTap: () {
          _overlayController.hideBars();
        },
      ),
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
          prev.htmlPages != curr.htmlPages,
      builder: (context, state) {
        if (state.htmlPages == null) return const SizedBox.shrink();
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
