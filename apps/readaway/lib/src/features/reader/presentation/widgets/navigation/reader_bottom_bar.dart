import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import '../../bloc/tts/reader_tts_bloc.dart';
import 'reader_bottom_bar_mixin.dart';
import 'reader_bottom_panel.dart';

export 'panels/panels.dart';
export 'reader_bottom_bar_mixin.dart';
export 'reader_bottom_panel.dart';

/// Fixed-height reader navigation bar with 5 primary Metro action controls:
/// - Outline / Table of Contents ('contents')
/// - Display Brightness & Theme Mode ('theme')
/// - Page Navigation Scrubber ('pages')
/// - Font Resizing & Scale Chips ('font', reflowable only)
/// - TTS (Text-to-Speech) ('listen', reflowable only)
///
/// Designed with flat non-circular Lumia Metro aesthetics, 3D perspective touch
/// tilt via [MetroPressable], and active theme accent indicators.
///
/// Contextual quick panels extend upward from the bar in a docked overlay,
/// avoiding Scaffold layout shifts and preventing document re-layouts.
class ReaderBottomBar extends StatefulWidget {
  const ReaderBottomBar({
    super.key,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSeekToPage,
    this.documentPath,
    this.onOpenDrawer,
    this.onOutlineTap,
    this.panelWidth = double.infinity,
    this.panelMaxWidth = double.infinity,
    this.backgroundColor,
    this.panelBackgroundColor,
    this.showTopBorder = false,
  });

  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onSeekToPage;
  final String? documentPath;
  final VoidCallback? onOutlineTap;
  final VoidCallback? onOpenDrawer;

  /// Optional fixed width for the contextual controls panel.
  /// Defaults to [double.infinity] to fill max available width.
  final double panelWidth;

  /// Maximum allowed width for the contextual controls panel.
  /// Defaults to [double.infinity].
  final double panelMaxWidth;

  /// Optional background color for the reader bottom bar.
  /// Defaults to theme bottombar background.
  final Color? backgroundColor;

  /// Optional background color for the appearing contextual controls panel.
  /// If omitted, defaults to [backgroundColor] or the bottom bar surface color.
  final Color? panelBackgroundColor;

  /// Whether to draw a 1px top border on the bar.
  /// Defaults to `false` (flat, no separator line).
  final bool showTopBorder;

  /// Fixed height of the navigation bar.
  static const double height = 58;

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
          prev.isReflowable != curr.isReflowable,
      builder: (context, readerState) {
        if (!readerState.hasDocument) return const SizedBox.shrink();

        final appColors = context.appColors;
        final barBgColor =
            widget.backgroundColor ?? appColors.bottombarBackground;

        return Container(
          decoration: BoxDecoration(
            color: barBgColor,
            border: widget.showTopBorder
                ? Border(
                    top: BorderSide(
                      color: appColors.bottombarBorder,
                      width: 1.0,
                    ),
                  )
                : null,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: ReaderBottomBar.height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Outline (Chapters / TOC)
                  _MetroReaderBarAction(
                    icon: LucideIcons.panelLeft,
                    label: 'contents',
                    tooltip: 'Outline',
                    semanticLabel: 'Open chapter outline',
                    onTap: handleOutlineTap,
                  ),

                  // 2. Brightness & Theme
                  _MetroReaderBarAction(
                    icon: LucideIcons.sunMedium,
                    label: 'theme',
                    tooltip: 'Brightness & Theme',
                    isActive: activePanel == ReaderBottomPanel.brightness,
                    semanticLabel: 'Display brightness and theme adjustment',
                    onTap: () => togglePanel(ReaderBottomPanel.brightness),
                  ),

                  // 3. Page Navigation
                  _MetroReaderBarAction(
                    icon: LucideIcons.slidersHorizontal,
                    label: 'pages',
                    tooltip: 'Page navigation',
                    isActive: activePanel == ReaderBottomPanel.pageNavigation,
                    semanticLabel: 'Page scrubber and jump controls',
                    onTap: () => togglePanel(ReaderBottomPanel.pageNavigation),
                  ),

                  // 4. Font Resizing (Reflowable only)
                  if (readerState.isReflowable)
                    _MetroReaderBarAction(
                      icon: LucideIcons.type,
                      label: 'font',
                      tooltip: 'Font size',
                      isActive: activePanel == ReaderBottomPanel.fontSize,
                      semanticLabel: 'Font size adjustment',
                      onTap: () => togglePanel(ReaderBottomPanel.fontSize),
                    ),

                  // 5. TTS (Text to Speech) (Reflowable only)
                  if (readerState.isReflowable)
                    BlocSelector<ReaderTtsBloc, ReaderTtsState, bool>(
                      selector: (ttsState) => ttsState.ttsActive,
                      builder: (context, ttsActive) {
                        return _MetroReaderBarAction(
                          icon: LucideIcons.audioLines,
                          label: 'listen',
                          tooltip: ttsActive
                              ? 'Close TTS player'
                              : 'Listen (TTS player)',
                          isActive: ttsActive,
                          semanticLabel: 'Text to speech player toggle',
                          onTap: () => handleTtsTap(readerState),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A flat non-circular action button adhering strictly to Metro UI guidelines.
///
/// Features:
/// - 3D perspective touch feedback powered by [MetroPressable].
/// - High-contrast lowercase typography label below the vector icon.
/// - Vibrant accent color transition and 2px flat underline indicator when active.
/// - Zero circular borders, zero rounded corners.
class _MetroReaderBarAction extends StatelessWidget {
  const _MetroReaderBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.tooltip,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final String? tooltip;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final activeColor = appColors.buttonBackground;
    final inactiveColor = appColors.bottombarForeground.withValues(alpha: 0.7);
    final effectiveColor = isActive ? activeColor : inactiveColor;

    Widget content = MetroPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: effectiveColor,
            ),
            const SizedBox(height: 3),
            MetroText.appBarLabel(
              label.toLowerCase(),
              color: effectiveColor,
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: 2,
              width: isActive ? 18 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      content = Tooltip(
        message: tooltip!,
        child: content,
      );
    }

    if (semanticLabel != null) {
      content = Semantics(
        label: semanticLabel,
        button: true,
        selected: isActive,
        child: content,
      );
    }

    return content;
  }
}
