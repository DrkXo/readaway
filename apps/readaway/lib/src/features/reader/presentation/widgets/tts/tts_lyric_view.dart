import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:readaway_core/readaway_core.dart'
    show TtsChunk, TtsTimeline, buildLrc;

import '../../../../../core/widgets/core_widgets.dart';
import '../../../../settings/domain/entity/tts_lyric_style.dart';
import '../../../domain/repositories/reader_tts_repository.dart';

/// Page-accurate lyric view for TTS playback.
///
/// Every sentence is placed on a single time axis by [TtsTimeline], whose
/// boundaries are the measured lengths of the synthesized audio rather than an
/// estimate. That makes this more than a highlighted list: the position driving
/// the active line is the same number, on the same axis, as an LRC file's —
/// so what is shown here and what a player would read from an exported `.lrc`
/// are the same timings, not two systems that happen to look alike.
///
/// The axis only covers sentences whose audio has been produced. Synthesis runs
/// ahead of playback and finishes a page within seconds of it starting, so this
/// is a growth at the top of the list that has usually completed before the
/// reader scrolls anywhere. Showing an estimate instead would mean every
/// sentence after the first unmeasured one was placed by guesswork, and a
/// guess that is wrong moves the highlight off the voice.
class TtsLyricView extends StatefulWidget {
  const TtsLyricView({
    required this.tts,
    required this.style,
    this.singleLine = false,
    super.key,
  });

  final ReaderTtsRepository tts;

  /// The reader's alignment choices, as chosen in Settings → Text to speech.
  ///
  /// Injected rather than read from a bloc so this stays a widget about
  /// drawing sentences: its existing tests build it over a fake repository with
  /// no provider in the tree, and a hidden dependency on app-wide settings
  /// would make them lie about what is being tested.
  final TtsLyricStyle style;

  /// Shows the sentence being spoken and nothing else.
  ///
  /// The page stays laid out underneath either way, so this changes the
  /// sentence that moves, not the timings: the highlight still lands on the
  /// boundary the axis measured rather than on an estimate.
  ///
  /// Touch is switched off in this mode, deliberately. Tapping would mean
  /// hitting lines that are not drawn, and dragging would scroll a view whose
  /// only line had left the screen — a gesture that looks broken however it
  /// behaves. Navigation stays with the transport controls below, which move
  /// by sentence and are the same either way.
  final bool singleLine;

  @override
  State<TtsLyricView> createState() => _TtsLyricViewState();
}

class _TtsLyricViewState extends State<TtsLyricView> {
  final LyricController _lyric = LyricController();

  StreamSubscription<TtsTimeline?>? _timelineSub;
  StreamSubscription<int>? _queueSub;
  StreamSubscription<Duration>? _positionSub;

  /// The axis the loaded lyrics were built from.
  ///
  /// Tapping a line yields that line's start time, not its index, because the
  /// LRC has one line per *spoken* sentence and the chunk queue has one entry
  /// per *chunk* — an utterance that was never synthesized leaves a gap and
  /// shifts every line after it. Resolving the time back through the axis is
  /// therefore the only mapping that cannot drift.
  TtsTimeline? _loadedTimeline;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _timelineSub = widget.tts.timelineStream.listen((_) => _reloadLyrics());
    // The queue can be replaced (a new page) without the axis changing shape
    // first, so both have to be watched to avoid pairing one page's text with
    // another's timings.
    _queueSub = widget.tts.queueVersion.listen((_) => _reloadLyrics());
    _positionSub = widget.tts.globalPositionStream.listen(
      _lyric.setPosition,
    );
  }

  void _resubscribe() {
    _timelineSub?.cancel();
    _queueSub?.cancel();
    _positionSub?.cancel();
    _subscribe();
  }

  void _reloadLyrics() {
    if (!mounted) return;
    final timeline = widget.tts.timeline;
    if (timeline == null || timeline.isEmpty) {
      _loadedTimeline = null;
      _lyric.load('');
      setState(() {});
      return;
    }

    final page = buildPageLyric(timeline: timeline, queue: widget.tts.queue);
    _loadedTimeline = timeline;
    _lyric.load(page.lrc, translation: page.translationLrc);
    setState(() {});
  }

  void _onLineTapped(Duration start) {
    final timeline = _loadedTimeline;
    if (timeline == null) return;
    widget.tts.seekToChunk(timeline.indexAt(start));
  }

  @override
  void didUpdateWidget(covariant TtsLyricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tts != widget.tts) _resubscribe();
  }

  @override
  void dispose() {
    _timelineSub?.cancel();
    _queueSub?.cancel();
    _positionSub?.cancel();
    _lyric.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeline = widget.tts.timeline;

    if (timeline == null || timeline.isEmpty) {
      return const AppLoadingView(
        label: 'Preparing sentences…',
        compact: true,
      );
    }

    return LyricView(
      // Keyed on the preferences so a change to them rebuilds this package's
      // internal layout instead of only repainting it.
      key: ValueKey(widget.style),
      controller: _lyric,
      preset: buildTtsLyricPreset(
        context,
        scheme,
        widget.style,
        singleLine: widget.singleLine,
      ),
      onLineTap: (details) => _onLineTapped(details.line.start),
    );
  }
}

