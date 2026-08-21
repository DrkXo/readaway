import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../router/router.dart';
import '../bloc/reader_bloc.dart';

class ReaderCaptionActions extends StatelessWidget {
  const ReaderCaptionActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MorphIconButton(
          icon: Icons.format_size_rounded,
          hoverIcon: Icons.text_increase_rounded,
          tooltip: 'Text size',
        ),
        MorphIconButton(
          icon: Icons.search_rounded,
          hoverIcon: Icons.manage_search_rounded,
          tooltip: 'Search',
        ),
        MorphIconButton(
          icon: Icons.menu_book_outlined,
          hoverIcon: Icons.auto_stories_outlined,
          tooltip: 'Notebook',
        ),
        MorphIconButton(
          icon: Icons.bookmark_border_rounded,
          hoverIcon: Icons.bookmark_rounded,
          tooltip: 'Bookmark',
        ),
        MorphIconButton(
          icon: Icons.close_rounded,
          hoverIcon: Icons.cancel_rounded,
          tooltip: 'Close document',
          onTap: () {
            context.read<ReaderBloc>().add(const ReaderEvent.closeDocument());
            appRouter.goNamed(appRoutes.library.name);
          },
        ),
      ],
    );
  }
}
