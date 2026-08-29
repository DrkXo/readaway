import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/services.dart';
import '../../../reader/presentation/bloc/reader_bloc.dart';
import '../../../settings/presentation/bloc/tts/tts_bloc.dart';

part 'tts_player_bloc.freezed.dart';
part 'tts_player_event.dart';
part 'tts_player_state.dart';

/// Owns the TTS "music player" session: which page/sentence is playing,
/// the lyrics list for the current page, rate/pitch/voice, and the sleep
/// timer. Wraps the shared [ReaderTtsController] and reads page text from
/// MuPDF (via [MuPdfService]). Lives as a singleton so playback survives
/// navigation.
@Singleton()
class TtsPlayerBloc extends Bloc<TtsPlayerEvent, TtsPlayerState> {
  TtsPlayerBloc({
    required this._controller,
    required this._readerBloc,
    required this._textChunker,
    required this._settingsService,
    required this._muPdfService,
  }) : super(const TtsPlayerState()) {
    on<_PlayFromPage>(_onPlayFromPage);
    on<_PlayPause>(_onPlayPause);
    on<_Pause>(_onPause);
    on<_Resume>(_onResume);
    on<_Stop>(_onStop);
    on<_ClosePlayer>(_onClosePlayer);
    on<_NextSentence>(_onNextSentence);
    on<_PreviousSentence>(_onPreviousSentence);
    on<_SetRate>(_onSetRate);
    on<_SetPitch>(_onSetPitch);
    on<_SetVoice>(_onSetVoice);
    on<_SetSleepTimer>(_onSetSleepTimer);
    on<_CancelSleepTimer>(_onCancelSleepTimer);
    on<_RestoreSettings>(_onRestoreSettings);
    on<_PlaybackChanged>(_onPlaybackChanged);
    on<_ChunkChanged>(_onChunkChanged);
    on<_SleepTimerTick>(_onSleepTimerTick);

    _playbackSub = _controller.playbackState.listen(
      (event) => add(_PlaybackChanged(event)),
    );
    _chunkSub = _controller.currentChunk.listen(
      (chunk) => add(_ChunkChanged(chunk)),
    );

    add(const _RestoreSettings());
  }

  final ReaderTtsController _controller;
  final ReaderBloc _readerBloc;
  final TextChunker _textChunker;
  final SettingsService _settingsService;
  final MuPdfService _muPdfService;

  StreamSubscription<TtsPlaybackEvent>? _playbackSub;
  StreamSubscription<TtsChunk>? _chunkSub;
  Timer? _sleepTimer;

  /// True when the user (or sleep timer) asked to stop — used to tell a
  /// natural end-of-page apart from an intentional stop so we only
  /// auto-advance pages in the former case.
  bool _userInitiatedStop = false;

  /// True once the player has been closed (✕). Suppresses the controller's
  /// trailing `stopped` event so the mini-player actually dismisses.
  bool _closed = false;

  /// Raw text of the current page, kept so "play" after a stop can resume
  /// from the same position.
  String? _currentPageText;

  // ---------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------

  Future<void> _onPlayFromPage(
    _PlayFromPage event,
    Emitter<TtsPlayerState> emit,
  ) async {
    await _startPage(event.pageIndex, emit: emit);
  }

  Future<void> _onPlayPause(
    _PlayPause event,
    Emitter<TtsPlayerState> emit,
  ) async {
    switch (state.playbackState) {
      case TtsPlaybackState.playing:
        await _controller.pause();
      case TtsPlaybackState.paused:
        await _controller.resume();
      case TtsPlaybackState.idle:
      case TtsPlaybackState.stopped:
        if (_currentPageText != null && state.chunkCount > 0) {
          _userInitiatedStop = false;
          emit(state.copyWith(loading: true, error: null));
          final startAt = state.currentChunkIndex >= 0
              ? state.currentChunkIndex
              : 0;
          await _controller.playText(
            _currentPageText!,
            startAtChunkIndex: startAt,
          );
        }
      case TtsPlaybackState.loading:
      case TtsPlaybackState.error:
        break;
    }
  }

  Future<void> _onPause(_Pause event, Emitter<TtsPlayerState> emit) async {
    if (state.playbackState != TtsPlaybackState.playing) return;
    await _controller.pause();
  }

  Future<void> _onResume(_Resume event, Emitter<TtsPlayerState> emit) async {
    if (state.playbackState != TtsPlaybackState.paused) return;
    await _controller.resume();
  }

