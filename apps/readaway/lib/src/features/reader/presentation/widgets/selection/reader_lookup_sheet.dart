import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/services/toast/toast_service.dart';
import '../../../../../core/services/toast/toast_types.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// Mode selector for the lookup bottom sheet.
enum ReaderLookupMode {
  definition,
  translation,
}

/// A modal sheet presenting dictionary definitions and translation for a selected passage.
class ReaderLookupSheet extends StatefulWidget {
  const ReaderLookupSheet({
    super.key,
    required this.selectedText,
    this.initialMode = ReaderLookupMode.definition,
  });

  final String selectedText;
  final ReaderLookupMode initialMode;

  /// Shows the lookup sheet for the given [selectedText].
  static Future<void> show({
    required BuildContext context,
    required String selectedText,
    ReaderLookupMode initialMode = ReaderLookupMode.definition,
  }) => showAppSheet<void>(
    context: context,
    title: initialMode == ReaderLookupMode.definition
        ? 'Definition'
        : 'Translate',
    builder: (_) => ReaderLookupSheet(
      selectedText: selectedText,
      initialMode: initialMode,
    ),
  );

  @override
  State<ReaderLookupSheet> createState() => _ReaderLookupSheetState();
}

class _ReaderLookupSheetState extends State<ReaderLookupSheet> {
  late ReaderLookupMode _mode = widget.initialMode;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final isWord = !widget.selectedText.trim().contains(' ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Switcher
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: appColors.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: appColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SegmentButton(
                    label: 'Define',
                    icon: LucideIcons.bookOpen,
                    selected: _mode == ReaderLookupMode.definition,
                    onTap: () => setState(
                      () => _mode = ReaderLookupMode.definition,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _SegmentButton(
                    label: 'Translate',
                    icon: LucideIcons.languages,
                    selected: _mode == ReaderLookupMode.translation,
                    onTap: () => setState(
                      () => _mode = ReaderLookupMode.translation,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Excerpt preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: appColors.sidebarBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: appColors.badgeBackground ?? appColors.scheme.primary,
                  width: 3.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  widget.selectedText.trim(),
                  variant: AppTextVariant.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  color: appColors.sidebarForeground,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Content Body
          if (_mode == ReaderLookupMode.definition)
            _buildDefinitionView(context, isWord)
          else
            _buildTranslationView(context),

          const SizedBox(height: 20),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(LucideIcons.copy, size: 16),
                label: const Text('Copy'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.selectedText));
                  context.showToast(
                    message: 'Copied to clipboard',
                    type: ToastType.info,
                  );
                },
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(LucideIcons.share2, size: 16),
                label: const Text('Share'),
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(text: widget.selectedText),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefinitionView(BuildContext context, bool isWord) {
    final appColors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.bookMarked,
                size: 16,
                color: appColors.inputPlaceholderForeground,
              ),
              const SizedBox(width: 6),
              AppText(
                isWord ? 'Dictionary Entry' : 'Passage Definition',
                variant: AppTextVariant.caption,
                color: appColors.inputPlaceholderForeground,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppText(
            isWord
                ? 'Ready for offline dictionary integration. Connect StarDict, Webster, or Wiktionary provider.'
                : 'Phrase / clause lookup available. Select a single word for concise lexical definitions.',
            variant: AppTextVariant.body,
            color: appColors.inputForeground,
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationView(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.languages,
                size: 16,
                color: appColors.inputPlaceholderForeground,
              ),
              const SizedBox(width: 6),
              AppText(
                'Translation Provider',
                variant: AppTextVariant.caption,
                color: appColors.inputPlaceholderForeground,
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppText(
            'Ready for translation services (Google, DeepL, LibreTranslate, or local LLM). Pluggable via ReaderSelectionActionRegistry.',
            variant: AppTextVariant.body,
            color: appColors.inputForeground,
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final primaryColor = appColors.badgeBackground ?? appColors.scheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: context.appMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? primaryColor
                  : appColors.sidebarForeground.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? primaryColor
                    : appColors.sidebarForeground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
