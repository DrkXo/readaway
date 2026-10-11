import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'metro_pressable.dart';

/// Presentation style of a [MetroPivotControl].
enum MetroPivotControlStyle {
  /// Authentic panoramic sub-pivot typography: lowercase text items
  /// where the active item is high-contrast/accented with an accent underline
  /// indicator, and inactive items are dimmed to 40% opacity.
  pivot,

  /// Contiguous flat rectangular segments with zero border radius (`BorderRadius.zero`),
  /// hairline borders, and solid accent fill for the active item.
  flatTiles,
}

/// Size tier for a [MetroPivotControl].
enum MetroPivotControlSize {
  /// Standard sizing for section and view switching (e.g. tabs, category pivots).
  normal,

  /// Compact sizing for form rows, inline preference selectors, and tight toolbars.
  compact,
}

/// A single selectable item in a [MetroPivotControl].
class MetroPivotControlItem<T> {
  const MetroPivotControlItem({
    required this.value,
    required this.label,
    this.icon,
    this.count,
    this.tooltip,
  });

  /// The unique value associated with this item.
  final T value;

  /// The display label (typically lowercase to match Metro typography).
  final String label;

  /// Optional icon placed beside the label.
  final IconData? icon;

  /// Optional counter or tag string (e.g. "12", "new").
  final String? count;

  /// Optional tooltip and accessibility label.
  final String? tooltip;
}

/// Reusable Lumia / Windows Phone Metro Pivot control.
///
/// Designed as a first-class Metro replacement for Material 3 [SegmentedButton]
/// and rounded tab bars across the application.
///
/// Features:
/// - Signature typography (high-contrast active label vs 40% dimmed inactive labels).
/// - 3D press tilt feedback powered by [MetroPressable].
/// - Animated accent underline indicator in [MetroPivotControlStyle.pivot] mode.
/// - Flat zero-border-radius contiguous tiles in [MetroPivotControlStyle.flatTiles] mode.
/// - Fluid horizontal scrolling for narrow viewports or many tabs with auto-scroll-to-selected.
/// - Full keyboard, accessibility, and [Semantics] support.
class MetroPivotControl<T> extends StatefulWidget {
  const MetroPivotControl({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.style = MetroPivotControlStyle.pivot,
    this.size = MetroPivotControlSize.normal,
    this.expanded = false,
    this.padding = EdgeInsets.zero,
    this.enabled = true,
  });

  /// List of items to select from.
  final List<MetroPivotControlItem<T>> items;

  /// Currently selected item value.
  final T value;

  /// Callback fired when an item is selected.
  final ValueChanged<T> onChanged;

  /// Visual styling mode (sub-pivot typography vs flat tiles).
  final MetroPivotControlStyle style;

  /// Size tier (normal for tabs/sub-pivots, compact for inline form controls).
  final MetroPivotControlSize size;

  /// If true, items expand equally to fill the available width.
  /// If false, items take their natural intrinsic width and scroll horizontally if needed.
  final bool expanded;

  /// Padding around the entire control.
  final EdgeInsetsGeometry padding;

  /// Whether user interaction is enabled.
  final bool enabled;

  @override
  State<MetroPivotControl<T>> createState() => _MetroPivotControlState<T>();
}

