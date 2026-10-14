import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway_core/readaway_core.dart';

import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import '../../controllers/reader_search_highlight_controller.dart';
import '../../../domain/repositories/reader_repository.dart';

/// Minimal "find in document" dialog for reflowable content.
///
/// Search is run against the HTML already loaded into [ReaderState]. Results
/// that land in chapters which have not been loaded yet are reported as soon as
/// that chapter's HTML is available on the next search pass.
class ReaderSearchDialog extends StatefulWidget {
  const ReaderSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    // The sheet is pushed on the root navigator, so the sheet's build context
    // no longer sits under the reader route's BlocProviders. Capture the bloc
    // from the caller's context and re-provide it inside the sheet subtree.
    final readerBloc = context.read<ReaderBloc>();
    return showAppSheet<void>(
      context: context,
      title: 'Find in document',
      builder: (_) => BlocProvider<ReaderBloc>.value(
        value: readerBloc,
        child: const ReaderSearchDialog(),
      ),
    );
  }

  @override
  State<ReaderSearchDialog> createState() => _ReaderSearchDialogState();
}

class _ReaderSearchDialogState extends State<ReaderSearchDialog> {
  final _controller = TextEditingController();
  List<ReaderSearchMatch> _results = const [];
  int _currentIndex = 0;
  bool _running = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ReaderState _state(BuildContext context) => context.read<ReaderBloc>().state;

  _SearchDocument _buildDocument(List<String?> htmls) =>
      _SearchDocument(htmls: htmls);

  Future<void> _runSearch(BuildContext context) async {
    final bloc = context.read<ReaderBloc>();
    final state = bloc.state;
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _running = false;
      });
      return;
    }

    setState(() => _running = true);

    final htmls = List<String?>.filled(state.pageCount, null);
    if (state.pageHtmls != null) {
      for (var i = 0; i < htmls.length && i < state.pageHtmls!.length; i++) {
        htmls[i] = state.pageHtmls![i];
      }
    }

    final repository = GetIt.I<ReaderRepository>();
    for (var i = 0; i < htmls.length; i++) {
      if (htmls[i] != null) continue;
      if (!mounted) return;
      final result = await repository.loadPage(i);
      result.fold(
        (failure) => htmls[i] = null,
        (pageData) => htmls[i] = pageData.html,
      );
    }

    if (!mounted) return;
    final service = const ReaderSearchService();
    final results = service.search(_buildDocument(htmls), query);

    if (!mounted) return;
    setState(() {
      _results = results;
      _currentIndex = 0;
      _running = false;
    });
    if (results.isNotEmpty) {
      await Future<void>.delayed(Duration.zero);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navigateTo(context, 0);
        });
      }
    }
  }

  void _navigateTo(BuildContext context, int index) {
    if (_results.isEmpty) return;
    final next = index.clamp(0, _results.length - 1);
    setState(() => _currentIndex = next);
    final match = _results[next];
    final bloc = context.read<ReaderBloc>();

    bloc.add(ReaderEvent.jumpToChapter(chapterIndex: match.sectionIndex));

    final coordinator = GetIt.I.isRegistered<PaginationCoordinator>()
        ? GetIt.I<PaginationCoordinator>()
        : null;
    final layout = coordinator?.getChapterLayout(match.sectionIndex);
    var rects = const <Rect>[];
    var term = _controller.text.trim();
    int? targetVirtualPage;
    if (layout != null && term.isNotEmpty) {
      final start = layout.flowText.toLowerCase().indexOf(term.toLowerCase());
      if (start >= 0) {
        final end = start + term.length;
        final raw = layout.rectsForCharRange(start, end);
        if (raw.isNotEmpty) rects = raw;
        if (coordinator != null) {
          targetVirtualPage = coordinator.globalPageForChar(
            match.sectionIndex,
            start,
          );
        }
      }
    }
    bloc.add(
      ReaderEvent.jumpToChapter(
        chapterIndex: match.sectionIndex,
        virtualPage: targetVirtualPage,
      ),
    );
    GetIt.I<ReaderSearchHighlightController>().set(match.sectionIndex, rects);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state(context);
    final hasResults = _results.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search text',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _runSearch(context),
          ),
          const SizedBox(height: 12),
          if (_running)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (hasResults)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${_currentIndex + 1} of ${_results.length} matches',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final m = _results[i];
                      final isActive = i == _currentIndex;
                      return ListTile(
                        dense: true,
                        selected: isActive,
                        title: Text(
                          'Chapter ${m.sectionIndex + 1}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        subtitle: Text(
                          m.snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _navigateTo(context, i),
                      );
                    },
                  ),
                ),
              ],
            )
          else
            Text(
              state.pageHtmls == null
                  ? 'Document still loading.'
                  : 'No matches yet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: hasResults
                    ? () => _navigateTo(context, _currentIndex - 1)
                    : null,
                child: const Text('Previous'),
              ),
              TextButton(
                onPressed: hasResults
                    ? () => _navigateTo(context, _currentIndex + 1)
                    : null,
                child: const Text('Next'),
              ),
              TextButton(
                onPressed: () => _runSearch(context),
                child: const Text('Search'),
              ),
              TextButton(
                onPressed: () {
                  GetIt.I<ReaderSearchHighlightController>().clear();
                  setState(() {
                    _results = const [];
                    _currentIndex = 0;
                  });
                },
                child: const Text('Clear'),
              ),
              TextButton(
                onPressed: () {
                  GetIt.I<ReaderSearchHighlightController>().clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchDocument implements ReflowableDocumentReader {
  _SearchDocument({required this.htmls});

  final List<String?>? htmls;

  @override
  int get sectionCount => htmls?.length ?? 0;

  @override
  List<DocumentSection> get sections {
    final count = sectionCount;
    return List.generate(
      count,
      (i) => DocumentSection(index: i, id: 'section_$i', href: ''),
    );
  }

  @override
  String loadSectionHtml(int index) {
    if (htmls == null || index < 0 || index >= htmls!.length) return '';
    return htmls![index] ?? '';
  }

  @override
  String get format => 'epub';

  @override
  bool get isReflowable => true;

  @override
  String? get title => null;

  @override
  DocumentMetadata? get metadata => null;

  @override
  List<OutlineItem> get outline => const [];

  @override
  String? get coverImagePath => null;

  @override
  bool get isDisposed => false;

  @override
  Uint8List? loadAsset(String assetPath) => null;

  @override
  Future<void> dispose() async {}
  @override
  String resolveAssetPath(int sectionIndex, String relativeHref) =>
      relativeHref;

  @override
  int? resolveSectionIndex(String href) => null;
}
