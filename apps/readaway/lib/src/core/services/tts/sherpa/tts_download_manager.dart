// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:readaway_core/readaway_core.dart';
import 'package:rxdart/rxdart.dart';

import '../../background_downloader_service.dart';
import '../../path_service.dart';
import '../extractor/tts_archive_extractor.dart';
import '../tts_download_task.dart';
import '../tts_model_store.dart';
import '../tts_models.dart';

/// The single owner of TTS voice downloads.
///
/// All TTS voice traffic flows through this manager:
///
/// * Every sub-transfer (archive, vocoder) gets a deterministic, stable
///   `taskId` so it can be paused/resumed/cancelled and is tracked in the
///   database across app restarts.
/// * The pipeline is a phase machine ([TtsDownloadPhase]) with a monotonic,
///   phase-weighted overall fraction — the progress bar never restarts when
///   a later sub-file begins, and it never reports 100% before the model is
///   actually installed.
/// * A cancel token is checked at every `await`, so cancelling during
///   extraction/aux file install can never persist an installed model.
/// * Tasks interrupted by app death are rehydrated and parked as
///   `interrupted` (never auto-rescheduled; the user resumes them manually
///   via [resume], surfaced by the Downloads UI).
/// * At most [_maxConcurrent] pipelines run at once; progress emissions are
///   throttled per task.
///
/// State is exposed as a snapshot stream ([snapshots]) keyed by model id.
/// The download manager is the only writer of installed state (via
/// [TtsModelStore.saveInstalledModel]) after a pipeline reaches `done`.
@singleton
class TtsDownloadManager {
  final _log = AppLogger.instance.scope('TtsDownloadManager');

  TtsDownloadManager({
    required BackGroundDownloaderService backgroundDownloader,
    required AppPathService pathService,
    required TtsModelStore store,
    required TtsArchiveExtractor archiveExtractor,
  }) : _backgroundDownloader = backgroundDownloader,
       _pathService = pathService,
       _store = store,
       _archiveExtractor = archiveExtractor;

  final BackGroundDownloaderService _backgroundDownloader;
  final AppPathService _pathService;
  final TtsModelStore _store;
  final TtsArchiveExtractor _archiveExtractor;

  /// Task group used for every TTS voice transfer so app-wide operations
  /// (cancel-all, storage badges) can target just TTS traffic.
  static const String taskGroup = 'tts-voice';

  /// Stable task id of the shared espeak-ng-data archive.
  static const String espeakTaskId = 'tts-espeak-data';

  /// Overall-fraction weights per phase group. The archive dominates; the
  /// remaining phases share a small tail so the bar is meaningful and the
  /// window after the archive download never looks "stuck at 100%".
  static const double archiveWeight = 0.85;
  static const double extractWindowStart = 0.85;
  static const double extractWindowEnd = 0.92;
  static const double auxWindowStart = 0.92;
  static const double auxWindowEnd = 0.98;
  static const double finalizeFraction = 0.98;

  static const int _maxConcurrent = 2;
  static const Duration _emitThrottle = Duration(milliseconds: 150);

  /// How long to wait for a reattached-but-`running` transfer to emit an
  /// update before parking it as `interrupted`.
  static const Duration _reattachSilenceGrace = Duration(milliseconds: 300);

  final Map<String, _ModelDownloadRunner> _runners = {};
  final Map<String, List<Transfer>> _transfersByModel = {};

  final BehaviorSubject<Map<String, TtsDownloadTask>> _snapshots =
      BehaviorSubject<Map<String, TtsDownloadTask>>.seeded(const {});

  Future<void>? _espeakInstallFuture;
  bool _initialized = false;
  Completer<void>? _initCompleter;

  // Concurrency slots for pipelines (fresh downloads + repairs share them).
  int _activeSlots = 0;
  final List<Completer<void>> _slotWaiters = [];

  // Throttled emission state (one trailing flush per task).
  final Map<String, Timer> _emitTimers = {};
  final Map<String, TtsDownloadTask> _pendingEmits = {};

  /// Current snapshot of every known TTS download task, keyed by model id.
  /// Replays the latest state on subscription.
  ValueStream<Map<String, TtsDownloadTask>> get snapshots => _snapshots.stream;

  TtsDownloadTask? taskOf(String modelId) => _snapshots.value[modelId];

