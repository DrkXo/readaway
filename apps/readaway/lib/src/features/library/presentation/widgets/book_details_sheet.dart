import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entity/reading_status.dart';
import '../../domain/entity/recent_document.dart';
import 'book_cover_widget.dart';

class BookDetailsSheet extends StatelessWidget {
  const BookDetailsSheet({
    super.key,
    required this.document,
    required this.onOpenReader,
    required this.onToggleFavorite,
    required this.onUpdateStatus,
    required this.onRemove,
  });

  final RecentDocument document;
  final VoidCallback onOpenReader;
  final VoidCallback onToggleFavorite;
  final ValueChanged<ReadingStatus> onUpdateStatus;
  final VoidCallback onRemove;

  static Future<void> show(
    BuildContext context, {
    required RecentDocument document,
    required VoidCallback onOpenReader,
    required VoidCallback onToggleFavorite,
    required ValueChanged<ReadingStatus> onUpdateStatus,
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
        onOpenReader: onOpenReader,
        onToggleFavorite: onToggleFavorite,
        onUpdateStatus: onUpdateStatus,
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
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                    coverPath: document.coverPath,
                    title: document.displayTitle,
                    author: document.displayAuthor,
                    format: document.format,
                    progressPercent: document.progressPercent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (document.displayAuthor != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          document.displayAuthor!,
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
                            label: document.formatBadge,
                            color: scheme.primaryContainer,
                            textColor: scheme.onPrimaryContainer,
                          ),
                          if (document.formattedFileSize.isNotEmpty)
                            _Badge(
                              label: document.formattedFileSize,
                              color: scheme.surfaceContainerHighest,
                              textColor: scheme.onSurfaceVariant,
                            ),
                          if (document.pageCount > 0)
                            _Badge(
                              label: '${document.pageCount} pages',
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
              ],
              selected: {document.readingStatus},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  onUpdateStatus(selected.first);
                }
              },
            ),

            const SizedBox(height: 20),

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
                    value: _formatDate(document.dateAdded),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: LucideIcons.history,
                    label: 'Last Opened',
                    value: _formatDate(document.lastOpened),
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: LucideIcons.percent,
                    label: 'Progress',
                    value: document.pageCount > 0
                        ? 'Page ${document.lastReadPage + 1} of ${document.pageCount} (${document.progressFormatted})'
                        : document.readingStatus.label,
                  ),
                  const Divider(height: 1),
                  _InfoRow(
                    icon: LucideIcons.folder,
                    label: 'File Path',
                    value: document.path,
                    isTruncated: true,
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.copy, size: 16),
                      tooltip: 'Copy file path',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: document.path));
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
                    document.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: document.isFavorite ? Colors.amber : scheme.primary,
                  ),
                  tooltip: document.isFavorite
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRemove();
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
