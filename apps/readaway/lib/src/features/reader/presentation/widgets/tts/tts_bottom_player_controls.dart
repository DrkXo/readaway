import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:readaway_core/readaway_core.dart' show TtsChunk;
import 'package:rxdart/rxdart.dart';

import '../../../../../core/services/audio/audio_player_service.dart';
import '../../../../../core/services/tts/tts_models.dart';
import '../../../../../core/theme/theme.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../settings/presentation/bloc/settings/settings_bloc.dart';
import '../../../domain/repositories/reader_tts_repository.dart';
import '../../bloc/reader_bloc.dart';
import 'live_speech_waveform.dart';
import 'tts_pitch_control_panel.dart';
import 'tts_prosody_control_panel.dart';
import 'tts_sleep_timer_control.dart';
import 'tts_speed_control_panel.dart';
import 'tts_voice_selection_panel.dart';
import 'waveform_scrubber.dart';

/// Bottom-anchored controls view with scrubber, speed button, and playback transport controls.
class TtsBottomPlayerControls extends StatefulWidget {
  const TtsBottomPlayerControls({
    required this.tts,
    this.onDragUpdate,
    this.onDragEnd,
    super.key,
  });

  final ReaderTtsRepository tts;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  @override
  State<TtsBottomPlayerControls> createState() =>
      _TtsBottomPlayerControlsState();
}

class _TtsBottomPlayerControlsState extends State<TtsBottomPlayerControls> {
  bool _showSpeedPanel = false;
  bool _showVoicePanel = false;
  bool _showPitchPanel = false;
  bool _showSleepTimerPanel = false;
  bool _showProsodyPanel = false;
  late final Stream<(PositionData, List<double>)> _waveformStream;

