import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_bottom_bar.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_gesture_detector.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_overlay_controller.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_page_content.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_top_bar.dart';
import 'package:readaway/src/features/settings/presentation/bloc/settings_bloc.dart';

import '../../../settings/domain/models/reader_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) => prev.fileName != curr.fileName,
      listener: (context, state) {
        if (state.fileName != null) {
          _settingsBloc.updateActiveDocumentPath(state.fileName);
        }
      },
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final prefs = settingsState.resolvedReaderPrefs(
            _readerBloc.state.fileName,
          );

          return PopScope(
            canPop: true,
            child: Scaffold(
              body: _buildReaderView(prefs),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReaderView(ReaderPreferences prefs) {
    return Stack(
      children: [
        _buildBrightnessOverlay(prefs),
        _buildContrastOverlay(prefs),
        ReaderGestureDetector(
          controller: _overlayController,
          child: ReaderPageContent(pageController: _pageController),
        ),
        _buildTopBar(),
        _buildBottomBar(),
        if (prefs.showStatusBar) _buildStatusBar(prefs),
      ],
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

  Widget _buildStatusBar(ReaderPreferences prefs) {
    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
      ],
      child: const SizedBox.shrink(),
    );
  }
}
