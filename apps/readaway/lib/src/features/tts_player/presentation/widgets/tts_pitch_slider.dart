import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../bloc/tts_player_bloc.dart';

/// Pitch slider (0.5×–2×). UI-only for now — sherpa-onnx offline TTS has no
/// runtime pitch knob, so the value is stored but not applied to audio.
class TtsPitchSlider extends StatelessWidget {
  const TtsPitchSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TtsPlayerBloc>.value(
      value: GetIt.I.get<TtsPlayerBloc>(),
      child: BlocBuilder<TtsPlayerBloc, TtsPlayerState>(
        buildWhen: (prev, curr) => prev.pitch != curr.pitch,
        builder: (context, state) {
          final scheme = Theme.of(context).colorScheme;
          return Row(
            children: [
              Icon(
                LucideIcons.audioLines,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: state.pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: '${state.pitch.toStringAsFixed(2)}×',
                  onChanged: (v) => context.read<TtsPlayerBloc>().add(
                    TtsPlayerEvent.setPitch(v),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${state.pitch.toStringAsFixed(2)}×',
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
