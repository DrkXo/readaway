import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../bloc/tts_player_bloc.dart';

/// Playback-rate slider (0.5×–2×). Applies to the next sentence.
class TtsRateSlider extends StatelessWidget {
  const TtsRateSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TtsPlayerBloc>.value(
      value: GetIt.I.get<TtsPlayerBloc>(),
      child: BlocBuilder<TtsPlayerBloc, TtsPlayerState>(
        buildWhen: (prev, curr) => prev.rate != curr.rate,
        builder: (context, state) {
          final scheme = Theme.of(context).colorScheme;
          return Row(
            children: [
              Icon(
                LucideIcons.gauge,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: state.rate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${state.rate.toStringAsFixed(2)}×',
                  onChanged: (v) => context.read<TtsPlayerBloc>().add(
                    TtsPlayerEvent.setRate(v),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${state.rate.toStringAsFixed(2)}×',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
