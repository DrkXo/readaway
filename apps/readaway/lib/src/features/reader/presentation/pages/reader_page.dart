import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final PageController _pageController = PageController();

  Future<void> _pickAndOpen() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xps', 'epub'],
    );

    if (result.isEmpty || result.first.path == null) return;

    if (!mounted) return;
    context.read<ReaderBloc>().add(
      ReaderEvent.openDocument(
        path: result.first.path!,
        fileName: result.first.name,
      ),
    );

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    context.read<ReaderBloc>().add(const ReaderEvent.closeDocument());
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ReaderBloc, ReaderState>(
          buildWhen: (prev, curr) => prev.fileName != curr.fileName,
          builder: (context, state) => Text(state.fileName ?? 'ReadAway'),
        ),
        actions: [_buildPageCounter()],
      ),
      body: _buildBody(),
      bottomNavigationBar: BlocBuilder<ReaderBloc, ReaderState>(
        buildWhen: (prev, curr) => prev.htmlPages != curr.htmlPages,
        builder: (context, state) {
          if (state.htmlPages == null) return const SizedBox.shrink();
          return _buildNavBar(state);
        },
      ),
      floatingActionButton: BlocBuilder<ReaderBloc, ReaderState>(
        buildWhen: (prev, curr) => prev.loading != curr.loading,
        builder: (context, state) => FloatingActionButton(
          onPressed: state.loading ? null : _pickAndOpen,
          child: const Icon(Icons.file_open),
        ),
      ),
    );
  }

  Widget _buildPageCounter() {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.pageCount != curr.pageCount ||
          prev.htmlPages != curr.htmlPages,
      builder: (context, state) {
        if (state.htmlPages == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              '${state.currentPage + 1} / ${state.pageCount}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavBar(ReaderState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filledTonal(
              onPressed: state.currentPage > 0
                  ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    )
                  : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous page',
            ),
            Text(
              'Page ${state.currentPage + 1} of ${state.pageCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            IconButton.filledTonal(
              onPressed: state.currentPage < state.pageCount - 1
                  ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    )
                  : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next page',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<ReaderBloc, ReaderState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return _buildError(state.error!);
        }
        if (state.htmlPages == null) {
          return const Center(child: Text('Tap + to open a document'));
        }
        return PageView.builder(
          controller: _pageController,
          itemCount: state.pageCount,
          onPageChanged: (i) => context.read<ReaderBloc>().add(
            ReaderEvent.pageChanged(index: i),
          ),
          itemBuilder: _buildPage,
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, int index) {
    final state = context.read<ReaderBloc>().state;
    final html = state.htmlPages![index];

    if (html == null) {
      context.read<ReaderBloc>().add(ReaderEvent.loadPage(index: index));
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          clipBehavior: Clip.none,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: SizedBox(
              width: double.infinity,
              child: HtmlWidget(html, renderMode: RenderMode.column),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
