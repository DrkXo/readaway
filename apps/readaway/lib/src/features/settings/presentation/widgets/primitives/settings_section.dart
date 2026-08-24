import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum SettingsScope { global, perBook }

/// Adwaita-style preferences group: optional uppercase [title] above a
/// boxed card whose [rows] are separated by hairline dividers.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.title,
    this.scope,
    this.onReset,
    required this.rows,
  });

  final String? title;
  final SettingsScope? scope;

  /// When set, a reset icon is shown in the title row that restores this
  /// section's settings to their defaults.
  final VoidCallback? onReset;

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        );
      }
      children.add(rows[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title!.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (scope != null) ...[
                        const SizedBox(width: 8),
                        _ScopeChip(scope: scope!),
                      ],
                    ],
                  ),
                ),
                if (onReset != null) _ResetButton(onPressed: onReset!),
              ],
            ),
          ),
        Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(LucideIcons.rotateCcw, size: 16),
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      tooltip: 'Reset this section',
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.scope});

  final SettingsScope scope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (scope) {
      SettingsScope.global => 'All books',
      SettingsScope.perBook => 'This book',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
