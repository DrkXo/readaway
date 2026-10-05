import 'package:flutter/material.dart';

import '../../../../core/theme/tts_highlight_palette.dart';

/// Preset swatches for the TTS speech-highlight color plus a "Custom" entry.
///
/// [selectedValue] is the persisted `GlobalViewSettings.ttsHighlightColor`
/// value: either a preset key (see [kTtsHighlightColorOptions]) or a hex
/// string. Selecting a swatch reports the new persisted value through
/// [onSelected]; the custom dialog normalises entered colors to `#RRGGBB`.
class TtsHighlightColorPicker extends StatelessWidget {
  const TtsHighlightColorPicker({
    super.key,
    required this.selectedValue,
    required this.onSelected,
  });

  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColor = parseHexColor(selectedValue);
    final customSelected = isCustomTtsHighlightColor(selectedValue);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final option in kTtsHighlightColorOptions)
          _SwatchChip(
            label: option.label,
            color: option.color ?? theme.colorScheme.primary,
            selected: selectedValue == option.key,
            onTap: () => onSelected(option.key),
          ),
        _SwatchChip(
          label: 'Custom',
          color: customSelected ? customColor : null,
          icon: Icons.colorize,
          selected: customSelected,
          onTap: () async {
            final picked = await showDialog<String>(
              context: context,
              builder: (_) => _CustomHighlightColorDialog(initial: customColor),
            );
            if (picked != null) onSelected(picked);
          },
        ),
      ],
    );
  }
}

/// A rounded, selectable chip with a color dot (or icon) and a label.
class _SwatchChip extends StatelessWidget {
  const _SwatchChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && color == null)
              Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant)
            else
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? accent : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hex entry plus quick swatches for a custom highlight color.
///
/// Pops a normalised `#RRGGBB` string via [Navigator.pop], or null on cancel.
class _CustomHighlightColorDialog extends StatefulWidget {
  const _CustomHighlightColorDialog({this.initial});

  final Color? initial;

  @override
  State<_CustomHighlightColorDialog> createState() =>
      _CustomHighlightColorDialogState();
}

class _CustomHighlightColorDialogState
    extends State<_CustomHighlightColorDialog> {
  static const _quickSwatches = <Color>[
    Color(0xFFFFEB3B),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF9E9E9E),
  ];

  late final TextEditingController _controller;
  Color? _color;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial ?? const Color(0xFFF59E0B);
    _color = initial;
    _controller = TextEditingController(text: colorToHex(initial));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(Color color) {
    setState(() {
      _color = color;
      _controller.text = colorToHex(color);
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = _color != null;

    return AlertDialog(
      title: const Text('Custom highlight color'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _color ?? theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (value) =>
                        setState(() => _color = parseHexColor(value)),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Hex color',
                      hintText: '#RRGGBB',
                      isDense: true,
                      errorText: !valid ? 'Enter #RRGGBB' : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final swatch in _quickSwatches)
                  _SwatchDot(
                    color: swatch,
                    selected: _color == swatch,
                    onTap: () => _select(swatch),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: valid
              ? () => Navigator.of(context).pop(colorToHex(_color!))
              : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// A small tappable color circle used inside the custom color dialog.
class _SwatchDot extends StatelessWidget {
  const _SwatchDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}
