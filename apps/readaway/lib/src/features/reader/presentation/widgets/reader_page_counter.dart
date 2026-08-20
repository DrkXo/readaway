import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';

class ReaderPageCounter extends StatelessWidget {
  const ReaderPageCounter({super.key});

  @override
  Widget build(BuildContext context) {
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
}