  bool isDownloading(String modelId) {
    final task = _snapshots.value[modelId];
    return task != null && task.phase.isActive;
  }

  /// Whether [modelId] currently has a task the user can act on (resume,
  /// pause, cancel) — i.e. not installed and not just removed.
  bool hasActionableTask(String modelId) => _snapshots.value[modelId] != null;

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  /// Runs once at DI startup: initializes the downloader, registers any
  /// TTS transfers interrupted by a previous process lifetime as resumable
  /// `interrupted` tasks, and (unawaited) repairs models whose archive
  /// landed but whose install never finished. Cheap reads only; repairs run
  /// in the background.
  @PostConstruct(preResolve: true)
  Future<void> init() => ensureInitialized();

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    final completer = Completer<void>();
    _initCompleter = completer;
    try {
      await _backgroundDownloader.ensureInitialized();
      _registerInterruptedTransfers();
      unawaited(_repairMarkedDownloads());
      _initialized = true;
      completer.complete();
    } catch (e, st) {
      _log.e('TtsDownloadManager init failed', error: e, stackTrace: st);
      completer.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
  }

  @disposeMethod
  void dispose() {
    for (final t in _emitTimers.values) {
      t.cancel();
    }
    _emitTimers.clear();
    _pendingEmits.clear();
    if (!_snapshots.isClosed) {
      _snapshots.close();
    }
  }

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------

  /// Starts the install pipeline for [model] (idempotent — safe to call
  /// repeatedly: an existing queued/running/interrupted task is returned
  /// untouched). Returns the current task state.
  TtsDownloadTask start(SherpaTtsModelInfo model) {
    final existing = _runners[model.id];
    if (existing != null) {
      return existing.task;
    }
    final runner = _ModelDownloadRunner(this, model);
    _runners[model.id] = runner;
    final task = runner.task.copyWith(
      phase: TtsDownloadPhase.queued,
      fraction: 0,
    );
    runner.updateTask(task);
    _emitNow(task);
    unawaited(
      _runWithSlot(() async {
        if (runner.isCanceled) return;
        await runner.run();
      }),
    );
    return task;
  }

  /// Pauses every sub-transfer of [modelId]'s pipeline. No-op when there is
  /// nothing pausable (e.g. extraction is running).
  Future<void> pause(String modelId) async {
    final runner = _runners[modelId];
    if (runner == null) return;
    await runner.pause();
  }

  /// Resumes [modelId]'s pipeline. If the pipeline was parked as
  /// `interrupted` (rehydrated after app death) or paused by the user, the
  /// underlying transfers are resumed and the pipeline continues.
  Future<void> resume(String modelId) async {
    final runner = _runners[modelId];
    if (runner == null) return;
    await runner.resume();
  }

  /// Requests cancellation of [modelId]'s pipeline. The cancel token is
  /// checked at every await, so a cancellation during extraction/aux will
  /// NOT persist an installed model. The snapshot entry is removed once the
  /// runner unwinds.
  Future<void> cancel(String modelId) async {
    final runner = _runners[modelId];
    if (runner == null) return;
    await runner.cancel();
    if (!runner._started && !runner._finished) {
      // Queued or bootstrapped-interrupted but never started: drop it
      // immediately (a started runner cleans itself up in _onRunnerFinished).
      _removeTask(modelId);
      _runners.remove(modelId);
    }
  }

  /// Ensures the shared espeak-ng-data directory exists, downloading it once
  /// (deduplicated across concurrent callers).
  Future<void> ensureSharedEspeakData([Directory? rootDir]) async {
    final root = rootDir ?? await _pathService.getTtsModelsDirectory();
    final sharedEspeakDir = Directory(p.join(root.path, 'espeak-ng-data'));
    if (await sharedEspeakDir.exists()) return;
    return _espeakInstallFuture ??= _installEspeakData(
      root,
      sharedEspeakDir,
    ).whenComplete(() => _espeakInstallFuture = null);
  }

  // ---------------------------------------------------------------------
  // Bootstrap
  // ---------------------------------------------------------------------

