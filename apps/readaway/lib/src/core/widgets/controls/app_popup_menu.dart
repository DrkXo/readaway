part of '../core_widgets.dart';

/// A single selectable entry of an [AppPopupMenu].
class AppPopupEntry<T> {
  const AppPopupEntry({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;

  /// Whether this entry uses the destructive (error) color.
  final bool destructive;
}

/// A divider between [AppPopupEntry]s.
class AppPopupDivider {
  const AppPopupDivider();
}

/// A header / section label inside an [AppPopupMenu].
class AppPopupHeader {
  const AppPopupHeader(this.label);

  final String label;
}

/// A tappable trigger that opens a theme-aware popup menu.
///
/// Wraps Flutter's [PopupMenuButton] with consistent theme tokens derived
/// from [AppColors], plus loading / error / empty states when [entries] is a
/// [Future]. Use this instead of raw `PopupMenuButton` for new UI so menus
/// stay consistent and handle async data gracefully.
///
/// When [entries] is a `Future<List<Object>>` (mix of [AppPopupEntry],
/// [AppPopupDivider], and [AppPopupHeader]), the menu shows an
/// [AppLoadingView] while resolving, an [AppErrorView] (with retry) on
/// failure, and an [AppEmptyView] when the list is empty.
class AppPopupMenu<T> extends StatelessWidget {
  const AppPopupMenu({
    super.key,
    required this.child,
    required this.onSelected,
    this.entries,
    this.future,
    this.tooltip,
    this.enabled = true,
    this.position = PopupMenuPosition.under,
    this.offset,
    this.menuMaxHeight,
    this.errorTitle = 'Could not load options',
    this.errorRetryLabel = 'Retry',
    this.emptyTitle = 'No options',
    this.emptyMessage,
    this.loadingLabel = 'Loading…',
  });

  /// The trigger widget that opens the menu when tapped.
  final Widget child;

  /// Called when the user selects an entry.
  final ValueChanged<T> onSelected;

  /// Synchronous list of menu items. Mutually exclusive with [future].
  final List<Object>? entries;

  /// Asynchronous source of menu items. Mutually exclusive with [entries].
  final Future<List<Object>>? future;

  /// Tooltip shown on the trigger.
  final String? tooltip;

  /// Whether the trigger is interactive.
  final bool enabled;

  /// Where the menu opens relative to the trigger.
  final PopupMenuPosition position;

  /// Offset of the menu relative to the trigger.
  final Offset? offset;

  /// Maximum height of the open menu.
  final double? menuMaxHeight;

  /// Title shown in the error state.
  final String errorTitle;

  /// Label of the retry action in the error state.
  final String errorRetryLabel;

  /// Title shown in the empty state.
  final String emptyTitle;

  /// Message shown in the empty state.
  final String? emptyMessage;

  /// Label shown while [future] is resolving.
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    // Synchronous path: render directly.
    if (entries != null) {
      return _buildButton(context, () async => entries!);
    }

    // Async path: resolve the future when the menu opens.
    final future = this.future;
    if (future == null) {
      return _buildButton(context, () async => const <Object>[]);
    }

    return _buildButton(context, () => future);
  }

  Widget _buildButton(
    BuildContext context,
    Future<List<Object>> Function() load,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<T>(
      tooltip: tooltip,
      enabled: enabled,
      position: position,
      offset: offset ?? Offset.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      constraints: BoxConstraints(
        maxHeight: menuMaxHeight ?? 480,
      ),
      onSelected: onSelected,
      itemBuilder: (context) => _AsyncMenuItems<T>(
        load: load,
        errorTitle: errorTitle,
        errorRetryLabel: errorRetryLabel,
        emptyTitle: emptyTitle,
        emptyMessage: emptyMessage,
        loadingLabel: loadingLabel,
      ).build(context),
      child: child,
    );
  }
}

/// Builds the popup menu items, resolving an async source with loading /
/// error / empty states.
class _AsyncMenuItems<T> {
  const _AsyncMenuItems({
    required this.load,
    required this.errorTitle,
    required this.errorRetryLabel,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.loadingLabel,
  });

  final Future<List<Object>> Function() load;
  final String errorTitle;
  final String errorRetryLabel;
  final String emptyTitle;
  final String? emptyMessage;
  final String loadingLabel;

  List<PopupMenuEntry<T>> build(BuildContext context) {
    // We can't await inside itemBuilder, so we render a single entry that
    // hosts a FutureBuilder. The menu stays open while the future resolves.
    return [
      PopupMenuItem<T>(
        enabled: false,
        height: 120,
        child: FutureBuilder<List<Object>>(
          future: load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return AppLoadingView(label: loadingLabel, compact: true);
            }
            if (snapshot.hasError) {
              return AppErrorView(
                title: errorTitle,
                retryLabel: errorRetryLabel,
              );
            }
            final resolved = snapshot.data ?? const <Object>[];
            if (resolved.isEmpty) {
              return AppEmptyView(
                icon: LucideIcons.inbox,
                title: emptyTitle,
                message: emptyMessage,
              );
            }
            // Render the resolved items inside a scrollable column.
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in resolved) _buildItem(context, item),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildItem(BuildContext context, Object item) {
    final scheme = Theme.of(context).colorScheme;

    if (item is AppPopupDivider) {
      return const PopupMenuDivider();
    }
    if (item is AppPopupHeader) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        child: AppCaption(item.label),
      );
    }
    if (item is AppPopupEntry<T>) {
      final entry = item;
      final color = entry.destructive
          ? scheme.error
          : entry.enabled
          ? scheme.onSurface
          : scheme.onSurface.withValues(alpha: 0.38);
      return PopupMenuItem<T>(
        value: entry.value,
        enabled: entry.enabled,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.icon != null) ...[
              Icon(
                entry.icon,
                size: 18,
                color: entry.destructive
                    ? scheme.error
                    : entry.enabled
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface.withValues(alpha: 0.38),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: AppText(
                entry.label,
                variant: AppTextVariant.body,
                color: color,
                fontWeight: entry.destructive
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
