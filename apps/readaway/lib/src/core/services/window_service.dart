part of 'services.dart';

@Singleton()
class WindowService with WindowListener {
  WindowManager get _wm => WindowManager.instance;

  final PublishSubject<void> _closeSubject = PublishSubject<void>();
  final PublishSubject<Size> _resizeSubject = PublishSubject<Size>();
  final PublishSubject<Offset> _moveSubject = PublishSubject<Offset>();
  final PublishSubject<bool> _maximizeSubject = PublishSubject<bool>();
  final PublishSubject<bool> _minimizeSubject = PublishSubject<bool>();
  final PublishSubject<bool> _focusSubject = PublishSubject<bool>();
  final PublishSubject<bool> _fullScreenSubject = PublishSubject<bool>();

  final BehaviorSubject<Size> _sizeSubject = BehaviorSubject<Size>.seeded(
    Size.zero,
  );
  final BehaviorSubject<Offset> _positionSubject =
      BehaviorSubject<Offset>.seeded(Offset.zero);
  final BehaviorSubject<bool> _maximizedSubject = BehaviorSubject<bool>.seeded(
    false,
  );
  final BehaviorSubject<bool> _minimizedSubject = BehaviorSubject<bool>.seeded(
    false,
  );
  final BehaviorSubject<bool> _focusedSubject = BehaviorSubject<bool>.seeded(
    false,
  );
  final BehaviorSubject<bool> _fullScreenSubjectState =
      BehaviorSubject<bool>.seeded(false);

  Stream<void> get windowClose => _closeSubject.stream;
  Stream<Size> get windowResize => _resizeSubject.stream;
  Stream<Offset> get windowMove => _moveSubject.stream;
  Stream<bool> get windowMaximize => _maximizeSubject.stream;
  Stream<bool> get windowMinimize => _minimizeSubject.stream;
  Stream<bool> get windowFocus => _focusSubject.stream;
  Stream<bool> get windowFullScreen => _fullScreenSubject.stream;

  Stream<Size> get windowSizeChanges => _sizeSubject.stream;
  Stream<Offset> get windowPositionChanges => _positionSubject.stream;
  Stream<bool> get windowMaximizeChanges => _maximizedSubject.stream;
  Stream<bool> get windowMinimizeChanges => _minimizedSubject.stream;
  Stream<bool> get windowFocusChanges => _focusedSubject.stream;
  Stream<bool> get windowFullScreenChanges => _fullScreenSubjectState.stream;

  Stream<WindowState> get windowStateChanges => Rx.combineLatest7(
    _sizeSubject,
    _positionSubject,
    _maximizedSubject,
    _minimizedSubject,
    _focusedSubject,
    _fullScreenSubjectState,
    _closeSubject,
    (size, position, maximized, minimized, focused, fullScreen, _) =>
        WindowState(
          size: size,
          position: position,
          isMaximized: maximized,
          isMinimized: minimized,
          isFocused: focused,
          isFullScreen: fullScreen,
        ),
  ).shareValue();

  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  bool get _isInitialized => _sizeSubject.hasValue;

  @PostConstruct(preResolve: true)
  Future<void> initialize() async {
    if (!isDesktop || _isInitialized) return;
    await _wm.ensureInitialized();
    await setDefaultTitle();
    _wm.addListener(this);
  }

  Future<void> setDefaultTitle() async {
    if (!isDesktop) return;
    await _wm.setTitle(F.title);
  }

  Future<void> setTitle(String title) async {
    if (!isDesktop) return;
    await _wm.setTitle(title);
  }

  Future<void> setSize(Size size, {bool animate = false}) async {
    if (!isDesktop) return;
    await _wm.setSize(size, animate: animate);
  }

  Future<Size> getSize() async {
    if (!isDesktop) return Size.zero;
    final size = await _wm.getSize();
    if (!_sizeSubject.isClosed) _sizeSubject.add(size);
    return size;
  }

  Future<void> setMinimumSize(Size size) async {
    if (!isDesktop) return;
    await _wm.setMinimumSize(size);
  }

  Future<void> setMaximumSize(Size size) async {
    if (!isDesktop) return;
    await _wm.setMaximumSize(size);
  }