  /// Registers every previously-tracked TTS transfer that is still active
  /// (not final) as an `interrupted` task so the user can decide to resume
  /// it. Auto-rescheduling is intentionally off; the downloads UI offers a
  /// manual "Resume interrupted" instead.
  void _registerInterruptedTransfers() {
    final transfers = _backgroundDownloader.all();
    for (final t in transfers) {
      if (t.status.isFinalState) continue;
      if (t.task is! DownloadTask) continue;
      final taskId = t.task.taskId;
      // The shared espeak archive is re-downloaded lazily; aux task ids
      // (`-vocoder`) are covered by their model's runner.
      if (!_isArchiveTaskId(taskId)) continue;

      final modelId = _modelIdFromArchiveTaskId(taskId);
      if (modelId == null || _runners.containsKey(modelId)) continue;

      final model = _store.byId(modelId);
      if (model == null) {
        _log.w('Ignoring interrupted TTS transfer for unknown model $modelId');
        continue;
      }

      _log.d(
        'Registering interrupted TTS download for $modelId (${t.status.name})',
      );
      final runner = _ModelDownloadRunner(this, model);
      _runners[modelId] = runner;
      _transfersByModel[modelId] = [t];
      final archiveFraction = (t.progress ?? 0).clamp(0.0, 1.0);
      final task = runner.task.copyWith(
        phase: TtsDownloadPhase.interrupted,
        fraction: archiveWeight * archiveFraction,
        interrupted: true,
      );
      runner.updateTask(task);
      _emitNow(task);
    }
  }

