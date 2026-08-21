import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/services.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/reader_bloc.dart';
import 'reader_error_view.dart';
import 'reader_html_widget.dart';

class ReaderPageContent extends StatelessWidget {
  const ReaderPageContent({
    super.key,
    required this.pageController,
  });

  final PageController pageController;

  static Widget htmlWidget(String html, BuildContext context) {
    return ReaderHtmlWidget(
      html: html,
      appColors: context.appColors,
      onTapUrl: (url) {
        logger.d('Opening url: $url');
      },
    );
  }

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
        return PageView.builder(
          controller: pageController,
          itemCount: state.pageCount,
          onPageChanged: (i) => context.read<ReaderBloc>().add(
            ReaderEvent.pageChanged(index: i),
          ),
          itemBuilder: state.isReflowable ? _buildHtmlPage : _buildImagePage,
        );
      },
    );
  }

  Widget _buildHtmlPage(BuildContext context, int index) {
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
              child: ReaderPageContent.htmlWidget(html, context),
            ),
          ),
        );
      },
    );
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
}

