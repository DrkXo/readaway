part of '../reader_widgets.dart';

class ReaderPageContent extends StatelessWidget {
  const ReaderPageContent({
    super.key,
    required this.pageViewController,
    required this.prefs,
    this.autoScrollController,
  });

  final ReaderPageViewController pageViewController;
  final ReaderPreferences prefs;

  /// Optional controller that drives auto-scroll. When provided, each
  /// reflowable page registers its vertical [ScrollController] with it.
  final AutoScrollController? autoScrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return const ReaderErrorView();
        }
        if (!state.hasDocument) {
          return const Center(child: Text('No document open'));
        }
        autoScrollController?.setPageCount(state.pageCount);
        pageViewController.setCurrentPage(state.currentPage);
        // Default ScrollBehavior excludes mouse from dragDevices (it fights
        // text selection), which leaves PageView unpageable by mouse. Opt
        // this PageView in: over text, SelectionArea's recognizer still wins
        // the arena; over images/margins mouse drag flips pages.
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.invertedStylus,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.mouse,
            },
          ),
          child: ReaderPageView(
            currentPage: state.currentPage,
            pageCount: state.pageCount,
            transition: prefs.pageTransition,
            direction: prefs.scrollDirection,
            itemBuilder: state.isReflowable ? _buildHtmlPage : _buildImagePage,
            onPageChangeRequested: (index) =>
                _onPageChangeRequested(context, index),
          ),
        );
      },
    );
  }

  void _onPageChangeRequested(BuildContext context, int index) {
    final state = context.read<ReaderBloc>().state;
    final clamped = index.clamp(0, state.pageCount - 1);
    if (clamped == state.currentPage) return;
    context.read<ReaderBloc>().add(ReaderEvent.pageChanged(index: clamped));
    autoScrollController?.setCurrentPage(clamped);
  }

  Widget _buildHtmlPage(BuildContext context, int index) {
    final state = context.read<ReaderBloc>().state;
    final html = state.htmlPages![index];

    if (html == null) {
      context.read<ReaderBloc>().add(ReaderEvent.loadPage(index: index));
      return const Center(child: CircularProgressIndicator());
    }

    return _AutoScrollableHtmlPage(
      index: index,
      html: html,
      prefs: prefs,
      autoScrollController: autoScrollController,
      onTapUrl: (url) => _onTapUrl(context, url),
    );
  }

  /// Internal links arrive pre-resolved as `#page=N` (flat page index)
  /// during HTML sanitization. External links are logged only for now.
  void _onTapUrl(BuildContext context, String url) {
    final match = RegExp(r'^#page=(\d+)$').firstMatch(url);
    if (match != null) {
      final maxIndex = context.read<ReaderBloc>().state.pageCount - 1;
      _onPageChangeRequested(
        context,
        int.parse(match.group(1)!).clamp(0, maxIndex),
      );
      return;
    }
    logger.d('External link ignored: $url');
  }

  Widget _buildImagePage(BuildContext context, int index) {
    final state = context.read<ReaderBloc>().state;
    final image = state.pageImages![index];

    if (image == null) {
      context.read<ReaderBloc>().add(ReaderEvent.loadPage(index: index));
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: RawImage(image: image, fit: BoxFit.contain),
    );
  }

  static FontWeight _resolveFontWeight(String weight) => switch (weight) {
    'lighter' => FontWeight.w300,
    'bold' => FontWeight.w700,
    _ => FontWeight.normal,
  };
}