  /// Completes installs that were interrupted after the archive transfer
  /// finished but before the model was recorded as installed. Triggered at
  /// startup (unawaited) and by the archive-download path reacting to a
  /// rehydrated `complete` transfer. Best-effort: failures are logged, never
  /// thrown (it runs on the startup path).
  Future<void> _repairMarkedDownloads() async {
    try {
      final root = await _pathService.getTtsModelsDirectory();
      if (!await root.exists()) return;

      await for (final entity in root.list()) {
        if (entity is! Directory) continue;
        final modelId = p.basename(entity.path);
        if (_runners.containsKey(modelId)) continue;
        final model = _store.byId(modelId);
        if (model == null) continue;

        if (!await _hasDoneMarker(entity)) continue;

        _log.d('Repairing interrupted TTS install for $modelId');
        final runner = _ModelDownloadRunner(this, model);
        _runners[modelId] = runner;
        final task = runner.task.copyWith(
          phase: TtsDownloadPhase.extractingArchive,
          fraction: extractWindowStart,
        );
        runner.updateTask(task);
        _emitNow(task);
        unawaited(
          _runWithSlot(() async {
            if (runner.isCanceled) return;
            await runner.runRepair();
          }),
        );
      }
    } catch (e, st) {
      _log.w(
        'Interrupted-download repair scan failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<bool> _hasDoneMarker(Directory dir) async {
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.done')) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------
  // Shared espeak install
  // ---------------------------------------------------------------------

  Future<void> _installEspeakData(
    Directory targetDir,
    Directory espeakDir,
  ) async {
    if (await espeakDir.exists()) return;

    final tmpDir = await _pathService.tempDirectory;
    final archivePath = p.join(tmpDir.path, 'espeak-ng-data.tar.bz2');
    final archiveFile = File(archivePath);

    var needDownload = true;
    if (await archiveFile.exists()) {
      try {
        await _verifyChecksum(archiveFile, 'espeak-ng-data.tar.bz2');
        needDownload = false;
      } catch (_) {
        needDownload = true;
      }
    }

    if (needDownload) {
      final transfer = await _backgroundDownloader.download(
        taskId: espeakTaskId,
        url: SherpaTtsUrls.espeakDataUrl,
        filename: 'espeak-ng-data.tar.bz2',
        saveDirectory: tmpDir,
        userInitiated: true,
        group: taskGroup,
      );
      final result = await transfer.result;
      if (result.status == TaskStatus.canceled) {
        throw const _QuietCancel();
      }
      if (result.status != TaskStatus.complete) {
        throw SherpaTtsException(
          'Failed to download espeak-ng-data: '
          '${result.exception?.description ?? result.status.name}',
        );
      }
      await _verifyChecksum(archiveFile, 'espeak-ng-data.tar.bz2');
    }

    await _archiveExtractor.extractEspeakArchive(
      archiveFile: archiveFile,
      targetDir: targetDir,
      espeakDir: espeakDir,
    );

    if (!await espeakDir.exists()) {
      throw SherpaTtsException(
        'espeak-ng-data archive did not produce an espeak-ng-data directory '
        'in ${targetDir.path}',
      );
    }
  }

  Future<void> _ensureEspeakData(Directory modelDir) async {
    final root = await _pathService.getTtsModelsDirectory();
    final sharedEspeakDir = Directory(p.join(root.path, 'espeak-ng-data'));
    final modelEspeakDir = Directory(p.join(modelDir.path, 'espeak-ng-data'));
    if (await sharedEspeakDir.exists() || await modelEspeakDir.exists()) return;
    return _espeakInstallFuture ??= _installEspeakData(
      root,
      sharedEspeakDir,
    ).whenComplete(() => _espeakInstallFuture = null);
  }

  // ---------------------------------------------------------------------
  // Downloader facade used by runners
  // ---------------------------------------------------------------------

  Future<Transfer> _download({
    required String taskId,
    required String url,
    required String filename,
    required Directory saveDirectory,
    OnTaskFinishedCallback? onTaskFinished,
  }) {
    return _backgroundDownloader.download(
      taskId: taskId,
      url: url,
      filename: filename,
      saveDirectory: saveDirectory,
      userInitiated: true,
      group: taskGroup,
      onTaskFinished: onTaskFinished,
    );
  }

  void _attachTransfers(String modelId, List<Transfer> transfers) {
    _transfersByModel[modelId] = [
      ...?_transfersByModel[modelId],
      ...transfers,
    ];
  }

  List<Transfer>? _transfersOf(String modelId) => _transfersByModel[modelId];

  // ---------------------------------------------------------------------
  // Pipeline execution (slots + cancellation + notifications)
  // ---------------------------------------------------------------------

  Future<void> _runWithSlot(Future<void> Function() body) async {
    await _acquireSlot();
    try {
      await body();
    } finally {
      _releaseSlot();
    }
  }

  Future<void> _acquireSlot() async {
    while (_activeSlots >= _maxConcurrent) {
      final waiter = Completer<void>();
      _slotWaiters.add(waiter);
      await waiter.future;
    }
    _activeSlots++;
  }

  void _releaseSlot() {
    _activeSlots--;
    if (_activeSlots < _maxConcurrent && _slotWaiters.isNotEmpty) {
      _slotWaiters.removeAt(0).complete();
    }
  }

  void _emit(TtsDownloadTask task) {
    if (_snapshots.isClosed) return;
    _pendingEmits[task.modelId] = task;
    _emitTimers[task.modelId] ??= Timer(_emitThrottle, () {
      _emitTimers.remove(task.modelId);
      final pending = _pendingEmits.remove(task.modelId);
      if (pending != null) _flush(pending);
    });
  }

  /// Immediate (non-throttled) emission for phase transitions and terminal
  /// states, so UI/state consumers never miss a noteworthy change.
  void _emitNow(TtsDownloadTask task) {
    if (_snapshots.isClosed) return;
    _emitTimers.remove(task.modelId)?.cancel();
    _pendingEmits.remove(task.modelId);
    _flush(task);
  }

  void _flush(TtsDownloadTask task) {
    if (_snapshots.isClosed) return;
    _snapshots.add({..._snapshots.value, task.modelId: task});
  }

  void _removeTask(String modelId) {
    _emitTimers.remove(modelId)?.cancel();
    _pendingEmits.remove(modelId);
    if (_snapshots.isClosed) return;
    if (!_snapshots.value.containsKey(modelId)) return;
    final next = Map<String, TtsDownloadTask>.of(_snapshots.value)
      ..remove(modelId);
    _snapshots.add(next);
  }

  Future<void> _onRunnerFinished(_ModelDownloadRunner runner) async {
    final id = runner.model.id;
    _runners.remove(id);
    _transfersByModel.remove(id);
    final task = runner.task;

    switch (task.phase) {
      case TtsDownloadPhase.done:
      case TtsDownloadPhase.failed:
        // Keep terminal tasks visible briefly so the (future) downloads view
        // can confirm completion/error, then drop them.
        Timer(const Duration(seconds: 8), () {
          final current = _snapshots.value[id];
          if (current == null) return;
          if (current.phase == TtsDownloadPhase.done ||
              current.phase == TtsDownloadPhase.failed) {
            _removeTask(id);
          }
        });
        break;
      default:
        // Canceled / never-started: drop immediately.
        _removeTask(id);
    }
  }

  // ---------------------------------------------------------------------
  // Checksum helpers
  // ---------------------------------------------------------------------

  Future<void> _verifyChecksum(File file, String fileName) async {
    final expected = _store.checksumFor(fileName);
    if (expected == null) return;
    final actual = await _sha256Of(file);
    if (actual != expected) {
      throw SherpaTtsException(
        'Checksum mismatch for $fileName (expected $expected, got $actual)',
      );
    }
  }

  Future<String> _sha256Of(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  // ---------------------------------------------------------------------
  // Task id parsing
  // ---------------------------------------------------------------------

  static bool _isArchiveTaskId(String taskId) {
    if (!taskId.startsWith('tts-model-')) return false;
    return !taskId.endsWith('-vocoder');
  }

  static String? _modelIdFromArchiveTaskId(String taskId) {
    if (!_isArchiveTaskId(taskId)) return null;
    return taskId.substring('tts-model-'.length);
  }
}

/// Thrown internally when a task is canceled; the pipeline treats it as a
/// quiet stop rather than a failure.
class _QuietCancel implements Exception {
  const _QuietCancel();
}

/// One install pipeline for a single model.
///
/// The runner owns the phase state machine ([_task]), a cancel token checked
/// at every await, and the sub-transfers (archive, vocoder) registered for
/// pause/resume/cancel.
class _ModelDownloadRunner {
  _ModelDownloadRunner(this._manager, this.model)
    : _task = TtsDownloadTask(
        modelId: model.id,
        phase: TtsDownloadPhase.queued,
      );

  final TtsDownloadManager _manager;
  final SherpaTtsModelInfo model;

  TtsDownloadTask _task;
  TtsDownloadTask get task => _task;

  bool _cancelRequested = false;
  bool _started = false;
  bool _finished = false;
  bool _pendingResume = false;
  Completer<void>? _resumeWait;

  /// Upper bound for a native pause/resume/cancel call. Control calls are
  /// best-effort: if the platform or task database stalls (e.g. a suspended
  /// DB isolate), the state machine must keep moving instead of hanging the
  /// caller forever.
  static const Duration _controlTimeout = Duration(seconds: 2);

  /// Runs a best-effort transfer control operation, tolerating both thrown
  /// errors and operations that never complete.
  Future<void> _safeControl(Future<bool> Function() op) async {
    try {
      await op().timeout(_controlTimeout, onTimeout: () => false);
    } catch (e, st) {
      _manager._log.w(
        'transfer control failed for ${model.id}: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  bool get isCanceled => _cancelRequested;

  void updateTask(TtsDownloadTask task) => _task = task;

  // ---------------------------------------------------------------------
  // Public control
  // ---------------------------------------------------------------------

  Future<void> pause() async {
    if (_cancelRequested || _finished) return;
    final transfers = _manager._transfersOf(model.id);
    if (transfers == null || transfers.isEmpty) return;
    var pausedAny = false;
    for (final t in transfers) {
      if (!t.status.isFinalState) {
        await _safeControl(t.pause);
        pausedAny = true;
      }
    }
    if (pausedAny && _task.phase.isActive) {
      _setPhase(TtsDownloadPhase.paused);
    }
  }

  Future<void> resume() async {
    if (_cancelRequested || _finished) return;
    var resumedAny = false;
    final transfers = _manager._transfersOf(model.id);
    if (transfers != null) {
      for (final t in transfers) {
        if (t.status.isNotFinalState) {
          await _safeControl(t.resume);
          resumedAny = true;
        }
      }
    }
    if (!_started) {
      // Bootstrapped-interrupted task (app died mid-download). Its transfers
      // were just resumed; kick off the pipeline now — it reattaches via the
      // deterministic task id and continues from the partial file.
      _pendingResume = true;
      unawaited(
        _manager._runWithSlot(() async {
          if (_cancelRequested) return;
          await run();
        }),
      );
      return;
    }
    if (_task.phase == TtsDownloadPhase.interrupted) {
      _task = _task.copyWith(interrupted: false);
      _resumeWait?.complete();
    } else if (_task.phase == TtsDownloadPhase.paused) {
      if (resumedAny) {
        // A resumed transfer will drive progress/phase from its updates.
        _setPhase(
          TtsDownloadPhase.downloadingArchive,
          fraction: _task.fraction,
        );
      } else {
        // Nothing was actually paused (e.g. pause during shared espeak
        // download) — resume the aux phase we were in.
        _setPhase(
          TtsDownloadPhase.downloadingAuxiliary,
          fraction: _task.fraction,
        );
      }
    }
  }

  Future<void> cancel() async {
    _cancelRequested = true;
    _resumeWait?.complete();
    final transfers = _manager._transfersOf(model.id);
    if (transfers != null) {
      for (final t in transfers) {
        await _safeControl(t.cancel);
      }
    }
  }

  // ---------------------------------------------------------------------
  // Main pipelines
  // ---------------------------------------------------------------------

  /// Fresh (or reattached) install: archive -> verify -> extract -> aux ->
  /// finalize.
  Future<void> run() async {
    if (_started || _finished) return;
    _started = true;
    try {
      final destDir = await _destDir();
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      _checkCanceled();
      await _downloadArchive(destDir);
      await _installAuxiliaryFiles(destDir);
      await _finalize();
    } on _QuietCancel {
      // User canceled — nothing else to do; snapshot entry is removed by the
      // manager in _onRunnerFinished.
    } catch (e, st) {
      _manager._log.e(
        'Failed to download ${model.id}',
        error: e,
        stackTrace: st,
      );
      _task = _task.copyWith(
        phase: TtsDownloadPhase.failed,
        errorMessage: _friendlyError(model.id, e),
      );
      _manager._emitNow(_task);
    } finally {
      _finished = true;
      await _manager._onRunnerFinished(this);
    }
  }

  /// Finishes a model whose archive already landed (repair path): extract if
  /// the archive still exists, then aux files, then finalize.
  Future<void> runRepair() async {
    if (_started || _finished) return;
    _started = true;
    try {
      final destDir = await _destDir();
      final archiveFile = File(p.join(destDir.path, model.archiveFileName));
      if (await archiveFile.exists()) {
        _checkCanceled();
        await _manager._verifyChecksum(archiveFile, model.archiveFileName);
        _setPhase(
          TtsDownloadPhase.extractingArchive,
          fraction: TtsDownloadManager.extractWindowEnd,
        );
        await _manager._archiveExtractor.extractModelArchive(
          archiveFile: archiveFile,
          destDir: destDir,
        );
        _checkCanceled();
        await archiveFile.delete();
      }
      await _installAuxiliaryFiles(destDir);
      await _finalize();
    } on _QuietCancel {
      // nothing to do
    } catch (e, st) {
      _manager._log.e(
        'Failed to repair ${model.id}',
        error: e,
        stackTrace: st,
      );
      _task = _task.copyWith(
        phase: TtsDownloadPhase.failed,
        errorMessage: _friendlyError(model.id, e),
      );
      _manager._emitNow(_task);
    } finally {
      _finished = true;
      await _manager._onRunnerFinished(this);
    }
  }

  /// Builds the user-facing failure text for [modelId]. Callers throw the
  /// *cause* only, so the prefix is applied exactly once.
  String _friendlyError(String modelId, Object e) {
    final message = e is SherpaTtsException
        ? e.message
        : (e is TaskException ? e.description : e.toString());
    return 'Failed to download $modelId: $message';
  }

  // ---------------------------------------------------------------------
  // Pipeline steps
  // ---------------------------------------------------------------------

  Future<Directory> _destDir() async {
    final root = await _manager._pathService.getTtsModelsDirectory();
    return Directory(p.join(root.path, model.id));
  }

  Future<void> _downloadArchive(Directory destDir) async {
    _checkCanceled();
    _setPhase(TtsDownloadPhase.downloadingArchive);

    final transfer = await _manager._download(
      taskId: ttsModelTaskId(model.id),
      url: model.downloadUrl,
      filename: model.archiveFileName,
      saveDirectory: destDir,
      onTaskFinished: ttsModelTaskFinished,
    );
    _manager._attachTransfers(model.id, [transfer]);

    final progressSub = transfer.progressUpdates.listen((u) {
      _manager._emit(
        _task.copyWith(
          phase: TtsDownloadPhase.downloadingArchive,
          fraction: _archivePhaseFraction(u.progress),
          speedBytesPerSec: u.hasNetworkSpeed
              ? u.networkSpeed * 1024 * 1024
              : null,
          timeRemaining: u.hasTimeRemaining ? u.timeRemaining : null,
        ),
      );
    });
    final statusSub = transfer.statusUpdates.listen((u) {
      if (u.status == TaskStatus.paused && _task.phase.isActive) {
        _setPhase(TtsDownloadPhase.paused);
      } else if (u.status == TaskStatus.failed && _task.phase.isActive) {
        _setPhase(
          TtsDownloadPhase.failed,
          errorMessage: u.exception?.description,
        );
      }
    });

    try {
      final result = await _awaitTransferResult(transfer);
      if (result.status == TaskStatus.canceled) throw const _QuietCancel();
      if (result.status != TaskStatus.complete) {
        // Cause only — _friendlyError adds the "Failed to download <id>"
        // prefix that the user sees under the voice row.
        throw SherpaTtsException(
          result.exception?.description ?? result.status.name,
        );
      }

      final archiveFile = File(p.join(destDir.path, model.archiveFileName));
      if (await archiveFile.exists()) {
        await _manager._verifyChecksum(archiveFile, model.archiveFileName);
        _checkCanceled();
        _setPhase(
          TtsDownloadPhase.verifyingArchive,
          fraction: TtsDownloadManager.extractWindowStart,
        );
        await _manager._archiveExtractor.extractModelArchive(
          archiveFile: archiveFile,
          destDir: destDir,
        );
        _checkCanceled();
        _setPhase(
          TtsDownloadPhase.extractingArchive,
          fraction: TtsDownloadManager.extractWindowEnd,
        );
        await archiveFile.delete();
      } else {
        // The archive is gone — a previous lifetime already extracted it
        // (marker left until finalize). Skip verify/extract and finish the
        // remaining steps, mirroring the repair path.
        _setPhase(
          TtsDownloadPhase.extractingArchive,
          fraction: TtsDownloadManager.extractWindowEnd,
        );
      }
    } finally {
      await progressSub.cancel();
      await statusSub.cancel();
    }
  }

  /// Awaits a sub-transfer's final result, parking as `interrupted` when the
  /// transfer was rehydrated (app killed mid-download) so it waits for a
  /// manual resume instead of hanging invisibly or restarting from zero.
  Future<TaskStatusUpdate> _awaitTransferResult(Transfer transfer) async {
    final status = transfer.status;
    if (status == TaskStatus.paused || status == TaskStatus.waitingToRetry) {
      // Paused (user or rehydrated) with no live worker: park — unless the
      // transfer was already resumed by a manual resume() (bootstrapped
      // interrupted task), in which case it will now drive to completion.
      if (!_pendingResume) _parkAsInterrupted();
    } else if (status.isNotFinalState && status != TaskStatus.enqueued) {
      // Running without (necessarily) a live worker. A freshly-started
      // transfer emits updates immediately; a rehydrated dead one stays
      // silent. Give it a brief grace period before parking.
      var sawUpdate = false;
      final sub = transfer.statusUpdates.listen((_) => sawUpdate = true);
      await Future<void>.delayed(TtsDownloadManager._reattachSilenceGrace);
      await sub.cancel();
      if (!sawUpdate && !_pendingResume) _parkAsInterrupted();
    }
    return transfer.result;
  }

  void _parkAsInterrupted() {
    if (_task.phase == TtsDownloadPhase.interrupted) return;
    _task = _task.copyWith(
      phase: TtsDownloadPhase.interrupted,
      interrupted: true,
    );
    _resumeWait = Completer<void>();
    _manager._emitNow(_task);
  }

  Future<void> _installAuxiliaryFiles(Directory destDir) async {
    _checkCanceled();
    final vocoderUrl = model.vocoderUrl;
    if (vocoderUrl != null) {
      final vocoderFile = File(p.join(destDir.path, model.vocoderFileName!));
      if (!await vocoderFile.exists()) {
        _setPhase(
          TtsDownloadPhase.downloadingAuxiliary,
          fraction: TtsDownloadManager.auxWindowStart,
        );
        final transfer = await _manager._download(
          taskId: '${ttsModelTaskId(model.id)}-vocoder',
          url: vocoderUrl,
          filename: model.vocoderFileName!,
          saveDirectory: destDir,
        );
        _manager._attachTransfers(model.id, [transfer]);

        final progressSub = transfer.progressUpdates.listen((u) {
          _manager._emit(
            _task.copyWith(
              phase: TtsDownloadPhase.downloadingAuxiliary,
              fraction: _auxPhaseFraction(u.progress),
              speedBytesPerSec: u.hasNetworkSpeed
                  ? u.networkSpeed * 1024 * 1024
                  : null,
              timeRemaining: u.hasTimeRemaining ? u.timeRemaining : null,
            ),
          );
        });
        final statusSub = transfer.statusUpdates.listen((u) {
          if (u.status == TaskStatus.paused && _task.phase.isActive) {
            _setPhase(TtsDownloadPhase.paused);
          } else if (u.status == TaskStatus.failed && _task.phase.isActive) {
            _setPhase(
              TtsDownloadPhase.failed,
              errorMessage: u.exception?.description,
            );
          }
        });
        try {
          final result = await _awaitTransferResult(transfer);
          if (result.status == TaskStatus.canceled) throw const _QuietCancel();
          if (result.status != TaskStatus.complete) {
            throw SherpaTtsException(
              'vocoder (${model.vocoderFileName}): '
              '${result.exception?.description ?? result.status.name}',
            );
          }
          await _manager._verifyChecksum(vocoderFile, model.vocoderFileName!);
        } finally {
          await progressSub.cancel();
          await statusSub.cancel();
        }
      }
    }
    if (model.needsEspeakData) {
      await _manager._ensureEspeakData(destDir);
    }
    _checkCanceled();
  }

  Future<void> _finalize() async {
    _checkCanceled();
    _setPhase(
      TtsDownloadPhase.finalizing,
      fraction: TtsDownloadManager.finalizeFraction,
    );

    final checksum = _manager._store.checksumFor(model.archiveFileName);
    final installedModel = model.copyWith(
      installedChecksum: checksum ?? model.installedChecksum,
      installedSizeBytes: (model.approxSizeMb * 1024 * 1024).round(),
      installedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _manager._store.saveInstalledModel(installedModel);

    // Clear any leftover "finished but not finalized" markers.
    final destDir = await _destDir();
    await for (final e in destDir.list()) {
      if (e is File && e.path.endsWith('.done')) {
        try {
          await e.delete();
        } catch (_) {
          // best effort
        }
      }
    }

    _task = _task.copyWith(
      phase: TtsDownloadPhase.done,
      fraction: 1,
      speedBytesPerSec: null,
      timeRemaining: null,
    );
    _manager._emitNow(_task);
  }

  // ---------------------------------------------------------------------
  // Phase + fraction helpers
  // ---------------------------------------------------------------------

  void _checkCanceled() {
    if (_cancelRequested) throw const _QuietCancel();
  }

  void _setPhase(
    TtsDownloadPhase phase, {
    double? fraction,
    String? errorMessage,
  }) {
    _task = _task.copyWith(
      phase: phase,
      fraction: fraction ?? _task.fraction,
      errorMessage: errorMessage ?? _task.errorMessage,
    );
    _manager._emitNow(_task);
  }

  double _archivePhaseFraction(double archiveFraction) {
    final weighted = TtsDownloadManager.archiveWeight * archiveFraction;
    return weighted
        .clamp(0.0, TtsDownloadManager.extractWindowStart)
        .toDouble();
  }

  double _auxPhaseFraction(double auxFraction) {
    final window =
        TtsDownloadManager.auxWindowEnd - TtsDownloadManager.auxWindowStart;
    final weighted = TtsDownloadManager.auxWindowStart + window * auxFraction;
    return weighted
        .clamp(
          TtsDownloadManager.auxWindowStart,
          TtsDownloadManager.auxWindowEnd,
        )
        .toDouble();
  }
}

/// Called by background_downloader when the archive transfer reaches a final
/// state (including app killed + relaunched). Marks the archive as "landed so
/// repair can finish extraction/aux/finalize" — the marker is only removed
/// once the fully-installed model is persisted.
@pragma('vm:entry-point')
Future<void> ttsModelTaskFinished(TaskStatusUpdate update) async {
  await _writeDoneMarker(update.task);
}

Future<void> _writeDoneMarker(Task task) async {
  try {
    final path = await task.filePath();
    final file = File(path);
    if (await file.exists()) {
      await File('$path.done').writeAsString('${task.taskId}\n');
    }
  } catch (_) {
    // Best-effort marker; repair also tolerates a missing marker.
  }
}
