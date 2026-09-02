import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/routes/routes.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../router/router.dart';
import '../../bloc/reader_bloc.dart';

class ReaderCaptionActions extends StatelessWidget {
  const ReaderCaptionActions.reFlowable({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          icon: LucideIcons.x,
          tooltip: 'Close document',
          onPressed: () {
            context.read<ReaderBloc>().add(const ReaderEvent.closeDocument());
            appRouter.goNamed(appRoutes.library.name);
          },
          size: AppIconButtonSize.small,
        ),
      ],
    );
  }
}
