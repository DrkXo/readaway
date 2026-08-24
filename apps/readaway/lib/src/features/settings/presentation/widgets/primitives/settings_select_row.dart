import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'settings_row.dart';

/// One selectable entry of a [SettingsSelectRow].
class SettingsSelectEntry<T> {
  const SettingsSelectEntry({required this.value, required this.label});

  final T value;
  final String label;
}

/// Row with a chromeless trailing dropdown. Uses [PopupMenuButton] so
/// nullable values (e.g. "System" font) work as selections.
class SettingsSelectRow<T> extends StatelessWidget {
  const SettingsSelectRow({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.entries,
    required this.onChanged,
  });

  final String label;
  final String? description;
  final T value;
  final List<SettingsSelectEntry<T>> entries;
  final ValueChanged<T> onChanged;

  String get _currentLabel => entries
      .firstWhere((e) => e.value == value, orElse: () => entries.first)
      .label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SettingsRow(
      label: label,
      description: description,
      trailing: PopupMenuButton<T>(
        initialValue: value,
        onSelected: onChanged,
        position: PopupMenuPosition.under,
        itemBuilder: (context) => [
          for (final entry in entries)
            PopupMenuItem<T>(
              value: entry.value,
              child: Text(
                entry.label,
                style: TextStyle(
                  fontWeight: entry.value == value
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: scheme.onSurface,
                ),
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_currentLabel, style: theme.textTheme.bodyMedium),
              Icon(
                LucideIcons.chevronDown,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
