import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:get_it/get_it.dart';
import 'package:readaway_core/readaway_core.dart';

import '../services/file_open_service.dart';

/// Keeps Readaway down to one Linux process and forwards the document that
/// launched the duplicate over to the instance that is already running.
///
/// Desktop file associations start a *new process* per double-clicked file
/// (`Exec=readaway %F`), so without this every file opened from the file
/// manager spawns a second window — and with it a second isolate, audio
/// session and TTS pipeline — while the first window keeps showing the old
/// book.
///
/// Only Linux is gated: Android and iOS are already single-process, macOS
/// delivers `openFile` through `FileOpenService`'s LaunchServices bridge, and
/// web has no process model to police.
class SingleInstanceBootstrap {
  const SingleInstanceBootstrap._();

  /// Matches `Exec=` in `linux/dev.readaway.desktop`.
  static const _slug = 'readaway';

  static final _log = AppLogger.instance.scope('SingleInstanceBootstrap');

  /// Launch arguments received before dependency injection finished.
  ///
  /// The RPC server starts inside [claim], well before `configureDependencies`
  /// completes — which takes seconds, because it spawns isolates and loads the
  /// TTS model. A duplicate landing in that window reaches [_onFocus] with
  /// `FileOpenService` not yet registered, and the package would still answer
  /// it with `success: true` while the file quietly failed to open. Buffering
  /// those handoffs until DI is ready stops the first seconds of a cold start
  /// from swallowing the file.
  static final List<List<String>> _pendingHandoffs = [];

  /// Claims the single-instance lock before any expensive startup work runs.
  ///
  /// Returns `true` when this process is the primary instance and should carry
  /// on booting. Returns `false` when another instance already owns the lock —
  /// the launch arguments have been handed to it by then, and the caller must
  /// exit without ever calling `runApp`.
  ///
  /// Deliberately runs before dependency injection: a duplicate launch should
  /// not pay for isolate spawn, audio session setup or the TTS model load just
  /// to discover it has nothing to do.
  static Future<bool> claim({required List<String> args}) async {
    if (kIsWeb || !Platform.isLinux) return true;

    FlutterSingleInstance.processName = _instanceName();
    // Otherwise `isFirstInstance()` short-circuits to `true` under the debugger
    // and the handoff can never be exercised locally. Build mode is
    // distinguished by `_instanceName()` instead.
    FlutterSingleInstance.debugMode = false;

    await windowManager.ensureInitialized();

    // Registered before the lock is claimed, not after: claiming starts the RPC
    // server and publishes the pid file, so a duplicate can already reach this
    // callback before `isFirstInstance()` has returned. Harmless in a duplicate
    // process, which never runs a server.
    FlutterSingleInstance.onFocus = _onFocus;

    final instance = FlutterSingleInstance();
    if (await instance.isFirstInstance()) {
      return true;
    }

    // Another process holds the lock. Hand it the file that launched us and
    // let it raise its own window. The package calls `windowManager.focus()`
    // after `onFocus`, so an argument-less duplicate still surfaces the
    // existing window.
    final error = await instance.focus({'args': args});
    if (error != null) {
      _log.w('Failed to hand off to the running instance: $error');
    } else {
      _log.i('Another instance is already running; handed off and exiting.');
    }
    return false;
  }

  /// Runs in the *primary* instance, invoked by the package's RPC server when a
  /// duplicate process forwards its launch arguments.
  static FutureOr<void> _onFocus(Map<String, dynamic> metadata) {
    final rawArgs = metadata['args'];
    if (rawArgs is! List || rawArgs.isEmpty) return null;

    final forwarded = rawArgs.map((arg) => arg.toString()).toList();

    // The RPC server is already listening while DI is still booting, so a
    // duplicate can reach us before the service exists. Buffer instead of
    // dropping; [drainPendingHandoffs] replays once DI is up.
    if (!GetIt.I.isRegistered<FileOpenService>()) {
      _pendingHandoffs.add(forwarded);
      _log.i(
        'Deferring ${forwarded.length} launch arg(s) until services ready',
      );
      return null;
    }

    _open(forwarded);
    return null;
  }

  /// Replays handoffs that arrived before dependency injection was ready.
  ///
  /// Must be called after `configureDependencies()`. Idempotent — the buffer is
  /// drained, so a later call is a no-op.
  static void drainPendingHandoffs() {
    if (_pendingHandoffs.isEmpty) return;
    final buffered = List<List<String>>.of(_pendingHandoffs);
    _pendingHandoffs.clear();
    for (final args in buffered) {
      _log.i('Replaying deferred handoff: ${args.join(' ')}');
      _open(args);
    }
  }

  /// Hands a resolved argument list to the file-open pipeline.
  ///
  /// Reusing `initializeWithArgs` keeps the existing path sanitising, the
  /// file-existence check and the `fromExternalLaunch` flag in one place.
  static void _open(List<String> args) {
    try {
      GetIt.I<FileOpenService>().initializeWithArgs(args);
    } catch (error, stackTrace) {
      // The package wraps `onFocus` in a bare catch and still answers the
      // duplicate with `success: true`, so a throw here would leave the user
      // with a window that did nothing. Log it loudly instead of swallowing it.
      _log.e(
        'Failed to open ${args.first} received from a second launch',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Lock file name, scoped per user and per build mode.
  ///
  /// The package locks `<name>.pid` in `/tmp` on Linux, and treats a failed
  /// lock as "another instance is running" without distinguishing *why* the
  /// lock failed. Two consequences this avoids:
  ///
  /// - `/tmp` is shared by every account, so an unprefixed name would let one
  ///   user's launch silently bail out as "not first instance".
  /// - `getProcessName` resolves the executable basename, so debug and release
  ///   builds would share one lock and refuse to run alongside each other.
  static String _instanceName() {
    final user =
        Platform.environment['USER'] ??
        Platform.environment['LOGNAME'] ??
        'shared';
    final safeUser = user.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
    final build = kDebugMode ? 'debug' : 'release';
    return '$_slug-$safeUser-$build';
  }
}
