import 'package:flutter/material.dart';

import 'settings_row.dart';

/// Row whose trailing control is a [Switch]; tapping anywhere on the row
/// toggles it.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.label,
    this.description,
    required this.value,
    this.onChanged,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      label: label,
      description: description,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
