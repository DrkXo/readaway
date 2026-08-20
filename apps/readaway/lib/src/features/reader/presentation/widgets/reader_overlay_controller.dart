import 'package:flutter/material.dart';

enum ReaderBarVisibility { visible, hidden, topOnly, bottomOnly }

class ReaderOverlayController extends ChangeNotifier {
  ReaderBarVisibility _visibility = ReaderBarVisibility.visible;
  bool _statusBarVisible = true;

  ReaderBarVisibility get visibility => _visibility;
  bool get statusBarVisible => _statusBarVisible;
  bool get barsVisible => _visibility == ReaderBarVisibility.visible;

  void toggleBars() {
    switch (_visibility) {
      case ReaderBarVisibility.visible:
        _visibility = ReaderBarVisibility.hidden;
      case ReaderBarVisibility.hidden:
        _visibility = ReaderBarVisibility.visible;
      case ReaderBarVisibility.topOnly:
        _visibility = ReaderBarVisibility.hidden;
      case ReaderBarVisibility.bottomOnly:
        _visibility = ReaderBarVisibility.visible;
    }
    notifyListeners();
  }

  void showBars() {
    _visibility = ReaderBarVisibility.visible;
    notifyListeners();
  }

  void hideBars() {
    _visibility = ReaderBarVisibility.hidden;
    notifyListeners();
  }

  void showTopOnly() {
    _visibility = ReaderBarVisibility.topOnly;
    notifyListeners();
  }

  void showBottomOnly() {
    _visibility = ReaderBarVisibility.bottomOnly;
    notifyListeners();
  }

  void toggleStatusBar() {
    _statusBarVisible = !_statusBarVisible;
    notifyListeners();
  }

  void setStatusBarVisible(bool visible) {
    _statusBarVisible = visible;
    notifyListeners();
  }
}
