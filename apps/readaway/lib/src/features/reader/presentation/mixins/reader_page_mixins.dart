part of "../pages/reader_page.dart";

/// Handles lifecycle logic, controller setups, and BLoC synchronization
mixin ReaderControllerMixin on State<ReaderPage> {
  late final ReaderPageViewController pageViewController;
  late final ScrollController scrollController;
  late final ValueNotifier<bool> isScrollingNotifier;

  late final ReaderBloc readerBloc;
  late final SettingsBloc settingsBloc;

  void initReaderState() {
    readerBloc = context.read<ReaderBloc>();
    settingsBloc = context.read<SettingsBloc>();

    scrollController = ScrollController();
    isScrollingNotifier = ValueNotifier<bool>(false);

    scrollController.addListener(_onScrollChanged);

    pageViewController = ReaderPageViewController();
    pageViewController.onNavigate = (index) {
      final count = readerBloc.state.pageCount;
      if (count <= 0) return;
      final clamped = index.clamp(0, count - 1);
      if (clamped != readerBloc.state.currentPage) {
        readerBloc.add(ReaderEvent.pageChanged(index: clamped));
        _syncProgressToLibrary(clamped, count);
      }
    };

    settingsBloc.loadPrefs();
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
              readingStatus:
                  isFinished ? ReadingStatus.finished : ReadingStatus.reading,
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
    scrollController.removeListener(_onScrollChanged);
    scrollController.dispose();
    isScrollingNotifier.dispose();
    wakelockService.disable();
    if (!readerBloc.isClosed) {
      readerBloc.add(const ReaderEvent.closeDocument());
    }
    pageViewController.dispose();
  }
}
