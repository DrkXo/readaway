import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:readaway_core/readaway_core.dart';
import 'package:rxdart/rxdart.dart';
import 'package:window_manager/window_manager.dart';

import '../../../flavors.dart';
import 'audio/audio_player_service.dart';

@Singleton()
class WindowService with WindowListener {
  final _log = AppLogger.instance.scope('WindowService');

  WindowManager get _wm => WindowManager.instance;

  final BehaviorSubject<bool> _maximizedSubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<String> _titleSubject =
      BehaviorSubject<String>.seeded(F.title);

  Stream<bool> get windowMaximizeChanges => _maximizedSubject.stream;
  Stream<String> get windowTitleChanges => _titleSubject.stream;
  String get currentTitle => _titleSubject.value;

  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  bool _initialized = false;
  bool _isShuttingDown = false;

  @PostConstruct(preResolve: true)
  Future<void> initialize() async {
    if (!isDesktop || _initialized) return;
    _initialized = true;
    await _wm.ensureInitialized();

    const options = WindowOptions(
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    _wm.waitUntilReadyToShow(options, () async {
      await _wm.show();
      await _wm.focus();
    });

    await setDefaultTitle();
    _wm.addListener(this);
    await _wm.setPreventClose(true);
  }

  Future<void> setDefaultTitle() async {
    if (!isDesktop) return;
    await _wm.setTitle(F.title);
    if (!_titleSubject.isClosed) _titleSubject.add(F.title);
  }

  Future<void> setTitle(String title) async {
    if (!isDesktop) return;
    await _wm.setTitle(title);
    if (!_titleSubject.isClosed) _titleSubject.add(title);
  }

  Future<void> startDragging() async {
    if (!isDesktop) return;
    await _wm.startDragging();
  }

  Future<void> minimize() async {
    if (!isDesktop) return;
    await _wm.minimize();
  }

  Future<void> maximize() async {
    if (!isDesktop) return;
    await _wm.maximize();
  }

  Future<void> unmaximize() async {
    if (!isDesktop) return;
    await _wm.unmaximize();
  }

  Future<void> toggleMaximize() async {
    if (!isDesktop) return;
    if (await isMaximized()) {
      await unmaximize();
    } else {
      await maximize();
    }
  }

  Future<bool> isMaximized() async {
    if (!isDesktop) return false;
    final result = await _wm.isMaximized();
    if (!_maximizedSubject.isClosed) _maximizedSubject.add(result);
    return result;
  }

  Future<void> close() async {
    if (!isDesktop) return;
    await onWindowClose();
  }

  @override
  void onWindowMaximize() {
    if (!_maximizedSubject.isClosed) _maximizedSubject.add(true);
  }

  @override
  void onWindowUnmaximize() {
    if (!_maximizedSubject.isClosed) _maximizedSubject.add(false);
  }

  @override
  void onWindowRestore() {
    if (!_maximizedSubject.isClosed) _maximizedSubject.add(false);
  }

  @override
  Future<void> onWindowClose() async {
    if (!isDesktop || _isShuttingDown) return;
    _isShuttingDown = true;
    // Release audio session before the window disappears
    try {
      await audioPlayerService.shutdown();
    } catch (e, st) {
      _log.w(
        'Error shutting down audio on window close: $e',
        error: e,
        stackTrace: st,
      );
    }
    try {
      if (isDesktop && _wm.hasListeners) {
        _wm.removeListener(this);
      }
    } catch (e, st) {
      _log.w('Error removing window listener: $e', error: e, stackTrace: st);
    } finally {
      if (Platform.isLinux) {
        await _wm.setPreventClose(false);
        await _wm.close();
      } else {
        await _wm.destroy();
      }
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    if (isDesktop && _wm.hasListeners) {
      _wm.removeListener(this);
    }
    await _maximizedSubject.close();
    await _titleSubject.close();
  }
}