  @override
  void initState() {
    super.initState();
    widget.tts.loadAvailableVoices();
    // Hoist combined stream creation out of build() to prevent recreation and memory thrashing
    _waveformStream =
        Rx.combineLatest2<
          PositionData,
          List<double>,
          (PositionData, List<double>)
        >(
          widget.tts.positionDataStream,
          widget.tts.currentWaveform,
          (posData, waveform) => (posData, waveform),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tts = widget.tts;

    final appColors = context.appColors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: widget.onDragUpdate,
      onVerticalDragEnd: widget.onDragEnd,
      child: Container(
        decoration: BoxDecoration(
          color: appColors.sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: appColors.borderSubtle,
              width: 1.0,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Expandable Top-Shelf Settings Panel (Voice list, Speed slider, Pitch slider, Prosody, or Sleep Timer)
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: _showVoicePanel
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StreamBuilder<List<TtsVoiceOption>>(
                        stream: tts.availableVoicesStream,
                        initialData: tts.availableVoices,
                        builder: (context, voicesSnap) {
                          final voices = voicesSnap.data ?? tts.availableVoices;
                          return StreamBuilder<TtsVoiceOption?>(
                            stream: tts.currentVoiceOption,
                            initialData: tts.currentVoice,
                            builder: (context, voiceSnap) {
                              final currentVoice =
                                  voiceSnap.data ?? tts.currentVoice;
                              return TtsVoiceSelectionPanel(
                                currentVoice: currentVoice,
                                availableVoices: voices,
                                onVoiceSelected: (voice) {
                                  tts.setVoice(voice);
                                },
                                onClose: () {
                                  setState(() => _showVoicePanel = false);
                                },
                              );
                            },
                          );
                        },
                      ),
                    )
                  : _showSpeedPanel
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StreamBuilder<double>(
                        stream: tts.rateStream,
                        initialData: tts.rate,
                        builder: (context, rateSnap) {
                          final rate = rateSnap.data ?? 1.0;
                          return TtsSpeedControlPanel(
                            rate: rate,
                            onRateChanged: (newRate) =>
                                tts.setRate(newRate),
                            onClose: () {
                              setState(() => _showSpeedPanel = false);
                            },
                          );
                        },
                      ),
                    )
                  : _showPitchPanel
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StreamBuilder<double>(
                        stream: tts.pitchStream,
                        initialData: tts.pitch,
                        builder: (context, pitchSnap) {
                          final pitch = pitchSnap.data ?? 1.0;
                          return TtsPitchControlPanel(
                            pitch: pitch,
                            onPitchChanged: (newPitch) =>
                                tts.setPitch(newPitch),
                            onClose: () {
                              setState(() => _showPitchPanel = false);
                            },
                          );
                        },
                      ),
                    )
                  : _showProsodyPanel
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BlocBuilder<SettingsBloc, SettingsState>(
                        builder: (context, settingsState) {
                          final gvs =
                              settingsState.appSettings.globalViewSettings;
                          return TtsProsodyControlPanel(
                            narrationStyle: gvs.ttsNarrationStyle,
                            sentenceGapMs: gvs.ttsSentenceGap,
                            paragraphGapMs: gvs.ttsParagraphGap,
                            silenceScale: gvs.ttsSilenceScale,
                            onNarrationStyleChanged: (style) {
                              final updated =
                                  settingsState.appSettings.copyWith(
                                globalViewSettings: gvs.copyWith(
                                  ttsNarrationStyle: style,
                                ),
                              );
                              context.read<SettingsBloc>().add(
                                    SettingsEvent.updateAppSettings(updated),
                                  );
                            },
                            onSentenceGapChanged: (gap) {
                              final updated =
                                  settingsState.appSettings.copyWith(
                                globalViewSettings: gvs.copyWith(
                                  ttsSentenceGap: gap,
                                ),
                              );
                              context.read<SettingsBloc>().add(
                                    SettingsEvent.updateAppSettings(updated),
                                  );
                            },
                            onParagraphGapChanged: (gap) {
                              final updated =
                                  settingsState.appSettings.copyWith(
                                globalViewSettings: gvs.copyWith(
                                  ttsParagraphGap: gap,
                                ),
                              );
                              context.read<SettingsBloc>().add(
                                    SettingsEvent.updateAppSettings(updated),
                                  );
                            },
                            onSilenceScaleChanged: (scale) {
                              final updated =
                                  settingsState.appSettings.copyWith(
                                globalViewSettings: gvs.copyWith(
                                  ttsSilenceScale: scale,
                                ),
                              );
                              context.read<SettingsBloc>().add(
                                    SettingsEvent.updateAppSettings(updated),
                                  );
                            },
                            onReset: () {
                              final updated =
                                  settingsState.appSettings.copyWith(
                                globalViewSettings: gvs.copyWith(
                                  ttsNarrationStyle: 'balanced',
                                  ttsSentenceGap: 500,
                                  ttsParagraphGap: 1000,
                                  ttsSilenceScale: 0.2,
                                ),
                              );
                              context.read<SettingsBloc>().add(
                                    SettingsEvent.updateAppSettings(updated),
                                  );
                            },
                            onClose: () {
                              setState(() => _showProsodyPanel = false);
                            },
                          );
                        },
                      ),
                    )
                  : _showSleepTimerPanel
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: BlocBuilder<ReaderBloc, ReaderState>(
                        buildWhen: (prev, curr) =>
                            prev.ttsSleepTimerRemaining !=
                                curr.ttsSleepTimerRemaining ||
                            prev.ttsActive != curr.ttsActive,
                        builder: (context, readerState) {
                          return TtsSleepTimerControl(
                            initialSelection:
                                readerState.ttsSleepTimerRemaining,
                            onClose: () {
                              setState(() => _showSleepTimerPanel = false);
                            },
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // 2. Full-Width Uniform Speech Settings Toolbar (Voice, Speed, Pitch, Prosody, Timer)
            Row(
              children: [
                // 2a. Voice Selection Pill
                Expanded(
                  child: StreamBuilder<TtsVoiceOption?>(
                    stream: tts.currentVoiceOption,
                    initialData: tts.currentVoice,
                    builder: (context, voiceSnap) {
                      final voice = voiceSnap.data ?? tts.currentVoice;
                      final label = voice?.label ?? 'Voice';

                      return _buildSettingPill(
                        scheme: scheme,
                        icon: LucideIcons.mic,
                        label: label,
                        isActive: _showVoicePanel,
                        tooltip: 'Voice: $label',
                        onTap: () {
                          setState(() {
                            _showVoicePanel = !_showVoicePanel;
                            if (_showVoicePanel) {
                              _showSpeedPanel = false;
                              _showPitchPanel = false;
                              _showProsodyPanel = false;
                              _showSleepTimerPanel = false;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 5),

                // 2b. Playback Speed Pill
                Expanded(
                  child: StreamBuilder<double>(
                    stream: tts.rateStream,
                    initialData: tts.rate,
                    builder: (context, rateSnap) {
                      final rate = rateSnap.data ?? 1.0;
                      final label = TtsSpeedControlPanel.formatRate(rate);

                      return _buildSettingPill(
                        scheme: scheme,
                        icon: LucideIcons.gauge,
                        label: label,
                        isActive: _showSpeedPanel,
                        tooltip: 'Speed: $label (Long press to reset)',
                        onTap: () {
                          setState(() {
                            _showSpeedPanel = !_showSpeedPanel;
                            if (_showSpeedPanel) {
                              _showVoicePanel = false;
                              _showPitchPanel = false;
                              _showProsodyPanel = false;
                              _showSleepTimerPanel = false;
                            }
                          });
                        },
                        onLongPress: () => tts.setRate(1.0),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 5),

                // 2c. Voice Pitch Pill
                Expanded(
                  child: StreamBuilder<double>(
                    stream: tts.pitchStream,
                    initialData: tts.pitch,
                    builder: (context, pitchSnap) {
                      final pitch = pitchSnap.data ?? tts.pitch;
                      final label = TtsPitchControlPanel.formatPitch(pitch);

                      return _buildSettingPill(
                        scheme: scheme,
                        icon: LucideIcons.audioWaveform,
                        label: label,
                        isActive: _showPitchPanel,
                        tooltip: 'Pitch: $label (Long press to reset)',
                        onTap: () {
                          setState(() {
                            _showPitchPanel = !_showPitchPanel;
                            if (_showPitchPanel) {
                              _showVoicePanel = false;
                              _showSpeedPanel = false;
                              _showProsodyPanel = false;
                              _showSleepTimerPanel = false;
                            }
                          });
                        },
                        onLongPress: () => tts.setPitch(1.0),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 5),

                // 2d. Prosody & Timing Pill
                Expanded(
                  child: BlocBuilder<SettingsBloc, SettingsState>(
                    buildWhen: (prev, curr) =>
                        prev.appSettings.globalViewSettings !=
                        curr.appSettings.globalViewSettings,
                    builder: (context, state) {
                      final style = state.appSettings.globalViewSettings
                          .ttsNarrationStyle;
                      final label = switch (style) {
                        'audiobook' => 'Audiobook',
                        'expressive' => 'Expressive',
                        _ => 'Balanced',
                      };

                      return _buildSettingPill(
                        scheme: scheme,
                        icon: LucideIcons.slidersHorizontal,
                        label: label,
                        isActive: _showProsodyPanel,
                        tooltip: 'Prosody: $label (Pauses & Style)',
                        onTap: () {
                          setState(() {
                            _showProsodyPanel = !_showProsodyPanel;
                            if (_showProsodyPanel) {
                              _showVoicePanel = false;
                              _showSpeedPanel = false;
                              _showPitchPanel = false;
                              _showSleepTimerPanel = false;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 5),

                // 2e. Sleep Timer Pill
                Expanded(
                  child: BlocBuilder<ReaderBloc, ReaderState>(
                    buildWhen: (prev, curr) =>
                        prev.ttsSleepTimerRemaining !=
                        curr.ttsSleepTimerRemaining,
                    builder: (context, state) {
                      final remaining = state.ttsSleepTimerRemaining;
                      final label = remaining == null
                          ? 'Timer'
                          : formatSleepDuration(remaining);
                      return _buildSettingPill(
                        scheme: scheme,
                        icon: remaining == null
                            ? LucideIcons.moon
                            : LucideIcons.moonStar,
                        label: label,
                        isActive: _showSleepTimerPanel,
                        tooltip: remaining == null
                            ? 'Sleep Timer'
                            : 'Sleep Timer: stops in $label',
                        onTap: () {
                          setState(() {
                            _showSleepTimerPanel = !_showSleepTimerPanel;
                            if (_showSleepTimerPanel) {
                              _showVoicePanel = false;
                              _showSpeedPanel = false;
                              _showPitchPanel = false;
                              _showProsodyPanel = false;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 3. Current Active Sentence Info Header (Clean, wide, prominent text)
            StreamBuilder<TtsChunk>(
              stream: tts.currentChunk,
              builder: (context, snapshot) {
                final text = snapshot.data?.text ?? 'Preparing…';
                final index = (tts.currentChunkIndex ?? 0) + 1;
                final total = tts.queueLength;

                return Row(
                  children: [
                    StreamBuilder<TtsPlaybackEvent>(
                      stream: tts.playbackState,
                      builder: (context, eventSnap) {
                        final isPlaying =
                            eventSnap.data?.state == TtsPlaybackState.playing;
                        final artUri = tts.baseTag?.artUri;
                        if (artUri != null && artUri.scheme == 'file') {
                          final coverFile = File(artUri.toFilePath());
                          return Stack(
                            alignment: Alignment.bottomRight,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 42,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: appColors.borderSubtle,
                                    width: 0.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    coverFile,
                                    width: 42,
                                    height: 54,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: LiveSpeechWaveform(
                                        isPlaying: isPlaying,
                                        color: scheme.primary,
                                        barCount: 4,
                                        height: 18,
                                        width: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isPlaying)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.surface.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: scheme.outlineVariant.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: LiveSpeechWaveform(
                                      isPlaying: true,
                                      color: scheme.primary,
                                      barCount: 3,
                                      height: 10,
                                      width: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }
                        return Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(
                              alpha: 0.6,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: LiveSpeechWaveform(
                              isPlaying: isPlaying,
                              color: scheme.primary,
                              barCount: 4,
                              height: 18,
                              width: 22,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text,
                            variant: AppTextVariant.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 3),
                          Builder(
                            builder: (context) {
                              final pIdx = snapshot.data?.paragraphIndex;
                              final pText = pIdx != null
                                  ? ' • ¶ ${pIdx + 1}'
                                  : '';
                              return AppCaption(
                                'Sentence $index of $total$pText',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // 4. Error Display Banner (if error occurred)
            StreamBuilder<TtsPlaybackEvent>(
              stream: tts.playbackState,
              builder: (context, snapshot) {
                final event = snapshot.data;
                if (event?.state == TtsPlaybackState.error &&
                    event?.message != null) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.circleAlert,
                          size: 16,
                          color: scheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event!.message!,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onErrorContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 6),

            // 5. Intra-Sentence Interactive Waveform Progress Scrubber
            StreamBuilder<(PositionData, List<double>)>(
              stream: _waveformStream,
              builder: (context, snapshot) {
                final posData = snapshot.data?.$1;
                final waveform = snapshot.data?.$2 ?? const [];
                final pos = posData?.position ?? Duration.zero;
                final dur = posData?.duration ?? Duration.zero;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: WaveformScrubber(
                    position: pos,
                    duration: dur,
                    waveform: waveform,
                    onSeek: (target) => tts.seek(target),
                  ),
                );
              },
            ),

            const SizedBox(height: 4),

            // 6. Transport Controls Row (Stop, Prev, Play/Pause, Next, Replay)
            StreamBuilder<TtsPlaybackEvent>(
              stream: tts.playbackState,
              builder: (context, snapshot) {
                final state = snapshot.data?.state;
                final isPlaying = state == TtsPlaybackState.playing;
                final isLoading = state == TtsPlaybackState.loading;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Stop Session Button
                    AppIconButton(
                      icon: LucideIcons.square,
                      tooltip: 'Stop reading',
                      onPressed: () => tts.stop(),
                      size: AppIconButtonSize.medium,
                    ),

                    // Skip Previous Sentence
                    AppIconButton(
                      icon: LucideIcons.skipBack,
                      tooltip: 'Previous sentence',
                      onPressed: () => tts.skipToPreviousSentence(),
                      size: AppIconButtonSize.large,
                    ),

                    // Hero Play / Pause Button
                    IconButton.filled(
                      iconSize: 30,
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        elevation: 1,
                      ),
                      icon: isLoading
                          ? SpinKitPulsingGrid(
                              color: scheme.onPrimary,
                              size: 24,
                            )
                          : Icon(
                              isPlaying ? LucideIcons.pause : LucideIcons.play,
                            ),
                      tooltip: isLoading
                          ? 'Loading speech…'
                          : isPlaying
                          ? 'Pause'
                          : 'Play',
                      onPressed: isLoading
                          ? null
                          : () {
                              if (isPlaying) {
                                tts.pause();
                              } else {
                                tts.resume();
                              }
                            },
                    ),

                    // Skip Next Sentence
                    AppIconButton(
                      icon: LucideIcons.skipForward,
                      tooltip: 'Next sentence',
                      onPressed: () => tts.skipToNextSentence(),
                      size: AppIconButtonSize.large,
                    ),

                    // Replay Current Sentence Button
                    AppIconButton(
                      icon: LucideIcons.rotateCcw,
                      tooltip: 'Replay sentence',
                      onPressed: () => tts.seek(Duration.zero),
                      size: AppIconButtonSize.medium,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingPill({
    required ColorScheme scheme,
    required IconData icon,
    required String label,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 7,
            ),
            constraints: const BoxConstraints(minHeight: 36),
            decoration: BoxDecoration(
              color: isActive
                  ? scheme.primary
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isActive ? scheme.onPrimary : scheme.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive ? scheme.onPrimary : scheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  isActive ? LucideIcons.chevronDown : LucideIcons.chevronUp,
                  size: 11,
                  color: isActive
                      ? scheme.onPrimary.withValues(alpha: 0.8)
                      : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
