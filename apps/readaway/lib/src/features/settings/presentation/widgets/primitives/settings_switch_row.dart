import 'package:flutter/material.dart';

import '../../../../../core/widgets/core_widgets.dart';

/// Row whose trailing control is a [Switch]; tapping anywhere on the row
/// toggles it.
///
/// When [enabled] is false the row is dimmed and the switch cannot change.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.label,
    this.description,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnChanged = enabled ? onChanged : null;

    return SettingsRow(
      label: label,
      description: description,
      enabled: enabled,
      onTap: effectiveOnChanged == null
          ? null
          : () => effectiveOnChanged(!value),
      trailing: Transform.scale(
        scale: 0.8,
        alignment: Alignment.centerRight,
        child: Switch(
          value: value,
          onChanged: effectiveOnChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