  Future<void> _onStop(_Stop event, Emitter<TtsPlayerState> emit) async {
    _userInitiatedStop = true;
    await _controller.stop();
    emit(
      state.copyWith(
        playbackState: TtsPlaybackState.stopped,
        loading: false,
      ),
    );
  }

  Future<void> _onClosePlayer(
    _ClosePlayer event,
    Emitter<TtsPlayerState> emit,
  ) async {
    _userInitiatedStop = true;
    _closed = true;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    await _controller.stop();
    _currentPageText = null;
    emit(
      state.copyWith(
        loading: false,
        error: null,
        playbackState: TtsPlaybackState.idle,
        currentPageIndex: 0,
        currentChunkIndex: -1,
        chunkCount: 0,
        pageSentences: const [],
        sleepTimerRemaining: null,
      ),
    );
  }

  Future<void> _onNextSentence(
    _NextSentence event,
    Emitter<TtsPlayerState> emit,
  ) async {
    if (!state.isActive) return;
    await _controller.skipToNextSentence();
  }

  Future<void> _onPreviousSentence(
    _PreviousSentence event,
    Emitter<TtsPlayerState> emit,
  ) async {
    if (!state.isActive) return;
    // At the first sentence of a page → jump to the previous page's last
    // sentence.
    if (state.currentChunkIndex <= 0 && state.currentPageIndex > 0) {
      await _startPage(
        state.currentPageIndex - 1,
        startAtChunkIndex: -1,
        emit: emit,
      );
      return;
    }
    await _controller.skipToPreviousSentence();
  }

  // ---------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------

  Future<void> _onSetRate(_SetRate event, Emitter<TtsPlayerState> emit) async {
    final rate = event.rate.clamp(0.5, 2.0);
    emit(state.copyWith(rate: rate));
    await _controller.setRate(rate);
    _persistRate(rate);
  }

  Future<void> _onSetPitch(
    _SetPitch event,
    Emitter<TtsPlayerState> emit,
  ) async {
    final pitch = event.pitch.clamp(0.5, 2.0);
    emit(state.copyWith(pitch: pitch));
    await _controller.setPitch(pitch); // no-op in sherpa-onnx.
  }

