import 'package:flutter/widgets.dart';

/// Provides the active document path (nullable) to settings panels so they can
/// edit per-book reader preferences instead of the global ones.
///
/// When [documentPath] is null, panels edit the global preferences.
class ReaderPrefsScope extends InheritedWidget {
  const ReaderPrefsScope({
    super.key,
    required this.documentPath,
    required super.child,
  });

  /// The document whose per-book preferences are being edited, or null to edit
  /// the global preferences.
  final String? documentPath;

  static ReaderPrefsScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ReaderPrefsScope>();
  }

  /// The active document path, or null when editing global preferences.
  static String? documentPathOf(BuildContext context) {
    return maybeOf(context)?.documentPath;
  }

  @override
  bool updateShouldNotify(ReaderPrefsScope oldWidget) {
    return oldWidget.documentPath != documentPath;
  }
}

/// Convenience accessor for the active document path from settings panels.
extension ReaderPrefsScopeContextX on BuildContext {
  /// The document path being edited, or null for global preferences.
  String? readerPrefsDocumentPath() => ReaderPrefsScope.documentPathOf(this);
}
