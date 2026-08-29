import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../bloc/tts_player_bloc.dart';

/// Sleep-timer presets. When the timer runs out, playback stops and the
/// session stays paused (mini-player remains visible).
class TtsSleepTimer extends StatelessWidget {
  const TtsSleepTimer({super.key});

  static const List<int> _presets = [5, 10, 15, 30, 45, 60];

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TtsPlayerBloc>.value(
      value: GetIt.I.get<TtsPlayerBloc>(),
      child: BlocBuilder<TtsPlayerBloc, TtsPlayerState>(
        buildWhen: (prev, curr) =>
            prev.sleepTimerRemaining != curr.sleepTimerRemaining,
        builder: (context, state) {
          final scheme = Theme.of(context).colorScheme;
          final remaining = state.sleepTimerRemaining;
          return Row(
            children: [
              Icon(
                LucideIcons.timer,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in _presets)
                      ChoiceChip(
                        label: Text('$minutes min'),
                        selected: _isSelected(remaining, minutes),
                        onSelected: (_) => context.read<TtsPlayerBloc>().add(
                          TtsPlayerEvent.setSleepTimer(
                            Duration(minutes: minutes),
                          ),
                        ),
                      ),
                    if (remaining != null)
                      ActionChip(
                        avatar: const Icon(LucideIcons.x, size: 16),
                        label: Text(_format(remaining)),
                        onPressed: () => context.read<TtsPlayerBloc>().add(
                          const TtsPlayerEvent.cancelSleepTimer(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Highlights the preset bucket the remaining time currently falls in.
   bool _isSelected(Duration? remaining, int minutes) {
    if (remaining == null) return false;
    final idx = _presets.indexOf(minutes);
    final next = idx + 1 < _presets.length ? _presets[idx + 1] : null;
    return remaining.inMinutes >= minutes &&
        (next == null || remaining.inMinutes < next);
  }
}
