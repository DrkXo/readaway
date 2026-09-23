import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import 'path_service.dart';

class DownloadResult {
  final bool success;
  final File? file;
  final TaskStatus status;
  final String? errorMessage;
  final TaskException? exception;

  const DownloadResult({
    required this.success,
    required this.status,
    this.file,
    this.errorMessage,
    this.exception,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          file?.path == other.file?.path &&
          status == other.status &&
          errorMessage == other.errorMessage);

  @override
  int get hashCode =>
      Object.hash(runtimeType, success, file?.path, status, errorMessage);
}

/// Central service for all background downloads/uploads in the app.
///
/// Registered with `injectable` as a `@lazySingleton`. All file locations
/// default to directories managed by [AppPathService] (resolved via
/// `Task.split`, the pattern the background_downloader package itself
/// recommends for turning an absolute path into a
/// `(BaseDirectory, directory, filename)` triple) so downloads land in the
/// same app-managed storage as everything else in the app, instead of a
/// hardcoded `BaseDirectory.applicationDocuments`.
@lazySingleton
class BackGroundDownloaderService {
  BackGroundDownloaderService(this._appPathService)
    : _downloader = FileDownloader();

  final AppPathService _appPathService;
  final FileDownloader _downloader;

  bool _initialized = false;
  Completer<void>? _initCompleter;

  StreamSubscription<TaskUpdate>? _updatesSub;
  final StreamController<TaskUpdate> _updateController =
      StreamController<TaskUpdate>.broadcast();

  /// Global stream of every status/progress update across all tasks.
  /// Prefer using a [Transfer]'s own notifiers for per-download UI; use this
  /// for app-wide bookkeeping (e.g. a "downloads in progress" badge).
  Stream<TaskUpdate> get updates => _updateController.stream;

  final Map<String, Transfer> _activeTransfers = {};

  // ---------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------

  /// Eagerly run once by injectable during DI setup (`preResolve: true`
  /// makes `getIt.init()` await this before the app continues), so the
  /// downloader is ready before any screen needs it. Also safe to call
  /// again manually — it's idempotent.
  @PostConstruct(preResolve: true)
  Future<void> init() =>
      ensureInitialized(requestNotificationPermission: false);

  /// Idempotent, re-entrant-safe initialization. Safe to call multiple
  /// times/from multiple places; only runs once.
  Future<void> ensureInitialized({
    bool autoCleanDatabase = true,
    bool requestNotificationPermission = true,
  }) async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    final completer = Completer<void>();
    _initCompleter = completer;

    try {
      // Make sure the app's managed downloads folder exists up front.
      await downloadsDirectory;

      // Activates persistent DB tracking + reconciles tasks that finished
      // or were interrupted while the app was suspended/terminated.

      ///TODO: need to figure out if app should automatically start downloads during app start
      // await _downloader.start(autoCleanDatabase: autoCleanDatabase);

      _downloader.configureNotification(
        running: const TaskNotification('Downloading', '{filename}'),
        complete: const TaskNotification('Download complete', '{filename}'),
        error: const TaskNotification('Download failed', '{filename}'),
        paused: const TaskNotification('Paused', '{filename}'),
        canceled: const TaskNotification('Canceled', '{filename}'),
        progressBar: true,
        tapOpensFile: false,
      );

      _updatesSub = _downloader.updates.listen(
        _updateController.add,
        onError: (Object e, StackTrace st) {
          debugPrint('BackGroundDownloaderService: update stream error: $e');
        },
      );

      if (requestNotificationPermission) {
        await _ensurePermission(PermissionType.notifications);
      }

      _initialized = true;
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      _initCompleter = null; // allow retry on next call
      rethrow;
    }
  }

  Future<PermissionStatus> _ensurePermission(PermissionType type) async {
    var status = await _downloader.permissions.status(type);
    if (status != PermissionStatus.granted) {
      status = await _downloader.permissions.request(type);
    }
    return status;
  }

  /// Explicitly request a permission (e.g. androidSharedStorage,
  /// iosAddToPhotoLibrary) ahead of an operation that needs it.
  Future<PermissionStatus> requestPermission(PermissionType type) =>
      _ensurePermission(type);

  // ---------------------------------------------------------------------
  // App-wide callback registration (alternative to [updates] stream)
  // ---------------------------------------------------------------------

