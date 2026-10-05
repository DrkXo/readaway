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
    _lyric.setOnTapLineCallback(_onLineTapped);
  }

  void _subscribe() {
    _timelineSub = widget.tts.timelineStream.listen((_) => _reloadLyrics());
    // The queue can be replaced (a new page) without the axis changing shape
    // first, so both have to be watched to avoid pairing one page's text with
    // another's timings.
    _queueSub = widget.tts.queueVersion.listen((_) => _reloadLyrics());
    _positionSub = widget.tts.globalPositionStream.listen(
      _lyric.setProgress,
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
      _lyric.loadLyric('');
      setState(() {});
      return;
    }

    final page = buildPageLyric(timeline: timeline, queue: widget.tts.queue);
    _loadedTimeline = timeline;
    _lyric.loadLyric(page.lrc, translationLyric: page.translationLrc);
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
      //
      // The package decides how much work a new style needs by comparing only
      // the fields that change a line's size — gap, padding, the three text
      // styles — and treats everything else as safe to reuse. Alignments are
      // not in that set, so a new `lineTextAlign` would be handed to the
      // painter while the `TextPainter`s it must apply to were still the old
      // ones, and the reader would see nothing change. Remounting is heavier
      // than it sounds but happens only on a deliberate settings change: the
      // controller outlives the state, so the active sentence survives and the
      // fresh layout re-parks it against the new anchor.
      key: ValueKey(widget.style),
      controller: _lyric,
      style: buildTtsLyricStyle(
        context,
        scheme,
        widget.style,
        singleLine: widget.singleLine,
      ),
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
/// the resume-after-selection timings — that is easy to lose when a style is
/// assembled field by field, and only the appearance needs to differ.
///
/// Public so a test can read the anchor the view actually uses. Tapping a line
/// and following the highlight are two independent index paths, and the only
/// way to hold them against each other is to know where the highlight is
/// parked — which is a style decision, not a constant.
LyricStyle buildTtsLyricStyle(
  BuildContext context,
  ColorScheme scheme,
  TtsLyricStyle prefs, {
  bool singleLine = false,
}) {
  // Swapping the preset rather than overriding a field is what makes
  // single-line mode work. `copyWith` cannot null a `fadeRange`, so the fade
  // that softens the top and bottom of a scrolling list would stay on and dim
  // the one line there is; the preset also drops the gap between lines, tightens
  // the gap to a translation, and cuts between sentences instead of sliding,
  // which is what a page showing one sentence at a time should do. Everything
  // that matters below is then applied on top of either preset alike.
  final base = singleLine ? LyricStyles.single : LyricStyles.default1;
  final textTheme = Theme.of(context).textTheme;

  return base.copyWith(
    textStyle: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: scheme.onSurface.withValues(alpha: 0.55),
      fontSize: 15,
      height: 1.35,
    ),
    activeStyle: (textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: scheme.onSurface,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    translationStyle: (textTheme.bodySmall ?? const TextStyle()).copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
      fontSize: 13,
      height: 1.3,
    ),
    translationActiveColor: scheme.onSurfaceVariant,
    // Where the previous sentence list parked the active row, so the swap does
    // not move the reader's eye.
    //
    // Both anchors, not one. `anchorPosition` sets the *selection* anchor; the
    // active line is positioned by `activeAnchorPosition`, which the stock
    // style leaves at whatever `selectionAnchorPosition` held when it was
    // constructed. Setting only the first moves where a tapped line lands and
    // leaves the highlight where it always was.
    anchorPosition: 0.35,
    activeAnchorPosition: 0.35,
    // `contentPadding.top` is scroll runway, not inset: the package clamps the
    // first line so it cannot scroll further up than this, and the stock value
    // of 500 exists so a song's opening line can reach mid-screen. A page is
    // read from the top, so the runway only needs to keep the first sentence
    // off the edge.
    contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
    lineGap: 18,
    translationLineGap: 6,
    selectedColor: scheme.onSurface,
    selectedTranslationColor: scheme.onSurfaceVariant,
    // The sweep along the active line is the package's own karaoke effect. It
    // is per-tick repaint work, and at line granularity there is nothing to
    // sweep, so it stays off.
    activeHighlightColor: null,
    textAlign: prefs.lineAlign.toTextAlign(),
    contentAlignment: prefs.contentAlign.toCrossAxisAlignment(),
    // Both anchor alignments, for the same reason as both anchor positions
    // above: `activeAlignment` falls back to whatever the *selection* alignment
    // was when the style was constructed, so passing one and not the other
    // would silently retarget the active line too.
    highlightAlign: prefs.selectionAnchorAlign.toMainAxisAlignment(),
    activeAlignment: prefs.activeAnchorAlign.toMainAxisAlignment(),
    // Stated rather than left to whichever preset was picked above: this pair
    // is the whole of single-line mode, and a style that draws one line while
    // still accepting taps and drags on the invisible ones is a mode nobody
    // asked for.
    activeLineOnly: singleLine,
    disableTouchEvent: singleLine,
    // Smooth line-switch animation in the full view. The single preset already
    // sets enableSwitchAnimation: false (instant cut on sentence change, which
    // is right when there is only one visible line). For the full scrolling
    // view a short fade-in keeps the eye on the new active line without
    // appearing to jump — still fast enough not to lag behind speech.
    enableSwitchAnimation: !singleLine,
    switchEnterDuration: singleLine
        ? Duration.zero
        : const Duration(milliseconds: 160),
    switchExitDuration: singleLine
        ? Duration.zero
        : const Duration(milliseconds: 120),
    // Distance-aware scroll durations: short lines close to the anchor
    // travel fast (240 ms), but a skip to a distant sentence uses a longer
    // ease so it does not feel like a teleport. The map keys are pixel
    // distances and are matched by `>=`, so only two tiers are needed.
    scrollDurationMap: singleLine
        ? const {}
        : {
            400.0: const Duration(milliseconds: 320),
            800.0: const Duration(milliseconds: 480),
          },
    // Soft fade at top and bottom of the full list, sized for the typical
    // phone portrait height. Expressed in absolute pixels so it does not
    // depend on the container height (a relative fade that trims 20 % of a
    // tall screen clips far too much of the context). Single-line mode has
    // no list to fade, so the preset's zero-fade is kept as-is.
    fadeRange: singleLine ? null : FadeRange(top: 48, bottom: 64),
    // How long after the user stops scrolling before the view snaps back to
    // the active sentence. 3 s is enough to read the line the user browsed to;
    // shorter feels like it snatches focus back. The selection resume fires
    // sooner (1.5 s) to handle accidental drags gracefully.
    selectLineResumeDuration: singleLine
        ? null
        : const Duration(milliseconds: 1500),
    activeLineResumeDuration: singleLine
        ? null
        : const Duration(milliseconds: 3000),
    selectLineResumeMode: singleLine
        ? null
        : SelectionAutoResumeMode.afterSelecting,
  );
}

extension on LyricLineAlign {
  TextAlign toTextAlign() => switch (this) {
    LyricLineAlign.left => TextAlign.left,
    LyricLineAlign.center => TextAlign.center,
    LyricLineAlign.right => TextAlign.right,
    LyricLineAlign.justify => TextAlign.justify,
  };
}

extension on LyricContentAlign {
  CrossAxisAlignment toCrossAxisAlignment() => switch (this) {
    LyricContentAlign.start => CrossAxisAlignment.start,
    LyricContentAlign.center => CrossAxisAlignment.center,
    LyricContentAlign.end => CrossAxisAlignment.end,
  };
}

extension on LyricAnchorAlign {
  MainAxisAlignment toMainAxisAlignment() => switch (this) {
    LyricAnchorAlign.start => MainAxisAlignment.start,
    LyricAnchorAlign.center => MainAxisAlignment.center,
    LyricAnchorAlign.end => MainAxisAlignment.end,
  };
}
