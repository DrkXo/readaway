import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import 'reader_bottom_bar_mixin.dart';

export 'panels/panels.dart';
export 'reader_bottom_bar_mixin.dart';

/// Fixed-height reader navigation bar with 5 primary action controls:
/// - Outline / Table of Contents
/// - Display Brightness & Theme Mode
/// - Page Navigation Scrubber
/// - Font Resizing & Scale Chips
/// - TTS (Text-to-Speech)
///
/// Contextual quick panels extend upward from the bar in a docked overlay,
/// avoiding Scaffold layout shifts and preventing document re-layouts.
class ReaderBottomBar extends StatefulWidget {
  const ReaderBottomBar({
    super.key,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSeekToPage,
    this.onOpenDrawer,
    this.onOutlineTap,
    this.panelWidth = double.infinity,
    this.panelMaxWidth = double.infinity,
    this.backgroundColor,
    this.panelBackgroundColor,
  });

  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onSeekToPage;
  final VoidCallback? onOutlineTap;
  final VoidCallback? onOpenDrawer;

  /// Optional fixed width for the contextual controls panel.
  /// Defaults to [double.infinity] to fill max available width.
  final double panelWidth;

  /// Maximum allowed width for the contextual controls panel.
  /// Defaults to [double.infinity].
  final double panelMaxWidth;

  /// Optional background color for the reader bottom bar.
  /// Defaults to [ColorScheme.surface] with alpha 0.95.
  final Color? backgroundColor;

  /// Optional background color for the appearing contextual controls panel.
  /// If omitted, defaults to [backgroundColor] or the bottom bar surface color.
  final Color? panelBackgroundColor;

  /// Fixed height of the navigation bar.
  static const double height = 56;

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar>
    with SingleTickerProviderStateMixin, ReaderBottomBarMixin {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      buildWhen: (prev, curr) =>
          prev.hasDocument != curr.hasDocument ||
          prev.isReflowable != curr.isReflowable ||
          prev.ttsActive != curr.ttsActive,
      builder: (context, readerState) {
        if (!readerState.hasDocument) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final appColors = context.appColors;
        final barBgColor =
            widget.backgroundColor ?? scheme.surface.withValues(alpha: 0.95);

        return Container(
          height: ReaderBottomBar.height,
          decoration: BoxDecoration(
            color: barBgColor,
            boxShadow: appColors.shadowMd,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Outline (Chapters / TOC)
                AppIconButton(
                  icon: LucideIcons.panelLeft,
                  tooltip: 'Outline',
                  size: AppIconButtonSize.medium,
                  semanticLabel: 'Open chapter outline',
                  onPressed: handleOutlineTap,
                ),

                // 2. Brightness & Theme
                AppIconButton(
                  icon: LucideIcons.sunMedium,
                  tooltip: 'Brightness & Theme',
                  size: AppIconButtonSize.medium,
                  selected: activePanel == ReaderBottomPanel.brightness,
                  semanticLabel: 'Display brightness and theme adjustment',
                  onPressed: () => togglePanel(ReaderBottomPanel.brightness),
                ),

                // 3. Page Navigation
                AppIconButton(
                  icon: LucideIcons.slidersHorizontal,
                  tooltip: 'Page navigation',
                  size: AppIconButtonSize.medium,
                  selected: activePanel == ReaderBottomPanel.pageNavigation,
                  semanticLabel: 'Page scrubber and jump controls',
                  onPressed: () =>
                      togglePanel(ReaderBottomPanel.pageNavigation),
                ),

                // 4. Font Resizing
                AppIconButton(
                  icon: LucideIcons.type,
                  tooltip: readerState.isReflowable
                      ? 'Font size'
                      : 'Font resizing (Reflowable only)',
                  size: AppIconButtonSize.medium,
                  selected: activePanel == ReaderBottomPanel.fontSize,
                  semanticLabel: 'Font size adjustment',
                  onPressed: readerState.isReflowable
                      ? () => togglePanel(ReaderBottomPanel.fontSize)
                      : null,
                ),

                // 5. TTS (Text to Speech)
                AppIconButton(
                  icon: LucideIcons.audioLines,
                  tooltip: readerState.isReflowable
                      ? (readerState.ttsActive
                            ? 'Close TTS player'
                            : 'Listen (TTS player)')
                      : 'TTS (Reflowable only)',
                  size: AppIconButtonSize.medium,
                  selected: readerState.ttsActive,
                  semanticLabel: 'Text to speech player toggle',
                  onPressed: readerState.isReflowable
                      ? () => handleTtsTap(readerState)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