  /// Registers callbacks fired for every task in [group] (the default
  /// group if omitted) as they change status/progress — a callback-style
  /// alternative to listening to [updates], scoped per group. Handy if
  /// different groups of tasks (e.g. "avatars" vs "documents") need
  /// different handling logic.
  ///
  /// These run on the main isolate and only fire while this app process
  /// is alive, same as [updates] — for a callback that survives the app
  /// being killed and relaunched, use the `onTaskFinished` parameter on
  /// [download]/[upload] instead (backed by `TaskOptions.onTaskFinished`,
  /// which requires a top-level/static function).
  void registerGroupCallbacks({
    String? group,
    TaskStatusCallback? onStatus,
    TaskProgressCallback? onProgress,
    TaskNotificationTapCallback? onNotificationTap,
  }) {
    _downloader.registerCallbacks(
      group: group ?? FileDownloader.defaultGroup,
      taskStatusCallback: onStatus,
      taskProgressCallback: onProgress,
      taskNotificationTapCallback: onNotificationTap,
    );
  }

  // ---------------------------------------------------------------------
  // App-managed storage locations
  // ---------------------------------------------------------------------

  Directory? _downloadsDir;

  /// Directory where downloaded files land by default: `<app>/downloads`.
  /// Follows the same pattern as [AppPathService]'s other subdirectory
  /// getters.
  Future<Directory> get downloadsDirectory async {
    if (_downloadsDir != null) return _downloadsDir!;
    final app = await _appPathService.appDirectory;
    final dir = Directory(p.join(app.path, 'downloads'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _downloadsDir = dir;
  }

  /// Resolves an absolute [directory] + [filename] into the
  /// `(BaseDirectory, directory, filename)` triple background_downloader's
  /// tasks need, using the package's own `Task.split` helper. This is how
  /// any [AppPathService] directory (covers, tts models, custom fonts,
  /// etc.) is made to work with `DownloadTask`/`UploadTask`, which only
  /// accept a [BaseDirectory] enum value plus a relative subpath.
  Future<(BaseDirectory, String, String)> _splitLocation(
    Directory directory,
    String filename,
  ) => Task.split(filePath: p.join(directory.path, filename));

  // ---------------------------------------------------------------------
  // Downloads
  // ---------------------------------------------------------------------

  /// Starts (or reattaches to an already-running/completed) download using
  /// the Transfer API. Returns a [Transfer] handle with reactive notifiers
  /// and awaitable futures (`transfer.result`, `transfer.file`).
  ///
  /// By default the file is saved under [downloadsDirectory]. Pass
  /// [saveDirectory] to target a different [AppPathService] location (e.g.
  /// `appPathService.getCoversDirectory()`), or pass [baseDirectory]
  /// directly for advanced/legacy use.
  ///
  /// Set [userInitiated] for user-triggered, high-priority downloads that
  /// should survive Android's 9-minute WorkManager cycle and use Android
  /// 14+ UIDT. Set [largeFile] for big files that should be pausable/
  /// resumable without necessarily being top priority.
  Future<Transfer> download({
    String? taskId,
    required String url,
    Map<String, String>? urlQueryParameters,
    required String filename,
    Map<String, String> headers = const {},
    String? httpRequestMethod,
    Directory? saveDirectory,
    String? directory,
    BaseDirectory? baseDirectory,
    String group = 'default',
    bool requiresWiFi = false,
    int retries = 3,
    int? priority,
    String metaData = '',
    String displayName = '',
    TaskOptions? options,
    TaskNotificationConfig? notificationConfig,
    bool userInitiated = false,
    bool largeFile = false,
    bool useSuggestedFilename = false,
    Duration stallTimeout = const Duration(seconds: 30),
    void Function(double progress)? onProgress,
    void Function(TaskStatus status)? onStatus,

    /// Called when this task reaches a final state, *including if the app
    /// was killed and relaunched* while it was running — unlike
    /// [onStatus]/[onProgress] above, which only fire while this app
    /// process is alive.
    ///
    /// Must be a top-level or static function (not a closure) annotated
    /// with `@pragma('vm:entry-point')`, since it can be invoked from
    /// native/background code. Ignored if you pass [options] yourself —
    /// set `TaskOptions(onTaskFinished: ...)` there instead in that case.
    OnTaskFinishedCallback? onTaskFinished,
  }) async {
    await ensureInitialized();
    await _ensurePermission(PermissionType.notifications);

    final resolvedOptions =
        options ??
        (onTaskFinished != null
            ? TaskOptions(onTaskFinished: onTaskFinished)
            : null);

    final requestedFilename = useSuggestedFilename ? '?' : filename;

    String resolvedFilename;
    String resolvedDirectory;
    BaseDirectory resolvedBaseDirectory;

    if (baseDirectory != null) {
      // Advanced/legacy path: caller specified the BaseDirectory directly.
      resolvedBaseDirectory = baseDirectory;
      resolvedDirectory = directory ?? '';
      resolvedFilename = requestedFilename;
    } else {
      // Default path: resolve via AppPathService storage.
      final dir = saveDirectory ?? await downloadsDirectory;
      final split = await _splitLocation(
        dir,
        useSuggestedFilename ? filename : requestedFilename,
      );
      resolvedBaseDirectory = split.$1;
      resolvedDirectory = split.$2;
      resolvedFilename = useSuggestedFilename ? '?' : split.$3;
    }

    final hints = <TransferHint>{
      if (userInitiated) TransferHint.userInitiated,
      if (largeFile) TransferHint.largeFile,
      if (useSuggestedFilename) TransferHint.useSuggestedFilename,
    };

    final task = DownloadTask(
      taskId: taskId,
      url: url,
      urlQueryParameters: urlQueryParameters,
      filename: resolvedFilename,
      headers: headers,
      httpRequestMethod: httpRequestMethod,
      directory: resolvedDirectory,
      baseDirectory: resolvedBaseDirectory,
      group: group,
      updates: Updates.statusAndProgress,
      requiresWiFi: requiresWiFi,
      retries: retries,
      // priority: 0 activates Android 14+ UIDT; leave null to let the
      // TransferHint below pick a sensible default (0 for userInitiated,
      // 5 otherwise) unless the caller overrides it explicitly.
      priority: priority ?? (userInitiated ? 0 : 5),
      metaData: metaData,
      displayName: displayName,
      options: resolvedOptions,
      notificationConfig: notificationConfig,
      allowPause: userInitiated || largeFile,
      stallTimeout: stallTimeout,
      transferHints: hints,
    );

    // getOrStart avoids duplicate enqueues if this is called again for the
    // same logical download (e.g. on a screen rebuild).
    final transfer = await _downloader.transfers.getOrStart(task);
    _activeTransfers[transfer.task.taskId] = transfer;

    if (onProgress != null) {
      transfer.progressNotifier.addListener(() {
        final progress = transfer.progressNotifier.value;
        if (progress != null) onProgress(progress);
      });
    }
    if (onStatus != null) {
      transfer.statusNotifier.addListener(() {
        onStatus(transfer.statusNotifier.value);
      });
    }

    return transfer;
  }

  /// Convenience one-shot download: starts the transfer and awaits its
  /// final result, returning a simple [DownloadResult] instead of a
  /// [Transfer] handle. Good for "download this one file and use it now"
  /// flows (e.g. downloading a PDF to preview). Saves under
  /// [downloadsDirectory] unless [saveDirectory] is given.
  Future<DownloadResult> downloadAndWait({
    required String url,
    required String filename,
    Directory? saveDirectory,
    Map<String, String> headers = const {},
    bool userInitiated = true,
  }) async {
    try {
      final transfer = await download(
        url: url,
        filename: filename,
        saveDirectory: saveDirectory,
        headers: headers,
        userInitiated: userInitiated,
      );

      final result = await transfer.result;

      if (result.status == TaskStatus.complete) {
        final file = await transfer.file;
        return DownloadResult(
          success: true,
          status: result.status,
          file: file,
        );
      }

      return DownloadResult(
        success: false,
        status: result.status,
        errorMessage: result.exception?.description ?? result.status.name,
        exception: result.exception,
      );
    } on TaskException catch (e) {
      return DownloadResult(
        success: false,
        status: TaskStatus.failed,
        errorMessage: e.description,
        exception: e,
      );
    } catch (e) {
      return DownloadResult(
        success: false,
        status: TaskStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Batch-download many files at once with aggregate progress. Build the
  /// tasks yourself (e.g. via repeated calls that construct `DownloadTask`
  /// using [_splitLocation] if you need AppPathService-resolved paths for
  /// each one) since a batch may target different subdirectories.
  Future<List<Transfer>> downloadAll(
    List<DownloadTask> tasks, {
    void Function(int succeeded, int failed)? onProgress,
  }) async {
    await ensureInitialized();
    await _ensurePermission(PermissionType.notifications);
    final transfers = await _downloader.transfers.startAll(
      tasks,
      onProgress: onProgress,
    );
    for (final t in transfers) {
      _activeTransfers[t.task.taskId] = t;
    }
    return transfers;
  }

  // ---------------------------------------------------------------------
  // Uploads
  // ---------------------------------------------------------------------

  /// Low-level upload where the file must already sit at [directory] +
  /// [filename] under [baseDirectory]. Prefer [uploadFile] if you have an
  /// absolute path (from a picker, or an [AppPathService] directory).
  Future<Transfer> upload({
    String? taskId,
    required String url,
    Map<String, String>? urlQueryParameters,
    required String filename,
    Map<String, String> headers = const {},
    String? httpRequestMethod,

    /// Set to `'binary'` to upload the raw file bytes directly instead of
    /// multipart/form-data. Ignored if [binary] is also true (in which
    /// case [TransferHint.binaryUpload] sets this for you).
    String? post,
    String fileField = 'file',
    String? mimeType,
    Map<String, String>? fields,
    String directory = '',
    BaseDirectory baseDirectory = BaseDirectory.applicationDocuments,
    String group = 'default',
    Updates updates = Updates.status,
    bool requiresWiFi = false,
    int retries = 0,
    int priority = 5,
    String metaData = '',
    String displayName = '',
    TaskOptions? options,
    TaskNotificationConfig? notificationConfig,
    Duration? stallTimeout,
    bool binary = false,
    bool userInitiated = true,

    /// See [download]'s parameter of the same name — must be a top-level
    /// or static function, not a closure. Ignored if [options] is set.
    OnTaskFinishedCallback? onTaskFinished,
  }) async {
    await ensureInitialized();

    final resolvedOptions =
        options ??
        (onTaskFinished != null
            ? TaskOptions(onTaskFinished: onTaskFinished)
            : null);

    final task = UploadTask(
      taskId: taskId,
      url: url,
      urlQueryParameters: urlQueryParameters,
      filename: filename,
      headers: headers,
      httpRequestMethod: httpRequestMethod,
      post: post,
      fileField: fileField,
      mimeType: mimeType,
      fields: fields,
      directory: directory,
      baseDirectory: baseDirectory,
      group: group,
      updates: updates,
      requiresWiFi: requiresWiFi,
      retries: retries,
      priority: priority,
      metaData: metaData,
      displayName: displayName,
      options: resolvedOptions,
      notificationConfig: notificationConfig,
      stallTimeout: stallTimeout,
      transferHints: {
        if (userInitiated) TransferHint.userInitiated,
        if (binary) TransferHint.binaryUpload,
      },
    );

    final transfer = await _downloader.transfers.start(task);
    _activeTransfers[transfer.task.taskId] = transfer;
    return transfer;
  }

  /// Convenience for uploading a file you already have an absolute path to
  /// — e.g. from an image/file picker, or any [AppPathService] directory
  /// such as `appPathService.getCoversDirectory()`.
  ///
  /// Uses `Task.split` to decompose [filePath] into (baseDirectory,
  /// directory, filename) as recommended by the package, then delegates to
  /// [upload]. Avoids `UploadTask.fromFile`, which the package docs note
  /// can be fragile on mobile since it pins `BaseDirectory.root`.
  Future<Transfer> uploadFile({
    required String filePath,
    required String url,
    Map<String, String>? fields,
    Map<String, String> headers = const {},
    String fileField = 'file',
    String? mimeType,
    bool binary = false,
    String group = 'default',
  }) async {
    final (baseDirectory, directory, filename) = await Task.split(
      filePath: filePath,
    );
    return upload(
      url: url,
      filename: filename,
      directory: directory,
      baseDirectory: baseDirectory,
      fields: fields,
      headers: headers,
      fileField: fileField,
      mimeType: mimeType,
      binary: binary,
      group: group,
    );
  }

  // ---------------------------------------------------------------------
  // Control (pause / resume / cancel)
  // ---------------------------------------------------------------------

  Transfer? _lookup(String taskId) =>
      _activeTransfers[taskId] ?? _downloader.transfers.forId(taskId);

  Future<void> pause(String taskId) async => _lookup(taskId)?.pause();

  Future<void> resume(String taskId) async => _lookup(taskId)?.resume();

  Future<void> cancel(String taskId) async {
    await _lookup(taskId)?.cancel();
    _activeTransfers.remove(taskId);
  }

  /// Cancels every active transfer in [group] (default: all groups).
  Future<void> cancelAll({String? group}) async {
    final targets = _downloader.transfers
        .active()
        .where((t) => group == null || t.task.group == group)
        .toList();
    await Future.wait(targets.map((t) => t.cancel()));
    _activeTransfers.removeWhere(
      (_, t) => group == null || t.task.group == group,
    );
  }

  /// Overrides a WiFi-only hold, allowing this transfer to proceed on
  /// cellular data.
  Future<void> allowCellular(String taskId) async =>
      _lookup(taskId)?.allowCellular();

  // ---------------------------------------------------------------------
  // Queries
  // ---------------------------------------------------------------------

  List<Transfer> all() => _downloader.transfers.all();
  List<Transfer> active() => _downloader.transfers.active();
  List<Transfer> completed() => _downloader.transfers.completed();

  Transfer? forId(String taskId) => _downloader.transfers.forId(taskId);
  Transfer? forUrl(String url) => _downloader.transfers.forUrl(url);

  ValueListenable<List<Transfer>> get notifier =>
      _downloader.transfers.notifier;

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  /// Called automatically by `get_it`/`injectable` when this singleton's
  /// scope is disposed (implements `Disposable`). Rarely relevant for an
  /// app-lifetime singleton, but keeps teardown clean in tests or scoped
  /// features.
  @disposeMethod
  Future<void> onDispose() async {
    await _updatesSub?.cancel();
    if (!_updateController.isClosed) {
      await _updateController.close();
    }
    _activeTransfers.clear();
  }
}
