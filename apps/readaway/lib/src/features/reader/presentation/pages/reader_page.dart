import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_nav_bar.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_page_counter.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_page_content.dart';

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

  @override
  void initState() {
    super.initState();
    _readerBloc = context.read<ReaderBloc>();
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
        actions: const [ReaderPageCounter()],
      ),
      body: ReaderPageContent(pageController: _pageController),
      bottomNavigationBar: ReaderNavBar(pageController: _pageController),
    );
  }
}
