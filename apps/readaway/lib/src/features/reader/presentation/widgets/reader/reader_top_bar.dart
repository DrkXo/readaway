import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/reader_bloc.dart';
import '../widgets.dart';

class ReaderTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ReaderTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) => prev.hasDocument != curr.hasDocument,
      builder: (context, state) {
        if (!state.hasDocument) return const SizedBox.shrink();

        return SafeArea(
          bottom: false,
          child: SizedBox(
            height: preferredSize.height,
            child: Row(
              children: const [
                Spacer(),
                ReaderCaptionActions.reFlowable(),
                SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