  Future<void> _onSetVoice(
    _SetVoice event,
    Emitter<TtsPlayerState> emit,
  ) async {
    final voice = event.voice;
    emit(state.copyWith(voice: voice, loading: true, error: null));
    try {
      await _controller.setVoice(voice);
      emit(state.copyWith(voice: voice, loading: false));
      // Keep the settings voice catalog in sync (also persists ttsVoice).
      GetIt.I<TtsBloc>().add(TtsEvent.activate(voice.id));
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Failed to switch voice: $e',
        ),
      );
    }
  }

  void _onSetSleepTimer(
    _SetSleepTimer event,
    Emitter<TtsPlayerState> emit,
  ) {
    _sleepTimer?.cancel();
    final duration = event.duration;
    if (duration == null) {
      emit(state.copyWith(sleepTimerRemaining: null));
      return;
    }
    emit(state.copyWith(sleepTimerRemaining: duration));
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const _SleepTimerTick());
    });
  }

  void _onCancelSleepTimer(
    _CancelSleepTimer event,
    Emitter<TtsPlayerState> emit,
  ) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    emit(state.copyWith(sleepTimerRemaining: null));
  }

  void _onSleepTimerTick(
    _SleepTimerTick event,
    Emitter<TtsPlayerState> emit,
  ) {
    final remaining = state.sleepTimerRemaining;
    if (remaining == null) {
      _sleepTimer?.cancel();
      return;
    }
    final next = remaining - const Duration(seconds: 1);
    if (next <= Duration.zero) {
      _sleepTimer?.cancel();
      _sleepTimer = null;
      emit(state.copyWith(sleepTimerRemaining: Duration.zero));
      _userInitiatedStop = true;
      unawaited(_controller.stop());
    } else {
      emit(state.copyWith(sleepTimerRemaining: next));
    }
  }

  Future<void> _onRestoreSettings(
    _RestoreSettings event,
    Emitter<TtsPlayerState> emit,
  ) async {
    final view = _settingsService.settings.globalViewSettings;
    final rate = view.ttsRate;
    if (rate != 1.0) {
      await _controller.setRate(rate);
    }

    var voice = state.voice;
    final persistedVoice = view.ttsVoice;
    if (persistedVoice != null) {
      final installed = await _controller.getInstalledVoices();
      final match = installed.where((v) => v.id == persistedVoice).firstOrNull;
      if (match != null) {
        await _controller.setVoice(match);
        voice = match;
      }
    }

    emit(state.copyWith(rate: rate, voice: voice));
  }

  // ---------------------------------------------------------------------
  // Controller stream handlers
  // ---------------------------------------------------------------------

  void _onPlaybackChanged(
    _PlaybackChanged event,
    Emitter<TtsPlayerState> emit,
  ) {
    final playback = event.event;
    switch (playback.state) {
      case TtsPlaybackState.playing:
        emit(
          state.copyWith(
            playbackState: TtsPlaybackState.playing,
            loading: false,
            error: null,
          ),
        );
      case TtsPlaybackState.paused:
        emit(state.copyWith(playbackState: TtsPlaybackState.paused));
      case TtsPlaybackState.stopped:
        // After a close the controller's trailing `stopped` event must not
        // resurrect the mini-player — the session is already reset to idle.
        if (_closed) return;
        emit(
          state.copyWith(
            playbackState: TtsPlaybackState.stopped,
            loading: false,
          ),
        );
        if (!_userInitiatedStop) {
          _advanceToNextPage();
        }
      case TtsPlaybackState.error:
        emit(
          state.copyWith(
            playbackState: TtsPlaybackState.error,
            error: playback.message,
            loading: false,
          ),
        );
      case TtsPlaybackState.idle:
      case TtsPlaybackState.loading:
        emit(state.copyWith(playbackState: playback.state));
    }
  }

  void _onChunkChanged(_ChunkChanged event, Emitter<TtsPlayerState> emit) {
    emit(
      state.copyWith(
        currentChunkIndex: _controller.currentChunkIndex ?? 0,
        chunkCount: _controller.queueLength,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// Loads [pageIndex]'s text from MuPDF, chunks it into sentences, and
  /// starts playback from [startAtChunkIndex] (or the last sentence when
  /// negative).
  Future<void> _startPage(
    int pageIndex, {
    int startAtChunkIndex = 0,
    required Emitter<TtsPlayerState> emit,
  }) async {
    final readerState = _readerBloc.state;
    if (!readerState.hasDocument || !readerState.isReflowable) {
      emit(
        state.copyWith(
          loading: false,
          error: 'TTS is only available for reflowable documents.',
        ),
      );
      return;
    }
    if (pageIndex < 0 || pageIndex >= readerState.pageCount) return;

    _userInitiatedStop = false;
    _closed = false;
    emit(
      state.copyWith(
        loading: true,
        error: null,
        currentPageIndex: pageIndex,
        totalPages: readerState.pageCount,
      ),
    );

    final text = await _loadPageText(pageIndex);
    if (text == null || text.trim().isEmpty) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No readable text on this page.',
        ),
      );
      return;
    }

    final sentences = _textChunker
        .chunkSentences(text)
        .map((c) => c.text)
        .toList();
    if (sentences.isEmpty) {
      emit(
        state.copyWith(
          loading: false,
          error: 'No readable text on this page.',
        ),
      );
      return;
    }

    _currentPageText = text;
    final startAt = startAtChunkIndex < 0
        ? sentences.length - 1
        : startAtChunkIndex.clamp(0, sentences.length - 1).toInt();

    emit(
      state.copyWith(
        loading: false,
        pageSentences: sentences,
        chunkCount: sentences.length,
        currentChunkIndex: startAt,
      ),
    );

    await _controller.playText(text, startAtChunkIndex: startAt);
  }

  /// Returns the plain text for [index] straight from MuPDF (the source of
  /// truth), which separates paragraphs with blank lines so the chunker can
  /// split on them. Also asks the reader to load the page so its cache stays
  /// warm (does not navigate the reader).
  Future<String?> _loadPageText(int index) async {
    _readerBloc.add(ReaderEvent.loadPage(index: index));
    return _muPdfService.extractPageText(index);
  }

  /// Advances to the next page when the current one finishes naturally.
  void _advanceToNextPage() {
    final next = state.currentPageIndex + 1;
    if (next >= state.totalPages) return;
    add(TtsPlayerEvent.playFromPage(next));
  }

  void _persistRate(double rate) {
    final current = _settingsService.settings;
    if (current.globalViewSettings.ttsRate == rate) return;
    _settingsService.scheduleSave(
      current.copyWith(
        globalViewSettings: current.globalViewSettings.copyWith(ttsRate: rate),
      ),
    );
  }

  @override
  Future<void> close() async {
    _sleepTimer?.cancel();
    await _playbackSub?.cancel();
    await _chunkSub?.cancel();
    await super.close();
  }
}