class _MetroPivotControlState<T> extends State<MetroPivotControl<T>> {
  late final ScrollController _scrollController;
  final List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _updateItemKeys();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToSelected(animate: false),
    );
  }

  @override
  void didUpdateWidget(MetroPivotControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      _updateItemKeys();
    }
    if (widget.value != oldWidget.value) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToSelected(animate: true),
      );
    }
  }

  void _updateItemKeys() {
    _itemKeys.clear();
    for (var i = 0; i < widget.items.length; i++) {
      _itemKeys.add(GlobalKey());
    }
  }

  void _scrollToSelected({required bool animate}) {
    if (!mounted || widget.expanded || !_scrollController.hasClients) return;
    final selectedIndex = widget.items.indexWhere(
      (item) => item.value == widget.value,
    );
    if (selectedIndex < 0 || selectedIndex >= _itemKeys.length) return;

    final context = _itemKeys[selectedIndex].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    final content = widget.style == MetroPivotControlStyle.pivot
        ? _buildPivotStyle(context, appColors)
        : _buildFlatTilesStyle(context, appColors);

    return Padding(
      padding: widget.padding,
      child: content,
    );
  }

  Widget _buildPivotStyle(BuildContext context, AppColors appColors) {
    final isCompact = widget.size == MetroPivotControlSize.compact;
    final fontSize = isCompact ? 14.0 : 18.0;
    final iconSize = isCompact ? 14.0 : 16.0;
    final spacing = isCompact ? 18.0 : 24.0;

    final children = <Widget>[];

    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final isSelected = item.value == widget.value;

      final activeColor = appColors.buttonBackground;
      final inactiveColor = appColors.readerForeground.withValues(alpha: 0.40);
      final itemColor = isSelected ? activeColor : inactiveColor;

      final tabContent = MetroPressable(
        key: i < _itemKeys.length ? _itemKeys[i] : null,
        enabled: widget.enabled,
        onTap: () {
          if (!isSelected) {
            widget.onChanged(item.value);
          }
        },
        child: Semantics(
          selected: isSelected,
          button: true,
          label: item.tooltip ?? item.label,
          child: Tooltip(
            message: item.tooltip ?? item.label,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.expanded ? 4.0 : 0.0,
                vertical: isCompact ? 4.0 : 6.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          size: iconSize,
                          color: itemColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        item.label.toLowerCase(),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          letterSpacing: isCompact ? -0.2 : -0.4,
                          color: itemColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.count != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          color: isSelected
                              ? appColors.buttonBackground
                              : appColors.readerForeground.withValues(
                                  alpha: 0.12,
                                ),
                          child: Text(
                            item.count!,
                            style: TextStyle(
                              fontSize: isCompact ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? appColors.buttonForeground
                                  : appColors.readerForeground.withValues(
                                      alpha: 0.65,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    height: 2.5,
                    width: widget.expanded ? double.infinity : null,
                    color: isSelected
                        ? appColors.buttonBackground
                        : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (widget.expanded) {
        children.add(Expanded(child: tabContent));
      } else {
        if (i > 0) children.add(SizedBox(width: spacing));
        children.add(tabContent);
      }
    }

    if (widget.expanded) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  Widget _buildFlatTilesStyle(BuildContext context, AppColors appColors) {
    final isCompact = widget.size == MetroPivotControlSize.compact;
    final fontSize = isCompact ? 12.5 : 14.0;
    final iconSize = isCompact ? 14.0 : 16.0;
    final verticalPadding = isCompact ? 7.0 : 10.0;
    final horizontalPadding = isCompact ? 10.0 : 14.0;

    final children = <Widget>[];

    for (var i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final isSelected = item.value == widget.value;

      final tileContent = MetroPressable(
        key: i < _itemKeys.length ? _itemKeys[i] : null,
        enabled: widget.enabled,
        onTap: () {
          if (!isSelected) {
            widget.onChanged(item.value);
          }
        },
        child: Semantics(
          selected: isSelected,
          button: true,
          label: item.tooltip ?? item.label,
          child: Tooltip(
            message: item.tooltip ?? item.label,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              color: isSelected
                  ? appColors.buttonBackground
                  : appColors.readerForeground.withValues(alpha: 0.03),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: iconSize,
                      color: isSelected
                          ? appColors.buttonForeground
                          : appColors.readerForeground.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    item.label.toLowerCase(),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? appColors.buttonForeground
                          : appColors.readerForeground.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      color: isSelected
                          ? appColors.buttonForeground.withValues(alpha: 0.20)
                          : appColors.readerForeground.withValues(alpha: 0.12),
                      child: Text(
                        item.count!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? appColors.buttonForeground
                              : appColors.readerForeground.withValues(
                                  alpha: 0.65,
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

      if (widget.expanded) {
        children.add(Expanded(child: tileContent));
      } else {
        children.add(tileContent);
      }

      if (i < widget.items.length - 1) {
        children.add(
          Container(
            width: 1,
            color: appColors.readerForeground.withValues(alpha: 0.08),
          ),
        );
      }
    }

    final row = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      children: children,
    );

    final border = Border.all(
      color: appColors.readerForeground.withValues(alpha: 0.08),
      width: 1,
    );

    if (widget.expanded) {
      return Container(
        decoration: BoxDecoration(border: border),
        child: row,
      );
    }

    return Container(
      decoration: BoxDecoration(border: border),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: row,
      ),
    );
  }
}

/// Alias for [MetroPivotControl] emphasizing its role as a pivot tab bar.
typedef MetroPivotBar<T> = MetroPivotControl<T>;

/// Alias for [MetroPivotControlItem].
typedef MetroPivotBarItem<T> = MetroPivotControlItem<T>;
