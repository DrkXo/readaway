import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/widgets/core_widgets.dart';
import '../../bloc/reader_bloc.dart';
import 'tts_bottom_player_controls.dart';
import 'tts_sentence_queue_list.dart';

/// Full Player View with scrollable auto-centering sentence queue,
/// intra-sentence position scrubber, speed controls, and bottom-anchored controls.
class ReaderTtsFullPlayerView extends StatelessWidget {
  const ReaderTtsFullPlayerView({
    required this.onClose,
    required this.onClosePlayer,
    this.onDragUpdate,
    this.onDragEnd,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onClosePlayer;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final tts = context.read<ReaderBloc>().ttsController;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          // 1. Top Drag Handle & Title Bar
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onDragUpdate,
            onVerticalDragEnd: onDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: LucideIcons.chevronDown,
                        tooltip: 'Minimize',
                        onPressed: onClose,
                        size: AppIconButtonSize.medium,
                      ),
                      const Expanded(
                        child: AppText(
                          'Sentences',
                          variant: AppTextVariant.title,
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppIconButton(
                        icon: LucideIcons.x,
                        tooltip: 'Close Player',
                        onPressed: onClosePlayer,
                        size: AppIconButtonSize.medium,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // 2. Scrollable Auto-Tracking Sentence Queue
          Expanded(
            child: TtsSentenceQueueList(tts: tts),
          ),

          // 3. Anchored Bottom Media Controls Section
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TtsBottomPlayerControls(
              tts: tts,
              onDragUpdate: onDragUpdate,
              onDragEnd: onDragEnd,
            ),
          ),
        ],
      ),
    );
  }
}
