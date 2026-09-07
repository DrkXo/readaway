part of "../pages/reader_page.dart";

/// Handles lifecycle logic, controller setups, gesture coordination, and BLoC synchronization
mixin ReaderControllerMixin on State<ReaderPage> {
  late final ReaderPageViewController pageViewController;
  late final ReaderAutoScrollController autoScrollController;
  late final ScrollController scrollController;
  late final ValueNotifier<bool> isScrollingNotifier;

  // Immersive UI & Gesture HUD notifiers
  late final ValueNotifier<bool> isChromeVisibleNotifier;
  late final ValueNotifier<bool> speedHudVisibleNotifier;
  late final ValueNotifier<double> speedLevelNotifier;

  Timer? _speedHudTimer;

  late final ReaderBloc readerBloc;
  late final SettingsBloc settingsBloc;

  ReaderGestureConstants get gestureConstants =>
      GetIt.I.isRegistered<ReaderGestureConstants>()
      ? GetIt.I<ReaderGestureConstants>()
      : const ReaderGestureConstants();

  // Live scroll boundary state for the current page's inner scroll view.
  // Used by the gesture arena to decide whether to claim a vertical drag
  // for page-turning or let the inner scroll view handle it.
  bool _pageAtTop = true;
  bool _pageAtBottom = false;

  /// Called by [ReaderViewport] whenever the visible page's scroll boundary changes.
  void onScrollBoundaryChanged({required bool atTop, required bool atBottom}) {
    _pageAtTop = atTop;
    _pageAtBottom = atBottom;
  }

  /// Synchronous closure passed to [ReaderGestureArena.isAtScrollBoundary].
  ///
  /// Returns true when the inner scroll view is at the boundary in the drag direction,
  /// meaning the arena should take over and flip to the next/previous page.
  bool isAtScrollBoundary(bool atEnd) {
    // atEnd = true  → dragging up  → going to next page → check atBottom
    // atEnd = false → dragging down → going to prev page → check atTop
    return atEnd ? _pageAtBottom : _pageAtTop;
  }

  void initReaderState() {
    readerBloc = context.read<ReaderBloc>();
    settingsBloc = context.read<SettingsBloc>();

    scrollController = ScrollController();
    isScrollingNotifier = ValueNotifier<bool>(false);
    scrollController.addListener(_onScrollChanged);

    pageViewController = ReaderPageViewController();
    autoScrollController = ReaderAutoScrollController();

    isChromeVisibleNotifier = ValueNotifier<bool>(true);
    speedHudVisibleNotifier = ValueNotifier<bool>(false);
    speedLevelNotifier = ValueNotifier<double>(40.0);

    pageViewController.onNavigate = (index) {
      final count = readerBloc.state.pageCount;
      if (count <= 0) return;
      final clamped = index.clamp(0, count - 1);
      if (clamped != readerBloc.state.currentPage) {
        readerBloc.add(ReaderEvent.pageChanged(index: clamped));
        _syncProgressToLibrary(clamped, count);
      }
    };

    settingsBloc.add(const SettingsEvent.loadPrefs());
    syncSettings(settingsBloc.state);
    initDocument();
  }

  void _onScrollChanged() {
    if (!scrollController.hasClients) return;
    final isScrolling = scrollController.position.isScrollingNotifier.value;
    if (isScrollingNotifier.value != isScrolling) {
      isScrollingNotifier.value = isScrolling;
    }
  }

  void initDocument() {
    if (widget.initialPath != null &&
        !readerBloc.state.loading &&
        !readerBloc.state.hasDocument) {
      readerBloc.add(
        ReaderEvent.openDocument(
          path: widget.initialPath!,
          fileName: widget.initialFileName,
        ),
      );
    }
  }

  void syncSettings(SettingsState state) {
    wakelockService.setEnabled(state.appSettings.screenWakeLock);
  }

  void toggleChrome() {
    isChromeVisibleNotifier.value = !isChromeVisibleNotifier.value;
  }

  void setChromeVisible(bool visible) {
    if (isChromeVisibleNotifier.value != visible) {
      isChromeVisibleNotifier.value = visible;
    }
  }

  void jumpToPage(int page) {
    final count = readerBloc.state.pageCount;
    if (count <= 0) return;
    final clamped = page.clamp(0, count - 1);
    readerBloc.add(ReaderEvent.pageChanged(index: clamped));
    pageViewController.jumpToPage(clamped);
  }

  void handleTapAction(ReaderTapAction action) {
    if (ReaderGestureArena.isTapSuppressed) return;
    switch (action) {
      case ReaderTapAction.toggleChrome:
        toggleChrome();
        break;
      case ReaderTapAction.previousPage:
        pageViewController.previousPage();
        break;
      case ReaderTapAction.nextPage:
        pageViewController.nextPage();
        break;
    }
  }

  void onSpeedGestureChange(double newSpeed) {
    speedLevelNotifier.value = newSpeed;
    speedHudVisibleNotifier.value = true;
    autoScrollController.setSpeed(newSpeed);
    _speedHudTimer?.cancel();
    _speedHudTimer = Timer(
      gestureConstants.hudOverlayAutoDismissDuration,
      () {
        speedHudVisibleNotifier.value = false;
      },
    );
  }

  void _syncProgressToLibrary(int currentPage, int pageCount) {
    final path = widget.initialPath;
    if (path == null) return;
    try {
      final repo = GetIt.I<LibraryRepository>();
      repo.getRecentDocuments().run().then((res) {
        res.fold((_) {}, (docs) {
          final doc = docs.where((d) => d.path == path).firstOrNull;
          if (doc != null) {
            final isFinished = pageCount > 0 && currentPage >= pageCount - 1;
            final updated = doc.copyWith(
              lastReadPage: currentPage,
              pageCount: pageCount,
              lastOpened: DateTime.now(),
              readingStatus: isFinished
                  ? ReadingStatus.finished
                  : ReadingStatus.reading,
            );
            repo.saveRecentDocument(updated).run();
          }
        });
      });
    } catch (_) {}
  }

  void closeReader() {
    _syncProgressToLibrary(
      readerBloc.state.currentPage,
      readerBloc.state.pageCount,
    );
    if (!readerBloc.isClosed) {
      readerBloc.add(const ReaderEvent.closeDocument());
    }
    if (mounted) context.pop();
  }

  void disposeReaderState() {
    _syncProgressToLibrary(
      readerBloc.state.currentPage,
      readerBloc.state.pageCount,
    );
    _speedHudTimer?.cancel();
    scrollController.removeListener(_onScrollChanged);
    scrollController.dispose();
    isScrollingNotifier.dispose();
    autoScrollController.dispose();
    isChromeVisibleNotifier.dispose();
    speedHudVisibleNotifier.dispose();
    speedLevelNotifier.dispose();
    wakelockService.disable();
    if (!readerBloc.isClosed) {
      readerBloc.add(const ReaderEvent.closeDocument());
    }
    pageViewController.dispose();
  }
}
