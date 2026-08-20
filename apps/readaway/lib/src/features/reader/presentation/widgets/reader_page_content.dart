import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:readaway/src/core/services/services.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_error_view.dart';

class ReaderPageContent extends StatelessWidget {
  const ReaderPageContent({
    super.key,
    required this.pageController,
  });

  final PageController pageController;

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
        if (state.htmlPages == null) {
          return const Center(child: Text('No document open'));
        }
        return PageView.builder(
          controller: pageController,
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
              child: HtmlWidget(
                html,
                renderMode: RenderMode.column,
                onTapUrl: (url) {
                  logger.d('Opening url: $url');
                  return true;
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
