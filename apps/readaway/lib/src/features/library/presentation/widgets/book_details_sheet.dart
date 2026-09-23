import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import '../bloc/library_bloc.dart';
import 'book_cover_widget.dart';

class BookDetailsSheet extends StatelessWidget {
  const BookDetailsSheet({
    super.key,
    required this.document,
    required this.bloc,
    required this.onOpenReader,
    required this.onToggleFavorite,
    required this.onUpdateStatus,
    required this.onResetProgress,
    required this.onRemove,
  });

  final RecentDocument document;
  final LibraryBloc bloc;
  final VoidCallback onOpenReader;
  final VoidCallback onToggleFavorite;
  final ValueChanged<ReadingStatus> onUpdateStatus;
  final VoidCallback onResetProgress;
  final VoidCallback onRemove;

  static Future<void> show(
    BuildContext context, {
    required RecentDocument document,
    required LibraryBloc bloc,
    required VoidCallback onOpenReader,
    required VoidCallback onToggleFavorite,
    required ValueChanged<ReadingStatus> onUpdateStatus,
    required VoidCallback onResetProgress,
    required VoidCallback onRemove,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookDetailsSheet(
        document: document,
        bloc: bloc,
        onOpenReader: onOpenReader,
        onToggleFavorite: onToggleFavorite,
        onUpdateStatus: onUpdateStatus,
        onResetProgress: onResetProgress,
        onRemove: onRemove,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      bloc: bloc,
      builder: (context, state) {
        final doc = state.recentDocuments.firstWhere(
          (d) => d.path == document.path,
          orElse: () => document,
        );
        return _buildBody(context, doc);
      },
    );
  }

  Widget _buildBody(BuildContext context, RecentDocument doc) {
    final appColors = context.appColors;
    final scheme = appColors.scheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Cover + Title + Author
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 108,
                  child: BookCoverWidget(
                    coverPath: doc.coverPath,
                    title: doc.displayTitle,
                    author: doc.displayAuthor,
                    format: doc.format,
                    progressPercent: doc.progressPercent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (doc.displayAuthor != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          doc.displayAuthor!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Badge(
                            label: doc.formatBadge,
                            color: scheme.primaryContainer,
                            textColor: scheme.onPrimaryContainer,
                          ),
                          if (doc.formattedFileSize.isNotEmpty)
                            _Badge(
                              label: doc.formattedFileSize,
                              color: scheme.surfaceContainerHighest,
                              textColor: scheme.onSurfaceVariant,
                            ),
                          if (doc.pageCount > 0)
                            _Badge(
                              label: '${doc.pageCount} pages',
                              color: scheme.surfaceContainerHighest,
                              textColor: scheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Reading Status Selection
            Text(
              'Reading Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.outline,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ReadingStatus>(
              segments: const [
                ButtonSegment(
                  value: ReadingStatus.unread,
                  label: Text('Unread'),
                  icon: Icon(LucideIcons.clock, size: 14),
                ),
                ButtonSegment(
                  value: ReadingStatus.reading,
                  label: Text('Reading'),
                  icon: Icon(LucideIcons.bookOpen, size: 14),
                ),
                ButtonSegment(
                  value: ReadingStatus.finished,
                  label: Text('Finished'),
                  icon: Icon(LucideIcons.circleCheck, size: 14),
                ),
                ButtonSegment(
                  value: ReadingStatus.abandoned,
                  label: Text('On Hold'),
                  icon: Icon(LucideIcons.pauseCircle, size: 14),
                ),
              ],
              selected: {doc.readingStatus},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  onUpdateStatus(selected.first);
                }
              },
            ),

            if (doc.readingStatus != ReadingStatus.unread ||
                doc.lastReadPage > 0 ||
                doc.lastReadChapter > 0 ||
                doc.lastReadProgression > 0.0) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: scheme.error,
                  ),
                  icon: const Icon(LucideIcons.rotateCcw, size: 13),
                  label: const Text(
                    'Reset Progress to Beginning',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset Reading Progress?'),
                        content: Text(
                          'This will reset "${doc.displayTitle}" back to page 1 and mark it as unread.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      onResetProgress();
                    }
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Metadata info list
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.calendarPlus,
                    label: 'Date Added',
                    value: _formatDate(doc.dateAdded),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: LucideIcons.history,
                    label: 'Last Opened',
                    value: _formatDate(doc.lastOpened),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: LucideIcons.percent,
                    label: 'Progress',
                    value: doc.pageCount > 0
                        ? 'Page ${doc.lastReadPage + 1} of ${doc.pageCount} (${doc.progressFormatted})'
                        : doc.readingStatus.label,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: LucideIcons.folder,
                    label: 'File Path',
                    value: doc.path,
                    isTruncated: true,
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.copy, size: 16),
                      tooltip: 'Copy file path',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: doc.path));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Path copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(LucideIcons.bookOpen, size: 18),
                    label: const Text('Read Now'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOpenReader();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  icon: Icon(
                    LucideIcons.star,
                    color: doc.isFavorite ? appColors.warning : scheme.primary,
                  ),
                  tooltip: doc.isFavorite
                      ? 'Remove favorite'
                      : 'Add to favorites',
                  onPressed: onToggleFavorite,
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  icon: Icon(
                    LucideIcons.trash2,
                    color: scheme.error,
                  ),
                  tooltip: 'Remove from library',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Remove from Library?'),
                        content: Text(
                          'Are you sure you want to remove "${doc.displayTitle}" from your library?\n\nReading progress and preferences will be cleared. The book file on your device will NOT be deleted.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.error,
                              foregroundColor: scheme.onError,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      onRemove();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isTruncated = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isTruncated;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.outline),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: isTruncated ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