  Future<void> center({bool animate = false}) async {
    if (!isDesktop) return;
    await _wm.center(animate: animate);
  }

  Future<void> setPosition(Offset position, {bool animate = false}) async {
    if (!isDesktop) return;
    await _wm.setPosition(position, animate: animate);
  }

  Future<Offset> getPosition() async {
    if (!isDesktop) return Offset.zero;
    final position = await _wm.getPosition();
    if (!_positionSubject.isClosed) _positionSubject.add(position);
    return position;
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

  Future<void> restore() async {
    if (!isDesktop) return;
    await _wm.restore();
  }

  Future<void> close() async {
    if (!isDesktop) return;
    await _wm.close();
  }

  Future<void> destroy() async {
    if (!isDesktop) return;
    await _wm.destroy();
  }

  Future<void> setFullScreen(bool isFullScreen) async {
    if (!isDesktop) return;
    await _wm.setFullScreen(isFullScreen);
  }

  Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async {
    if (!isDesktop) return;
    await _wm.setAlwaysOnTop(isAlwaysOnTop);
  }

  Future<void> setOpacity(double opacity) async {
    if (!isDesktop) return;
    await _wm.setOpacity(opacity);
  }

  Future<void> setBackgroundColor(Color backgroundColor) async {
    if (!isDesktop) return;
    await _wm.setBackgroundColor(backgroundColor);
  }

  Future<void> setTitleBarStyle(
    TitleBarStyle titleBarStyle, {
    bool windowButtonVisibility = true,
  }) async {
    if (!isDesktop) return;
    await _wm.setTitleBarStyle(
      titleBarStyle,
      windowButtonVisibility: windowButtonVisibility,
    );
  }

  Future<void> setResizable(bool resizable) async {
    if (!isDesktop) return;
    await _wm.setResizable(resizable);
  }

  Future<void> setMovable(bool movable) async {
    if (!isDesktop) return;
    await _wm.setMovable(movable);
  }

  Future<void> setMinimizable(bool minimizable) async {
    if (!isDesktop) return;
    await _wm.setMinimizable(minimizable);
  }

  Future<void> setMaximizable(bool maximizable) async {
    if (!isDesktop) return;
    await _wm.setMaximizable(maximizable);
  }

  Future<void> setClosable(bool closable) async {
    if (!isDesktop) return;
    await _wm.setClosable(closable);
  }

  Future<void> setPreventClose(bool preventClose) async {
    if (!isDesktop) return;
    await _wm.setPreventClose(preventClose);
  }

  Future<bool> isMaximized() async {
    if (!isDesktop) return false;
    final result = await _wm.isMaximized();
    if (!_maximizedSubject.isClosed) _maximizedSubject.add(result);
    return result;
  }

  Future<bool> isMinimized() async {
    if (!isDesktop) return false;
    final result = await _wm.isMinimized();
    if (!_minimizedSubject.isClosed) _minimizedSubject.add(result);
    return result;
  }

  Future<bool> isFullScreen() async {
    if (!isDesktop) return false;
    final result = await _wm.isFullScreen();
    if (!_fullScreenSubjectState.isClosed) {
      _fullScreenSubjectState.add(result);
    }
    return result;
  }

  Future<bool> isFocused() async {
    if (!isDesktop) return false;
    final result = await _wm.isFocused();
    if (!_focusedSubject.isClosed) _focusedSubject.add(result);
    return result;
  }

  Future<bool> isAlwaysOnTop() async {
    if (!isDesktop) return false;
    return _wm.isAlwaysOnTop();
  }

  Future<Rect> getBounds() async {
    if (!isDesktop) return Rect.zero;
    final bounds = await _wm.getBounds();
    if (!_sizeSubject.isClosed) _sizeSubject.add(bounds.size);
    if (!_positionSubject.isClosed) _positionSubject.add(bounds.topLeft);
    return bounds;
  }

  Future<void> setBounds(Rect bounds, {bool animate = false}) async {
    if (!isDesktop) return;
    await _wm.setBounds(bounds, animate: animate);
    if (!_sizeSubject.isClosed) _sizeSubject.add(bounds.size);
    if (!_positionSubject.isClosed) _positionSubject.add(bounds.topLeft);
  }

  Future<void> setAspectRatio(double aspectRatio) async {
    if (!isDesktop) return;
    await _wm.setAspectRatio(aspectRatio);
  }

  Future<void> setIcon(String iconPath) async {
    if (!isDesktop) return;
    await _wm.setIcon(iconPath);
  }

  @override
  void onWindowClose() {
    _closeSubject.add(null);
  }

  @override
  void onWindowResize() {
    _wm.getSize().then((size) {
      if (!_resizeSubject.isClosed) _resizeSubject.add(size);
      if (!_sizeSubject.isClosed) _sizeSubject.add(size);
    });
  }

  @override
  void onWindowMove() {
    _wm.getPosition().then((position) {
      if (!_moveSubject.isClosed) _moveSubject.add(position);
      if (!_positionSubject.isClosed) _positionSubject.add(position);
    });
  }

  @override
  void onWindowMaximize() {
    if (!_maximizeSubject.isClosed) _maximizeSubject.add(true);
    if (!_maximizedSubject.isClosed) _maximizedSubject.add(true);
  }

  @override
  void onWindowUnmaximize() {
    if (!_maximizeSubject.isClosed) _maximizeSubject.add(false);
    if (!_maximizedSubject.isClosed) _maximizedSubject.add(false);
  }

  @override
  void onWindowMinimize() {
    if (!_minimizeSubject.isClosed) _minimizeSubject.add(true);
    if (!_minimizedSubject.isClosed) _minimizedSubject.add(true);
  }

  @override
  void onWindowRestore() {
    if (!_minimizeSubject.isClosed) _minimizeSubject.add(false);
    if (!_minimizedSubject.isClosed) _minimizedSubject.add(false);
  }

  @override
  void onWindowFocus() {
    if (!_focusSubject.isClosed) _focusSubject.add(true);
    if (!_focusedSubject.isClosed) _focusedSubject.add(true);
  }

  @override
  void onWindowBlur() {
    if (!_focusSubject.isClosed) _focusSubject.add(false);
    if (!_focusedSubject.isClosed) _focusedSubject.add(false);
  }

  @override
  void onWindowEnterFullScreen() {
    if (!_fullScreenSubject.isClosed) _fullScreenSubject.add(true);
    if (!_fullScreenSubjectState.isClosed) {
      _fullScreenSubjectState.add(true);
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (!_fullScreenSubject.isClosed) _fullScreenSubject.add(false);
    if (!_fullScreenSubjectState.isClosed) {
      _fullScreenSubjectState.add(false);
    }
  }

  @disposeMethod
  Future<void> dispose() async {
    if (isDesktop && _wm.hasListeners) {
      _wm.removeListener(this);
    }
    await _closeSubject.close();
    await _resizeSubject.close();
    await _moveSubject.close();
    await _maximizeSubject.close();
    await _minimizeSubject.close();
    await _focusSubject.close();
    await _fullScreenSubject.close();
    await _sizeSubject.close();
    await _positionSubject.close();
    await _maximizedSubject.close();
    await _minimizedSubject.close();
    await _focusedSubject.close();
    await _fullScreenSubjectState.close();
  }
}

@immutable
class WindowState {
  final Size size;
  final Offset position;
  final bool isMaximized;
  final bool isMinimized;
  final bool isFocused;
  final bool isFullScreen;

  const WindowState({
    required this.size,
    required this.position,
    required this.isMaximized,
    required this.isMinimized,
    required this.isFocused,
    required this.isFullScreen,
  });

  WindowState copyWith({
    Size? size,
    Offset? position,
    bool? isMaximized,
    bool? isMinimized,
    bool? isFocused,
    bool? isFullScreen,
  }) => WindowState(
    size: size ?? this.size,
    position: position ?? this.position,
    isMaximized: isMaximized ?? this.isMaximized,
    isMinimized: isMinimized ?? this.isMinimized,
    isFocused: isFocused ?? this.isFocused,
    isFullScreen: isFullScreen ?? this.isFullScreen,
  );
}
