import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bloc/reader_bloc.dart';

/// Sleep-timer slider range limits (minutes).
const int kSleepTimerMinMinutes = 5;
const int kSleepTimerMaxMinutes = 360; // 6h
const int kSleepTimerStepMinutes = 5;

/// Sleep-timer preset quick options (minutes).
const List<int> kSleepTimerPresetMinutes = [15, 30, 45, 60];

/// Formats [d] as compact `h m` / `m` / `mm:ss` label for pills and chips.
String formatSleepDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes >= 60) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
  if (totalMinutes >= 1) return '${totalMinutes}m';
  final s = d.inSeconds;
  return '${s}s';
}

/// A compact sleep-timer picker panel for the TTS player.
///
/// Uses quick 1-tap preset chips, a 5-minute-step slider (5 min – 6 h),
/// an "Off" toggle, and shows a live countdown while an active timer is running.
/// The authoritative state lives on [ReaderBloc] (`ttsSleepTimerRemaining`).
class TtsSleepTimerControl extends StatefulWidget {
  const TtsSleepTimerControl({
    required this.initialSelection,
    this.onClose,
    super.key,
  });

  /// The currently persisted/active timer duration (null = off).
  final Duration? initialSelection;

  /// Optional callback to collapse or close the panel.
  final VoidCallback? onClose;

  @override
  State<TtsSleepTimerControl> createState() => _TtsSleepTimerControlState();
}

class _TtsSleepTimerControlState extends State<TtsSleepTimerControl> {
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _minutes =
        widget.initialSelection?.inMinutes ??
        30; // default to 30 min if off
  }

  @override
  void didUpdateWidget(TtsSleepTimerControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelection == null && widget.initialSelection != null) {
      _minutes = widget.initialSelection!.inMinutes;
    }
  }

  void _arm(int minutes) {
    setState(() => _minutes = minutes);
    context.read<ReaderBloc>().add(
      ReaderEvent.setSleepTimer(Duration(minutes: minutes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isActive = widget.initialSelection != null;
    final sliderValue = _minutes.toDouble().clamp(
      kSleepTimerMinMinutes.toDouble(),
      kSleepTimerMaxMinutes.toDouble(),
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Icon, Title, Live countdown readout & Close button
          Row(
            children: [
              Icon(
                isActive ? LucideIcons.moonStar : LucideIcons.moon,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Sleep Timer',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              BlocBuilder<ReaderBloc, ReaderState>(
                buildWhen: (prev, curr) =>
                    prev.ttsSleepTimerRemaining != curr.ttsSleepTimerRemaining,
                builder: (context, state) {
                  final remaining = state.ttsSleepTimerRemaining;
                  if (remaining == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.timer,
                          size: 12,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stops in ${formatSleepDuration(remaining)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (isActive) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Turn off timer',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: const EdgeInsets.all(6),
                  ),
                  onPressed: () {
                    context.read<ReaderBloc>().add(
                      const ReaderEvent.setSleepTimer(Duration.zero),
                    );
                  },
                  icon: Icon(
                    LucideIcons.power,
                    size: 16,
                    color: scheme.error,
                  ),
                ),
              ],
              if (widget.onClose != null) ...[
                const SizedBox(width: 2),
                IconButton(
                  tooltip: 'Close sleep timer',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: const EdgeInsets.all(6),
                  ),
                  onPressed: widget.onClose,
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // 2. Instant 1-Tap Quick Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: kSleepTimerPresetMinutes.map((presetMin) {
                final isSelected = isActive && _minutes == presetMin;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _arm(presetMin),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        minWidth: 54,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? scheme.primary
                            : scheme.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$presetMin min',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),

          const SizedBox(height: 10),

          // 3. Custom Duration Slider (5 min – 6 hours)
          Row(
            children: [
              Icon(
                LucideIcons.timer,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Custom: ${formatSleepDuration(Duration(minutes: _minutes))}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                formatSleepDuration(Duration(minutes: kSleepTimerMaxMinutes)),
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.surfaceContainerHighest,
              thumbColor: scheme.primary,
              valueIndicatorColor: scheme.primary,
            ),
            child: Slider(
              value: sliderValue,
              min: kSleepTimerMinMinutes.toDouble(),
              max: kSleepTimerMaxMinutes.toDouble(),
              divisions:
                  ((kSleepTimerMaxMinutes - kSleepTimerMinMinutes) ~/
                  kSleepTimerStepMinutes),
              label: formatSleepDuration(Duration(minutes: _minutes)),
              onChanged: (value) {
                setState(() => _minutes = value.round());
              },
              onChangeEnd: (value) {
                _arm(value.round());
              },
            ),
          ),
        ],
      ),
    );
  }
}
