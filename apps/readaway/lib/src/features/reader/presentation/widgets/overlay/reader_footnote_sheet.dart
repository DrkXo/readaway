import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core_rust/readaway_core_rust.dart';

import 'package:readaway/src/core/theme/schemes/token_inspired.dart';
import 'package:readaway/src/core/theme/theme.dart';
import 'package:readaway/src/core/widgets/core_widgets.dart';

/// Modal bottom sheet / popover that displays an interactive footnote preview.
class ReaderFootnoteSheet extends StatelessWidget {
  const ReaderFootnoteSheet({
    super.key,
    required this.footnote,
    this.onJumpToNote,
  });

  final FootnoteItem footnote;
  final VoidCallback? onJumpToNote;

  /// Shows the footnote sheet within [context].
  static Future<void> show({
    required BuildContext context,
    required FootnoteItem footnote,
    VoidCallback? onJumpToNote,
  }) {
    return showAppSheet<void>(
      context: context,
      title: footnote.type == 'endnote' ? 'Endnote' : 'Footnote',
      maxWidth: 480,
      builder: (ctx) => ReaderFootnoteSheet(
        footnote: footnote,
        onJumpToNote: onJumpToNote,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? tokenInspiredDark
            : tokenInspiredLight);
    final plainText = HtmlTextExtractor.extractPageText(footnote.contentHtml);
    final isEndnote = footnote.type == 'endnote';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: colors.scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEndnote ? LucideIcons.bookmark : LucideIcons.info,
                      size: 14.0,
                      color: colors.scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      footnote.id.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: colors.scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Footnote content
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: SelectableText(
                plainText.isNotEmpty ? plainText : footnote.contentHtml,
                style: TextStyle(
                  fontSize: 15.0,
                  height: 1.5,
                  color: colors.readerForeground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: colors.scheme.outline),
                ),
              ),
              if (onJumpToNote != null) ...[
                const SizedBox(width: 8.0),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onJumpToNote!();
                  },
                  icon: const Icon(LucideIcons.arrowUpRight, size: 16.0),
                  label: const Text('Jump to Note'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
