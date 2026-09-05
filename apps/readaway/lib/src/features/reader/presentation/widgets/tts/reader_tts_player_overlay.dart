import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motor/motor.dart';

import '../../bloc/reader_bloc.dart';
import '../navigation/reader_bottom_bar.dart';
import 'reader_tts_full_player_view.dart';
import 'reader_tts_mini_player_bar.dart';

class ReaderTtsPlayerOverlay extends StatefulWidget {
  const ReaderTtsPlayerOverlay({super.key});

  @override
  State<ReaderTtsPlayerOverlay> createState() => _ReaderTtsPlayerOverlayState();
}

class _ReaderTtsPlayerOverlayState extends State<ReaderTtsPlayerOverlay>
    with SingleTickerProviderStateMixin {
  static const _presenceDuration = Duration(milliseconds: 320);

  late final AnimationController _presence;

  bool _sheetMounted = false;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _presence = AnimationController(
      vsync: this,
      duration: _presenceDuration,
    );
    final active = context.read<ReaderBloc>().state.ttsActive;
    _active = active;
    _sheetMounted = active;
    if (active) _presence.value = 1;
  }

  @override
  void dispose() {
    _presence.dispose();
    super.dispose();
  }

  void _syncWithActive(bool active) {
    setState(() {
      _active = active;
      if (active) _sheetMounted = true;
    });

    if (active) {
      _presence.forward();
    } else {
      _presence.reverse().whenCompleteOrCancel(() {
        if (mounted && _presence.isDismissed) {
          setState(() => _sheetMounted = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReaderBloc, ReaderState>(
      listenWhen: (prev, curr) => prev.ttsActive != curr.ttsActive,
      listener: (context, state) => _syncWithActive(state.ttsActive),
      child: !_sheetMounted
          ? const SizedBox.shrink()
          : Positioned.fill(
              child: IgnorePointer(
                ignoring: !_active,
                child: _ReaderTtsExpandableSheet(
                  key: const ValueKey('tts_sheet'),
                  presence: _presence,
                ),
              ),
            ),
    );
  }
}

/// Owns the expand/collapse [AnimationController] (0 = mini, 1 = full) and
/// renders both states, cross-fading as the user drags between them.
///
/// Re-created each time TTS (re)activates (see the [ValueKey] above), so it
/// always starts collapsed rather than remembering the last expand state.
class _ReaderTtsExpandableSheet extends StatefulWidget {
  const _ReaderTtsExpandableSheet({
    required this.presence,
    super.key,
  });

  final Animation<double> presence;

  @override
  State<_ReaderTtsExpandableSheet> createState() =>
      _ReaderTtsExpandableSheetState();
}

class _ReaderTtsExpandableSheetState extends State<_ReaderTtsExpandableSheet>
    with SingleTickerProviderStateMixin {
  static const _miniMargin = 8.0;
  static const _flingVelocityThreshold = 700.0;
  static const _fadeOutEnd = 0.45;
  static const _fadeInStart = 0.3;

  late final SingleMotionController _motion;

  @override
  void initState() {
    super.initState();
    _motion = SingleMotionController(
      motion: MaterialSpringMotion.expressiveSpatialDefault(),
      vsync: this,
      initialValue: 0.0,
    );
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  double _calculateDragExtent(double overlayHeight) {
    final extent =
        overlayHeight - ReaderBottomBar.height - ReaderTtsMiniPlayerBar.height;
    return extent > 0 ? extent : 1.0; // Prevent division by zero
  }

  void _handleDragUpdate(DragUpdateDetails details, double dragExtent) {
    final delta = details.delta.dy / dragExtent;
    _motion.value = (_motion.value - delta).clamp(0.0, 1.0);
  }

  void _handleDragEnd(DragEndDetails details, double dragExtent) {
    final velocity = details.primaryVelocity ?? 0;
    final relativeVelocity = -velocity / dragExtent;

    double target = _motion.value > 0.5 ? 1.0 : 0.0;
    if (velocity.abs() > _flingVelocityThreshold) {
      target = velocity < 0 ? 1.0 : 0.0;
    }

    _motion.animateTo(
      target,
      withVelocity: relativeVelocity,
    );
  }

  void _handleSkipDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final tts = context.read<ReaderBloc>().ttsRepository;
    if (velocity < -200) {
      tts.skipToNextSentence().run();
    } else if (velocity > 200) {
      tts.skipToPreviousSentence().run();
    }
  }

  void _expand() => _motion.animateTo(1.0);
  void _collapse() => _motion.animateTo(0.0);
  void _close() => context.read<ReaderBloc>().add(const ReaderEvent.ttsClose());

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final overlayHeight = constraints.maxHeight;
        const controlBarHeight = ReaderBottomBar.height;
        final dragExtent = _calculateDragExtent(overlayHeight);

        return AnimatedBuilder(
          animation: Listenable.merge([_motion, widget.presence]),
          builder: (context, child) {
            // Clamp t to handle physics overshoots gracefully in geometry lerps
            final t = _motion.value.clamp(0.0, 1.0);

            // Curved presence interpolation:
            // Entering: easeOutCubic (rises smoothly from bottom and settles)
            // Dismissing: easeInCubic (accelerates downwards off the bottom of the screen)
            final curvedPresence = CurvedAnimation(
              parent: widget.presence,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ).value;

            // Distance to slide down off-screen:
            // In mini player mode (t=0): 160px places the card completely offscreen below the bottom bar.
            // In full player mode (t=1): overlayHeight places the entire sheet off the screen.
            final slideDistance = lerpDouble(160.0, overlayHeight, t)!;
            final dy = (1.0 - curvedPresence) * slideDistance;
            final presenceOpacity = curvedPresence.clamp(0.0, 1.0);

            final top = lerpDouble(
              overlayHeight -
                  controlBarHeight -
                  ReaderTtsMiniPlayerBar.height -
                  _miniMargin,
              0,
              t,
            )!;
            final bottom = lerpDouble(controlBarHeight + _miniMargin, 0, t)!;
            final horizontalMargin = lerpDouble(_miniMargin, 0, t)!;
            final radius = lerpDouble(20, 0, t)!;
            final elevation = lerpDouble(6, 0, t)!;

            final miniOpacity = (1 - t / _fadeOutEnd).clamp(0.0, 1.0);
            final fullOpacity = ((t - _fadeInStart) / (1 - _fadeInStart)).clamp(
              0.0,
              1.0,
            );

            return Stack(
              children: [
                Positioned(
                  top: top,
                  bottom: bottom,
                  left: horizontalMargin,
                  right: horizontalMargin,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: presenceOpacity,
                      child: Material(
                        elevation: elevation,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(radius),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Mini Player View
                            IgnorePointer(
                              ignoring: t > _fadeOutEnd,
                              child: Opacity(
                                opacity: miniOpacity,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _expand,
                                  onVerticalDragUpdate: (d) =>
                                      _handleDragUpdate(d, dragExtent),
                                  onVerticalDragEnd: (d) =>
                                      _handleDragEnd(d, dragExtent),
                                  onHorizontalDragEnd: _handleSkipDrag,
                                  child: ReaderTtsMiniPlayerBar(
                                    onClosePlayer: _close,
                                  ),
                                ),
                              ),
                            ),
                            // Full Player View
                            IgnorePointer(
                              ignoring: t < _fadeInStart,
                              child: Opacity(
                                opacity: fullOpacity,
                                child: OverflowBox(
                                  alignment: Alignment.topCenter,
                                  minHeight: 0,
                                  maxHeight: double.infinity,
                                  child: SizedBox(
                                    height: overlayHeight,
                                    child: ReaderTtsFullPlayerView(
                                      onClose: _collapse,
                                      onClosePlayer: _close,
                                      onDragUpdate: (d) =>
                                          _handleDragUpdate(d, dragExtent),
                                      onDragEnd: (d) =>
                                          _handleDragEnd(d, dragExtent),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