/// Builds the LRC pair for one page: the sentences as displayed, and the text
/// as synthesized where the two differ.
///
/// Returned as a record rather than written straight into a controller so the
/// generated text can be checked against a real parser without pumping a
/// widget. The writer and `flutter_lyric`'s parser have to agree exactly — on
/// digit counts, on where a line may break, on what a bracketed number in the
/// middle of a sentence means — and that agreement is much easier to break
/// silently than to notice in the running app.
({String lrc, String? translationLrc}) buildPageLyric({
  required TtsTimeline timeline,
  required List<TtsChunk> queue,
}) {
  // Only the leading run of chunks is on the axis. Reading the queue to that
  // same length keeps the LRC and the axis in step; a longer list would be
  // timed against boundaries that do not exist yet.
  final texts = <String>[];
  final spokenTexts = <String>[];
  var hasTranslation = false;
  for (var i = 0; i < timeline.length && i < queue.length; i++) {
    final chunk = queue[i];
    texts.add(chunk.text);
    final spoken = chunk.spokenText;
    if (spoken != null && spoken.isNotEmpty && spoken != chunk.text) {
      spokenTexts.add(spoken);
      hasTranslation = true;
    } else {
      // A placeholder, not a gap. The writer matches a line to the axis by
      // position, so dropping the entries that need no translation would slide
      // every rewritten sentence onto the boundary of the sentence before it —
      // and the first sentence of a page is exactly the one most likely to be
      // rewritten. An empty body is skipped at write time, so the placeholder
      // leaves a hole without moving anything.
      spokenTexts.add('');
    }
  }

  return (
    lrc: buildLrc(timeline: timeline, texts: texts),
    // A translation line is only worth its vertical space where it differs
    // from the line above it. Emitting one per sentence would double the
    // layout cost of every line to repeat text already on screen.
    translationLrc: hasTranslation
        ? buildLrc(timeline: timeline, texts: spokenTexts)
        : null,
  );
}

/// Maps the package defaults onto the app's colour scheme, type, the reader's
/// alignment choices in [prefs], and [singleLine].
///
/// Taken from the package presets rather than written from scratch: the
/// defaults encode real behaviour — the anchor position, the fade distances,
/// Assembles the lyric preset for the view.
///
/// Public so a test can read the preset the view actually uses. Tapping a line
/// and following the highlight are two independent index paths, and the only
/// way to hold them against each other is to know where the highlight is
/// parked — which is a preset decision, not a constant.
LyricPreset buildTtsLyricPreset(
  BuildContext context,
  ColorScheme scheme,
  TtsLyricStyle prefs, {
  bool singleLine = false,
}) {
  final textTheme = Theme.of(context).textTheme;

  return LyricPreset(
    displayMode: singleLine
        ? LyricDisplayMode.activeLine
        : LyricDisplayMode.scrollable,
    interactive: !singleLine,
    textStyle: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: scheme.onSurface.withValues(alpha: 0.55),
      fontSize: 15,
      height: 1.35,
    ),
    activeTextStyle: (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: scheme.onSurface,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    translationTextStyle: (textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
      fontSize: 13,
      height: 1.3,
    ),
    activeTranslationTextStyle: (textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: 13,
          height: 1.3,
        ),
    selectedTextColor: scheme.onSurface,
    selectedTranslationTextColor: scheme.onSurfaceVariant,
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
    lineSpacing: 18,
    translationSpacing: 6,
    activeAnchor: LyricAnchor.fraction(
      0.35,
      target: prefs.activeAnchorAlign.toAnchorTarget(),
    ),
    selectionAnchor: LyricAnchor.fraction(
      0.35,
      target: prefs.selectionAnchorAlign.toAnchorTarget(),
    ),
    highlight: const LyricHighlight.none(),
    textAlign: prefs.lineAlign.toTextAlign(),
    contentAlignment: prefs.contentAlign.toLyricContentAlignment(),
    edgeFade: singleLine
        ? const LyricEdgeFade.none()
        : const LyricEdgeFade.pixels(top: 48, bottom: 64),
    scrollAnimation: singleLine
        ? const LyricScrollAnimation.none()
        : LyricScrollAnimation.byDistance(
            durations: {
              400.0: const Duration(milliseconds: 320),
              800.0: const Duration(milliseconds: 480),
            },
            duration: const Duration(milliseconds: 240),
          ),
    lineTransition: singleLine
        ? LyricLineTransitions.cinematic
        : const LyricLineTransition(
            enterDuration: Duration(milliseconds: 160),
            exitDuration: Duration(milliseconds: 120),
          ),
    selectionSnapMode: singleLine
        ? LyricSelectionSnapMode.none
        : LyricSelectionSnapMode.afterScroll,
    selectionSnapDelay: singleLine
        ? Duration.zero
        : const Duration(milliseconds: 1500),
    resumeDelay: singleLine ? null : const Duration(milliseconds: 3000),
  );
}

@Deprecated('Use buildTtsLyricPreset instead')
LyricPreset buildTtsLyricStyle(
  BuildContext context,
  ColorScheme scheme,
  TtsLyricStyle prefs, {
  bool singleLine = false,
}) => buildTtsLyricPreset(context, scheme, prefs, singleLine: singleLine);

extension on LyricLineAlign {
  TextAlign toTextAlign() => switch (this) {
    LyricLineAlign.left => TextAlign.left,
    LyricLineAlign.center => TextAlign.center,
    LyricLineAlign.right => TextAlign.right,
    LyricLineAlign.justify => TextAlign.justify,
  };
}

extension on LyricContentAlign {
  LyricContentAlignment toLyricContentAlignment() => switch (this) {
    LyricContentAlign.start => LyricContentAlignment.start,
    LyricContentAlign.center => LyricContentAlignment.center,
    LyricContentAlign.end => LyricContentAlignment.end,
  };
}

extension on LyricAnchorAlign {
  LyricAnchorTarget toAnchorTarget() => switch (this) {
    LyricAnchorAlign.start => LyricAnchorTarget.mainText,
    LyricAnchorAlign.center => LyricAnchorTarget.lineCenter,
    LyricAnchorAlign.end => LyricAnchorTarget.translationText,
  };
}
