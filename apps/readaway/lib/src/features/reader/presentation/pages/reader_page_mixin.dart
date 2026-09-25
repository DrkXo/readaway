part of "../pages/reader_page.dart";

/// Handles lifecycle logic, controller setups, gesture coordination, and BLoC synchronization
mixin ReaderControllerMixin on State<ReaderPage> {
  late final ReaderViewportController viewportController;
  late final ScrollController scrollController;
  late final ValueNotifier<bool> isScrollingNotifier;

  // Immersive UI notifiers
  late final ValueNotifier<bool> isChromeVisibleNotifier;

  late final ReaderBloc readerBloc;
  late final SettingsBloc settingsBloc;

  ReaderGestureConstants get gestureConstants =>
      GetIt.I.isRegistered<ReaderGestureConstants>()
      ? GetIt.I<ReaderGestureConstants>()
      : const ReaderGestureConstants();

  /// Called by [ReaderViewport] whenever the visible page's scroll boundary changes.
  void onScrollBoundaryChanged({required bool atTop, required bool atBottom}) {}

  /// Synchronous closure passed to [ReaderGestureArena.isAtScrollBoundary].
  ///
  /// In paged mode, all pages (ReflowableVirtualPage and FixedReaderPage) are
  /// discrete non-scrolling screen pages, so vertical drags should always claim and flip pages.
  bool isAtScrollBoundary(bool atEnd) {
    return true;
  }

  void initReaderState() {
    readerBloc = context.read<ReaderBloc>();
    settingsBloc = context.read<SettingsBloc>();

    scrollController = ScrollController();
    isScrollingNotifier = ValueNotifier<bool>(false);
    scrollController.addListener(_onScrollChanged);

    viewportController = ReaderViewportController();

    isChromeVisibleNotifier = ValueNotifier<bool>(true);

    viewportController.onNavigate = (index) {
      final count = readerBloc.state.pageCount;
      if (count <= 0) return;
      final clamped = index.clamp(0, count - 1);
      if (clamped != readerBloc.state.currentPage) {
        readerBloc.add(ReaderEvent.pageChanged(index: clamped));
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
    final prefs = settingsBloc.state.effectiveReaderPrefs(
      readerBloc.state.documentPath,
    );
    final isContinuous =
        prefs.effectiveScrollDirection(
              isReflowable: readerBloc.state.isReflowable,
            ) ==
            ReaderScrollDirection.vertical &&
        !prefs.effectivePageSnap(
          isReflowable: readerBloc.state.isReflowable,
        );

    if (!isContinuous &&
        readerBloc.state.isReflowable &&
        GetIt.I.isRegistered<PaginationCoordinator>()) {
      final coordinator = GetIt.I<PaginationCoordinator>();
      // If 'page' is a chapter index from TOC (< chapterCount), map to its first global page
      final globalPage = (page < coordinator.chapterCount)
          ? coordinator.getGlobalPageForChapter(page)
          : page
                .clamp(0, math.max(0, coordinator.currentState.totalPages - 1))
                .toInt();

      final coord = coordinator.coordinateFromGlobalPage(globalPage);
      readerBloc.add(
        ReaderEvent.virtualPageChanged(
          globalPage: globalPage,
          totalPages: coordinator.currentState.totalPages,
          chapterIndex: coord.chapterIndex,
        ),
      );
      viewportController.jumpToPage(globalPage);
      return;
    }

    final count = readerBloc.state.pageCount;
    if (count <= 0) return;
    final clamped = page.clamp(0, count - 1).toInt();
    readerBloc.add(ReaderEvent.pageChanged(index: clamped));
    viewportController.jumpToPage(clamped);
  }

  void handleTapAction(ReaderTapAction action) {
    if (ReaderGestureArena.isTapSuppressed) return;
    switch (action) {
      case ReaderTapAction.toggleChrome:
        toggleChrome();
        break;
      case ReaderTapAction.previousPage:
        viewportController.previousPage();
        break;
      case ReaderTapAction.nextPage:
        viewportController.nextPage();
        break;
    }
  }

  void closeReader() {
    if (!readerBloc.isClosed) {
      readerBloc.add(const ReaderEvent.closeDocument());
    }
    if (mounted) context.pop();
  }

  void disposeReaderState() {
    scrollController.removeListener(_onScrollChanged);
    scrollController.dispose();
    isScrollingNotifier.dispose();
    isChromeVisibleNotifier.dispose();
    wakelockService.disable();
    if (!readerBloc.isClosed) {
      readerBloc.add(const ReaderEvent.closeDocument());
    }
    viewportController.dispose();
  }
}
