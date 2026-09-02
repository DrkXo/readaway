import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';

class ReaderErrorView extends StatelessWidget {
  const ReaderErrorView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      builder: (context, state) {
        return AppErrorView(
          title: 'Something went wrong',
          message: state.error,
          onRetry: null,
        );
      },
    );
  }
}
