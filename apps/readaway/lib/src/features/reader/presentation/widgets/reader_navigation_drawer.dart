import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:readaway/src/features/reader/presentation/bloc/reader_bloc.dart';
import 'package:readaway/src/features/reader/presentation/widgets/reader_overlay_controller.dart';

class ReaderNavigationDrawer extends StatelessWidget {
  const ReaderNavigationDrawer({
    super.key,
    required this.controller,
  });

  final ReaderOverlayController controller;

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        FadeEffect(duration: 200.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(-1, 0),
          end: Offset.zero,
          duration: 200.ms,
          curve: Curves.easeOut,
        ),
      ],
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(
                'Reader Menu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Table of Contents'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Bookmarks'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Reader Settings'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Close Reader'),
              onTap: () {
                context.read<ReaderBloc>().add(const ReaderEvent.closeDocument());
                GoRouter.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
