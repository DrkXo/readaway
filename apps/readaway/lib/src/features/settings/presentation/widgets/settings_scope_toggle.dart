import 'package:flutter/material.dart';

/// Segmented control for choosing whether reader settings apply to all books
/// (global) or only the currently open book (per-book).
class SettingsScopeToggle extends StatelessWidget {
  const SettingsScopeToggle({
    super.key,
    required this.isGlobalMode,
    required this.onChanged,
  });

  final bool isGlobalMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('All books')),
        ButtonSegment(value: false, label: Text('This book')),
      ],
      selected: {isGlobalMode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
