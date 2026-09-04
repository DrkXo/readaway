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
    wakelockService.disable();
    if (!readerBloc.isClosed) {
      readerBloc.add(const ReaderEvent.closeDocument());
    }
    pageViewController.dispose();
  }
}
