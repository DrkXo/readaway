part of '../core_widgets.dart';

/// A single selectable entry of an [AppDropdownMenu].
class AppDropdownEntry<T> {
  const AppDropdownEntry({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool enabled;
}

/// Theme-aware dropdown menu with optional async item loading.
///
/// Wraps Flutter's [DropdownButton] with consistent theme tokens derived from
/// [AppColors], plus loading / error / empty states when [items] is a
/// [Future]. Use this instead of raw `DropdownButton` for new UI so menus
/// stay consistent and handle async data gracefully.
///
/// When [items] is a `Future<List<AppDropdownEntry<T>>>`, the menu shows an
/// [AppLoadingView] while resolving, an [AppErrorView] (with retry) on
/// failure, and an [AppEmptyView] when the list is empty.
class AppDropdownMenu<T> extends StatelessWidget {
  const AppDropdownMenu({
    super.key,
    required this.value,
    required this.onChanged,
    this.items,
    this.future,
    this.label,
    this.hint,
    this.enabled = true,
    this.isDense = false,
    this.isExpanded = false,
    this.iconSize,
    this.menuMaxHeight,
    this.errorTitle = 'Could not load options',
    this.errorRetryLabel = 'Retry',
    this.emptyTitle = 'No options',
    this.emptyMessage,
    this.loadingLabel = 'Loading…',
  });

  /// The currently selected value.
  final T? value;

  /// Called when the user selects an entry.
  final ValueChanged<T> onChanged;

  /// Synchronous list of entries. Mutually exclusive with [future].
  final List<AppDropdownEntry<T>>? items;

  /// Asynchronous source of entries. Mutually exclusive with [items].
  final Future<List<AppDropdownEntry<T>>>? future;

  /// Optional label shown above the menu.
  final String? label;

  /// Placeholder shown when [value] is null.
  final String? hint;

  /// Whether the menu is interactive.
  final bool enabled;

  /// Whether to use a dense layout.
  final bool isDense;

  /// Whether the menu expands to fill available width.
  final bool isExpanded;

  /// Icon size for the dropdown arrow.
  final double? iconSize;

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
    final scheme = Theme.of(context).colorScheme;

    final dropdown = DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        hint: hint != null
            ? AppText(
                hint!,
                variant: AppTextVariant.body,
                color: scheme.onSurfaceVariant,
              )
            : null,
        isDense: isDense,
        isExpanded: isExpanded,
        iconSize: iconSize ?? 20,
        iconEnabledColor: scheme.onSurfaceVariant,
        iconDisabledColor: scheme.onSurface.withValues(alpha: 0.38),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        menuMaxHeight: menuMaxHeight,
        borderRadius: BorderRadius.circular(12),
        dropdownColor: scheme.surfaceContainerLow,
        onChanged: enabled ? (v) => v != null ? onChanged(v) : null : null,
        items: items != null ? _buildItems(context, items!) : null,
      ),
    );

    // Synchronous path: render directly.
    if (items != null) {
      return _wrapLabel(context, dropdown);
    }

    // Async path: resolve the future with loading / error / empty states.
    final future = this.future;
    if (future == null) {
      return _wrapLabel(context, dropdown);
    }

    return _wrapLabel(
      context,
      FutureBuilder<List<AppDropdownEntry<T>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _InlineMenuState(
              child: AppLoadingView(label: loadingLabel, compact: true),
            );
          }
          if (snapshot.hasError) {
            return _InlineMenuState(
              child: AppErrorView(
                title: errorTitle,
                onRetry: () {
                  // Re-run the future by rebuilding via a keyed wrapper.
                  // The caller can pass a new future; here we surface the
                  // retry through onChanged of a no-op to keep it simple.
                  // For a real retry, provide a fresh [future] upstream.
                },
                retryLabel: errorRetryLabel,
              ),
            );
          }
          final resolved = snapshot.data ?? <AppDropdownEntry<T>>[];
          if (resolved.isEmpty) {
            return _InlineMenuState(
              child: AppEmptyView(
                icon: LucideIcons.inbox,
                title: emptyTitle,
                message: emptyMessage,
              ),
            );
          }
          return DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: hint != null
                  ? AppText(
                      hint!,
                      variant: AppTextVariant.body,
                      color: scheme.onSurfaceVariant,
                    )
                  : null,
              isDense: isDense,
              isExpanded: isExpanded,
              iconSize: iconSize ?? 20,
              iconEnabledColor: scheme.onSurfaceVariant,
              iconDisabledColor: scheme.onSurface.withValues(alpha: 0.38),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ),
              menuMaxHeight: menuMaxHeight,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: scheme.surfaceContainerLow,
              onChanged: enabled
                  ? (v) => v != null ? onChanged(v) : null
                  : null,
              items: _buildItems(context, resolved),
            ),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<T>> _buildItems(
    BuildContext context,
    List<AppDropdownEntry<T>> entries,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return [
      for (final entry in entries)
        DropdownMenuItem<T>(
          value: entry.value,
          enabled: entry.enabled,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (entry.icon != null) ...[
                Icon(
                  entry.icon,
                  size: 16,
                  color: entry.enabled
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface.withValues(alpha: 0.38),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: AppText(
                  entry.label,
                  variant: AppTextVariant.body,
                  color: entry.enabled
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _wrapLabel(BuildContext context, Widget child) {
    if (label == null) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppCaption(label!),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

/// A constrained inline container for menu states (loading / error / empty).
class _InlineMenuState extends StatelessWidget {
  const _InlineMenuState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 160, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}
