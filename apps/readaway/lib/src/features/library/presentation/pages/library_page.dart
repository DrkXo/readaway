import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routes/routes.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entity/recent_document.dart';
import '../cubit/library_cubit.dart';
import '../cubit/library_state.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<LibraryCubit>()..loadRecentDocuments(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  void _navigateToReader(BuildContext context, String path, String fileName) {
    final route =
        '${appRoutes.reader.path}?path=${Uri.encodeComponent(path)}&fileName=${Uri.encodeComponent(fileName)}';
    GoRouter.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LibraryCubit, LibraryState>(
      listenWhen: (prev, curr) =>
          curr.openedDocument != null &&
          prev.openedDocument != curr.openedDocument,
      listener: (context, state) {
        final doc = state.openedDocument;
        if (doc != null) {
          context.read<LibraryCubit>().clearOpened();
          _navigateToReader(context, doc.path, doc.fileName);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: const AppTopBar(
            titleText: 'ReadAway',
          ),
          body: Column(
            children: [
              if (state.failure != null)
                FailureBanner(
                  failure: state.failure!,
                  onRetry: () =>
                      context.read<LibraryCubit>().loadRecentDocuments(),
                  onDismiss: () =>
                      context.read<LibraryCubit>().loadRecentDocuments(),
                ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state.isLoading && state.recentDocuments.isEmpty) {
                      return const AppLoadingView(label: 'Loading library...');
                    }

                    if (state.recentDocuments.isEmpty) {
                      return AppEmptyView(
                        icon: LucideIcons.bookOpen,
                        title: 'Your Library is Empty',
                        message:
                            'Open a book, document, or comic to start reading.',
                        actionLabel: 'Open Document',
                        onAction: () =>
                            context.read<LibraryCubit>().pickAndOpenDocument(),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: state.recentDocuments.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final doc = state.recentDocuments[index];
                        return _RecentDocumentTile(
                          document: doc,
                          onTap: () =>
                              _navigateToReader(context, doc.path, doc.fileName),
                          onDelete: () =>
                              context.read<LibraryCubit>().removeRecent(doc.path),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(LucideIcons.folderOpen, size: 20),
            label: const Text('Open File'),
            onPressed: () => context.read<LibraryCubit>().pickAndOpenDocument(),
          ),
        );
      },
    );
  }
}

class _RecentDocumentTile extends StatelessWidget {
  const _RecentDocumentTile({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  final RecentDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final progressText = document.pageCount > 0
        ? 'Page ${document.lastReadPage + 1} of ${document.pageCount}'
        : 'Recently opened';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: _DocumentCoverThumbnail(coverPath: document.coverPath),
      title: Text(
        document.fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        progressText,
        style: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(LucideIcons.trash2, size: 18),
        tooltip: 'Remove from history',
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}

class _DocumentCoverThumbnail extends StatelessWidget {
  const _DocumentCoverThumbnail({this.coverPath});

  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final file = (coverPath != null && coverPath!.isNotEmpty)
        ? File(coverPath!)
        : null;

    final hasFile = file != null && file.existsSync();

    return Container(
      width: 44,
      height: 58,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasFile
          ? Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackIcon(scheme),
            )
          : _fallbackIcon(scheme),
    );
  }

  Widget _fallbackIcon(ColorScheme scheme) {
    return Center(
      child: Icon(
        LucideIcons.book,
        color: scheme.primary,
        size: 22,
      ),
    );
  }
}
