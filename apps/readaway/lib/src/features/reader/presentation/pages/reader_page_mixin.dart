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
    // Applied here (not only in the settings panel) so a stored budget takes
    // effect on launch. `configureBudget` no-ops when unchanged.
    FixedLayoutImageCache.instance.configureBudget(
      state.appSettings.globalViewSettings.readerCacheSizeMb * 1024 * 1024,
    );
  }

  void toggleChrome() {
    isChromeVisibleNotifier.value = !isChromeVisibleNotifier.value;
  }

  void setChromeVisible(bool visible) {
    if (isChromeVisibleNotifier.value != visible) {
      isChromeVisibleNotifier.value = visible;
    }
  }

  void jumpToGlobalPage(int globalPage, {bool animated = false}) {
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
      final total = math.max(0, coordinator.currentState.totalPages);
      if (total <= 0) return;
      final clamped = globalPage.clamp(0, total - 1).toInt();
      viewportController.updatePageCount(total);
      if (animated) {
        viewportController.goToPage(clamped, animated: true);
      } else {
        viewportController.jumpToPage(clamped);
      }
      return;
    }

    final count = readerBloc.state.pageCount;
    if (count <= 0) return;
    final clamped = globalPage.clamp(0, count - 1).toInt();
    viewportController.updatePageCount(count);
    if (animated) {
      viewportController.goToPage(clamped, animated: true);
    } else {
      viewportController.jumpToPage(clamped);
    }
  }

  void jumpToChapter(int chapterIndex, {bool animated = false}) {
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

    if (isContinuous) {
      final count = readerBloc.state.pageCount;
      if (count <= 0) return;
      final clamped = chapterIndex.clamp(0, count - 1).toInt();
      viewportController.updatePageCount(count);
      if (animated) {
        viewportController.goToPage(clamped, animated: true);
      } else {
        viewportController.jumpToPage(clamped);
      }
      return;
    }

    if (readerBloc.state.isReflowable &&
        GetIt.I.isRegistered<PaginationCoordinator>()) {
      final coordinator = GetIt.I<PaginationCoordinator>();
      final globalPage = coordinator.getGlobalPageForChapter(chapterIndex);
      jumpToGlobalPage(globalPage, animated: animated);
      return;
    }
    jumpToGlobalPage(chapterIndex, animated: animated);
  }

  void jumpToPage(int page, {bool animated = false, bool isChapter = false}) {
    if (isChapter) {
      jumpToChapter(page, animated: animated);
    } else {
      jumpToGlobalPage(page, animated: animated);
    }
  }

  /// Moves to where [note] is anchored.
  ///
  /// A fixed-layout note addresses a page directly. A reflowable note addresses
  /// a character range, so its page is the chapter's first page plus the page the
  /// offset falls on — which lands on the right page rather than the start of the
  /// chapter. When the chapter has no measured geometry yet, the offset resolves
  /// provisionally to its first page, loads the chapter, and then refines to the
  /// exact page once layout measurement completes.
  void jumpToNote(ReaderNote note) {
    final anchor = note.anchor;
    if (anchor.kind == NoteAnchorKind.page || !readerBloc.state.isReflowable) {
      jumpToGlobalPage(anchor.pageIndex);
      return;
    }

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

    if (isContinuous) {
      jumpToChapter(anchor.chapterIndex);
      return;
    }

    if (!GetIt.I.isRegistered<PaginationCoordinator>()) {
      jumpToChapter(anchor.chapterIndex);
      return;
    }

    final coordinator = GetIt.I<PaginationCoordinator>();
    if (coordinator.hasCharacterMapping(anchor.chapterIndex)) {
      jumpToGlobalPage(
        coordinator.globalPageForChar(anchor.chapterIndex, anchor.startChar),
      );
      return;
    }

    // Unmeasured chapter: jump provisionally, request loading, and refine once measured.
    final provisionalPage = coordinator.getGlobalPageForChapter(
      anchor.chapterIndex,
    );
    jumpToGlobalPage(provisionalPage);
    readerBloc.add(ReaderEvent.loadPage(index: anchor.chapterIndex));

    coordinator.ensureChapterMeasured(anchor.chapterIndex).then((_) {
      if (!mounted) return;
      jumpToGlobalPage(
        coordinator.globalPageForChar(anchor.chapterIndex, anchor.startChar),
      );
    });
  }

  void handleTapAction(ReaderTapAction action) {
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
    if (context.canPop()) {
      context.pop();
    } else if (!kIsWeb &&
        (Platform.isAndroid ||
            Platform.isWindows ||
            Platform.isLinux ||
            Platform.isMacOS)) {
      SystemNavigator.pop();
    } else if (mounted) {
      context.go(appRoutes.library.path);
    }
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
