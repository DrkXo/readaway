part of '../core_widgets.dart';

/// Unified adaptive TopBar for ReadAway supporting both Desktop and Mobile.
///
/// On Desktop:
/// - Provides frameless window dragging and double-click maximize/restore.
/// - Shows window caption controls (minimize, maximize/restore, close app).
/// - Sleek 42px compact desktop height.
///
/// On Mobile (Android / iOS):
/// - Respects [SafeArea] with standard 56px touch height.
/// - Hides window caption controls.
/// - Prioritizes clean touch-friendly actions.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.leading,
    this.title,
    this.titleText,
    this.subtitle,
    this.subtitleText,
    this.actions,
    this.showSettings = true,
    this.showCaptionControls = true,
    this.onSettingsPressed,
    this.settingsTooltip = 'Settings',
    this.height,
    this.showBottomBorder = true,
    this.backgroundColor,
    this.contentPadding,
  });

  final Widget? leading;
  final Widget? title;
  final String? titleText;
  final Widget? subtitle;
  final String? subtitleText;
  final List<Widget>? actions;
  final bool showSettings;
  final bool showCaptionControls;
  final VoidCallback? onSettingsPressed;
  final String settingsTooltip;
  final double? height;
  final bool showBottomBorder;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;

  static const double desktopHeight = 42.0;
  static const double mobileHeight = 56.0;

  bool get _isDesktop => GetIt.I<WindowService>().isDesktop;

  @override
  Size get preferredSize => Size.fromHeight(
        height ?? (_isDesktop ? desktopHeight : mobileHeight),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDesktop = _isDesktop;
    final windowService = GetIt.I<WindowService>();

    final barHeight = height ?? (isDesktop ? desktopHeight : mobileHeight);
    final effectiveBgColor = backgroundColor ??
        scheme.surface.withValues(alpha: isDesktop ? 0.96 : 0.92);

    Widget? titleWidget = title;
    if (titleWidget == null && titleText != null) {
      titleWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText!,
            style: isDesktop
                ? theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  )
                : theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            subtitle!
          else if (subtitleText != null)
            Text(
              subtitleText!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      );
    }

    return Container(
      height: isDesktop ? barHeight : null,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        border: showBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        top: !isDesktop,
        child: SizedBox(
          height: barHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading action or logo
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: leading!,
                )
              else if (isDesktop)
                const SizedBox(width: 14)
              else
                const SizedBox(width: 16),

              // Title and draggable window area
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart:
                      isDesktop ? (_) => windowService.startDragging() : null,
                  onDoubleTap: isDesktop ? windowService.toggleMaximize : null,
                  child: Container(
                    padding: contentPadding ??
                        const EdgeInsets.symmetric(horizontal: 8.0),
                    alignment: Alignment.centerLeft,
                    child: titleWidget ?? const SizedBox.shrink(),
                  ),
                ),
              ),

              // Action shortcuts (e.g. Reader Options)
              if (actions != null && actions!.isNotEmpty) ...[
                ...actions!,
                const SizedBox(width: 2),
              ],

              // Settings button
              if (showSettings)
                SettingsButton(
                  tooltip: settingsTooltip,
                  onPressed: onSettingsPressed,
                ),

              // Desktop Window Caption Controls
              if (showCaptionControls && isDesktop) ...[
                const SizedBox(width: 4),
                Container(
                  height: 18,
                  width: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                ),
                WindowCaptionControls(service: windowService),
              ] else if (!isDesktop) ...[
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
