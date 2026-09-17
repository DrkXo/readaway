import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../bloc/reader_bloc.dart';

/// Sleep-timer slider range limits (minutes).
const int kSleepTimerMinMinutes = 5;
const int kSleepTimerMaxMinutes = 360; // 6h
const int kSleepTimerStepMinutes = 5;

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
/// Uses a 5-minute-step slider (5 min – 6 h) plus an "Off" toggle, and shows a
/// live countdown while an active timer is running. The authoritative state
/// lives on [ReaderBloc] (`ttsSleepTimerRemaining`); this widget only renders
/// it and dispatches [ReaderEvent.setSleepTimer] /
/// [ReaderEvent.ttsSleepTimerFired].
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
        kSleepTimerMaxMinutes; // default to max while off
  }

  @override
  void didUpdateWidget(TtsSleepTimerControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync the slider value only on a fresh arm (off -> active). While the
    // countdown runs, `initialSelection` shrinks every second; we must keep
    // showing the originally chosen duration so the slider doesn't drift.
    if (oldWidget.initialSelection == null && widget.initialSelection != null) {
      _minutes = widget.initialSelection!.inMinutes;
    }
  }

  void _arm(int minutes) {
    context.read<ReaderBloc>().add(
      ReaderEvent.setSleepTimer(Duration(minutes: minutes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          // Header: title + live countdown readout when active + close.
          Row(
            children: [
              Icon(LucideIcons.moon, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Sleep Timer',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                    child: Text(
                      'Stops in ${formatSleepDuration(remaining)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  );
                },
              ),
              if (widget.onClose != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Close sleep timer',
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: widget.onClose,
                  icon: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Slider (5–360 min, 5-min steps). Releasing the thumb arms the
          // countdown at the chosen duration (even if it was off).
          Row(
            children: [
              Icon(LucideIcons.timer, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
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
                    setState(() => _minutes = value.round());
                    _arm(_minutes);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatSleepDuration(Duration(minutes: kSleepTimerMinMinutes)),
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                formatSleepDuration(Duration(minutes: kSleepTimerMaxMinutes)),
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Current selection + cancel (Off) action. Cancelling must NOT stop
          // playback — only the countdown reaching zero does.
          Row(
            children: [
              Expanded(
                child: Text(
                  isActive
                      ? 'Selected: ${formatSleepDuration(Duration(minutes: _minutes))}'
                      : 'Timer is off — drag the slider to set one',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isActive)
                TextButton.icon(
                  onPressed: () {
                    context.read<ReaderBloc>().add(
                      ReaderEvent.setSleepTimer(Duration.zero),
                    );
                  },
                  icon: Icon(
                    LucideIcons.power,
                    size: 16,
                    color: scheme.error,
                  ),
                  label: Text(
                    'Off',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.error,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
