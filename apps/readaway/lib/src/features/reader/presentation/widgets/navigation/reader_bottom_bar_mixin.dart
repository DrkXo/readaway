import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/models/models.dart';
import '../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../bloc/reader_bloc.dart';
import 'reader_bottom_bar.dart';

/// Mixin managing bottom bar operations, panel animations, and overlay presentation.
mixin ReaderBottomBarMixin on State<ReaderBottomBar>, TickerProvider {
  ReaderBottomPanel? activePanel;
  OverlayEntry? overlayEntry;
  late final ValueNotifier<ReaderBottomPanel?> panelNotifier;
  late final AnimationController animController;
  late final Animation<double> fadeAnimation;
  late final Animation<Offset> slideAnimation;

  @override
  void initState() {
    super.initState();
    initBottomBarState();
  }

  @override
  void dispose() {
    disposeBottomBarState();
    super.dispose();
  }

  /// Initializes animation controllers, curves, and listeners for the bottom bar.
  void initBottomBarState() {
    panelNotifier = ValueNotifier<ReaderBottomPanel?>(null);
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 180),
    );
    fadeAnimation = CurvedAnimation(
      parent: animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      reverseCurve: const Interval(0.35, 1.0, curve: Curves.easeIn),
    );
    slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
  }

  /// Cleans up overlay entries and disposes controllers.
  void disposeBottomBarState() {
    removeOverlay();
    animController.dispose();
    panelNotifier.dispose();
  }

  /// Removes and disposes the current floating overlay entry if present.
  void removeOverlay() {
    overlayEntry?.remove();
    overlayEntry?.dispose();
    overlayEntry = null;
  }

  /// Toggles the specified contextual panel.
  void togglePanel(ReaderBottomPanel panel) {
    if (activePanel == panel) {
      closePanel();
    } else {
      openPanel(panel);
    }
  }

  /// Opens the specified panel in the floating overlay.
  void openPanel(ReaderBottomPanel panel) {
    activePanel = panel;
    panelNotifier.value = panel;

    if (overlayEntry == null) {
      overlayEntry = createOverlayEntry();
      Overlay.of(context).insert(overlayEntry!);
      animController.forward(from: 0.0);
    } else {
      if (!animController.isCompleted) {
        animController.forward();
      }
    }
    setState(() {});
  }

  /// Closes any open contextual panel with exit animation.
  void closePanel() {
    if (activePanel == null && overlayEntry == null) return;
    setState(() {
      activePanel = null;
    });
    panelNotifier.value = null;
    animController.reverse().then((_) {
      if (mounted && activePanel == null) {
        removeOverlay();
      }
    });
  }

  /// Handles opening the chapter outline / drawer.
  void handleOutlineTap() {
    closePanel();
    (widget.onOpenDrawer ?? widget.onOutlineTap)?.call();
  }

  /// Handles toggling the text-to-speech engine.
  void handleTtsTap(ReaderState readerState) {
    closePanel();
    if (readerState.ttsActive) {
      context.read<ReaderBloc>().add(
        const ReaderEvent.ttsClose(),
      );
    } else {
      context.read<ReaderBloc>().add(
        const ReaderEvent.ttsStart(),
      );
    }
  }

  /// Creates the [OverlayEntry] containing the backdrop and floating controls card.
  OverlayEntry createOverlayEntry() {
    final readerBloc = context.read<ReaderBloc>();
    final settingsBloc = context.read<SettingsBloc>();

    return OverlayEntry(
      builder: (overlayContext) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final mediaQuery = MediaQuery.of(context);
        final bottomPadding = mediaQuery.padding.bottom;
        final cardBgColor = widget.panelBackgroundColor ??
            widget.backgroundColor ??
            scheme.surface.withValues(alpha: 0.95);

        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: readerBloc),
            BlocProvider.value(value: settingsBloc),
          ],
          child: Stack(
            children: [
              // 1. Dismiss backdrop (covers screen above bottom bar)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: ReaderBottomBar.height + bottomPadding,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: closePanel,
                ),
              ),

              // 2. Extending quick panel from bottom bar
              Positioned(
                left: 0,
                right: 0,
                bottom: ReaderBottomBar.height + bottomPadding,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipRect(
                    child: SlideTransition(
                      position: slideAnimation,
                      child: FadeTransition(
                        opacity: fadeAnimation,
                        child: ReaderBottomControlsPanel(
                          width: widget.panelWidth,
                          maxWidth: widget.panelMaxWidth,
                          backgroundColor: cardBgColor,
                          panelNotifier: panelNotifier,
                          onClose: closePanel,
                          onPreviousPage: widget.onPreviousPage,
                          onNextPage: widget.onNextPage,
                          onSeekToPage: widget.onSeekToPage,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
