import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';

class ReaderErrorView extends StatelessWidget {
  const ReaderErrorView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) => prev.failure != curr.failure || prev.error != curr.error,
      builder: (context, state) {
        final failure = state.failure ??
            (state.error != null
                ? UnexpectedFailure(state.error!)
                : const UnexpectedFailure('An unexpected error occurred while loading this document.'));

        return FailureView(
          failure: failure,
          onRetry: () {
            if (state.fileName != null) {
              context.read<ReaderBloc>().add(
                    ReaderEvent.openDocument(
                      path: state.fileName!,
                      fileName: state.fileName,
                    ),
                  );
            }
          },
          retryLabel: 'Reload Document',
          onSecondaryAction: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          secondaryActionLabel: 'Return to Library',
        );
      },
    );
  }
}
