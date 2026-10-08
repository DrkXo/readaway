import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hyper_render/hyper_render.dart' show HyperSelectionOverlayState;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart' show PaginationCoordinator;

import '../../../../../core/theme/theme.dart';
import '../../../../../core/theme/tts_highlight_palette.dart';
import '../../controllers/reader_viewport_controller.dart';
import 'reader_selection_action.dart';
import 'reader_selection_action_registry.dart';
import 'reader_selection_context.dart';

/// Modern floating capsule context menu for text selection in the reader.
///
/// Features:
/// - Frosted glass / surface elevation matching active [VsCodeTheme].
/// - 1-tap highlight color swatches (Kindle / Apple Books style).
/// - 44pt touch targets with accessible tooltips and semantics.
/// - Overflow popover for secondary reading tools (Translate, Define, Speak, Share).
class ReaderSelectionContextMenu extends StatelessWidget {
  const ReaderSelectionContextMenu({
    super.key,
    required this.chapterIndex,
    required this.coordinator,
    required this.overlayState,
    this.controller,
  });

  final int chapterIndex;
  final PaginationCoordinator coordinator;
  final HyperSelectionOverlayState overlayState;
  final ReaderViewportController? controller;

  @override
  Widget build(BuildContext context) {
    final selCtx = ReaderSelectionActionRegistry.buildContext(
      context: context,
      chapterIndex: chapterIndex,
      coordinator: coordinator,
      overlayState: overlayState,
      controller: controller,
    );

    final appColors = context.appColors;
    final primaryActions = ReaderSelectionActionRegistry.getPrimaryActions(
      selCtx,
    );
    final secondaryActions = ReaderSelectionActionRegistry.getSecondaryActions(
      selCtx,
    );

    // Color swatches (top 5 high-contrast reader palette colors)
    final swatches = kTtsHighlightColorOptions.take(5).toList();
    final currentHighlightColor = selCtx.existingHighlight?.colorValue;

    return Semantics(
      container: true,
      label: 'Text selection menu',
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: appColors.sidebarBackground.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: appColors.borderSubtle.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Highlight color swatches
                    for (final option in swatches)
                      _HighlightColorDot(
                        colorKey: option.key,
                        label: option.label,
                        isSelected: currentHighlightColor == option.key,
                        onTap: () =>
                            ReaderSelectionActionRegistry.applyHighlight(
                              selCtx,
                              option.key,
                            ),
                      ),

                    // Unhighlight / Eraser button if passage is already highlighted
                    if (selCtx.isHighlighted) ...[
                      _MenuIconButton(
                        icon: LucideIcons.eraser,
                        label: 'Unhighlight',
                        tooltip: 'Remove highlight',
                        color: appColors.sidebarForeground.withValues(
                          alpha: 0.8,
                        ),
                        onTap: () =>
                            ReaderSelectionActionRegistry.removeHighlight(
                              selCtx,
                            ),
                      ),
                    ],

                    _buildVerticalDivider(appColors.borderSubtle),

                    // Primary action buttons (Note, Copy)
                    for (final action in primaryActions)
                      _MenuIconButton(
                        icon: action.icon,
                        label: action.label,
                        tooltip: action.tooltip ?? action.label,
                        onTap: () => action.onTap(selCtx),
                      ),

                    _buildVerticalDivider(appColors.borderSubtle),

                    // More (...) overflow menu
                    _OverflowMenuButton(
                      actions: secondaryActions,
                      selCtx: selCtx,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(Color borderColor) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: borderColor.withValues(alpha: 0.4),
    );
  }
}

/// Circular highlight color swatch with expanded touch target.
class _HighlightColorDot extends StatelessWidget {
  const _HighlightColorDot({
    required this.colorKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String colorKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final swatchColor = resolveTtsHighlightColor(colorKey, scheme);

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Highlight in $label',
      child: Tooltip(
        message: 'Highlight: $label',
        child: InkResponse(
          onTap: onTap,
          radius: 20,
          containedInkWell: true,
          highlightShape: BoxShape.circle,
          child: Container(
            width: 32,
            height: 38,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: context.appMotion.fast,
              width: isSelected ? 22 : 18,
              height: isSelected ? 22 : 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: swatchColor,
                border: Border.all(
                  color: isSelected
                      ? scheme.onSurface
                      : Colors.black.withValues(alpha: 0.15),
                  width: isSelected ? 2.2 : 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: swatchColor.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An accessible icon button styled for the floating selection pill.
class _MenuIconButton extends StatelessWidget {
  const _MenuIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final iconColor = color ?? appColors.sidebarForeground;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: tooltip ?? label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Overflow button ('...') opening secondary actions popover or bottom sheet.
class _OverflowMenuButton extends StatelessWidget {
  const _OverflowMenuButton({
    required this.actions,
    required this.selCtx,
  });

  final List<ReaderSelectionAction> actions;
  final ReaderSelectionContext selCtx;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Semantics(
      button: true,
      label: 'More options',
      child: Tooltip(
        message: 'More options',
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOverflowMenu(context),
          child: Container(
            width: 36,
            height: 38,
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.ellipsis,
              size: 18,
              color: appColors.sidebarForeground,
            ),
          ),
        ),
      ),
    );
  }

  void _showOverflowMenu(BuildContext context) {
    final appColors = context.appColors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              color: appColors.sidebarBackground,
              clipBehavior: Clip.antiAlias,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: appColors.borderSubtle.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: appColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  for (final action in actions)
                    ListTile(
                      leading: Icon(
                        action.icon,
                        size: 20,
                        color: appColors.sidebarForeground,
                      ),
                      title: Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: appColors.sidebarForeground,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        action.onTap(selCtx);
                      },
                    ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
