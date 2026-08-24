part of '../reader_widgets.dart';

class ReaderCaptionActions extends StatelessWidget {
  const ReaderCaptionActions.reFlowable({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MorphIconButton(
          icon: LucideIcons.x,
          hoverIcon: LucideIcons.xCircle,
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
