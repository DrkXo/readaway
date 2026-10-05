import 'package:flutter/material.dart';

import 'primitives/settings_section.dart';

/// Shared per-book scope state for the settings sheet.
///
/// Provided by [SettingsPage] and read by [ScopedSettingsSection]. It carries
/// the document the sheet was opened for (if any) plus the current scope flag
/// and how to change it, so every settings group can label itself and expose a
/// per-book toggle without each panel owning its own state.
class SettingsScopeControl extends InheritedWidget {
  const SettingsScopeControl({
    super.key,
    required this.bookPath,
    required this.scoped,
    required this.onScopedChanged,
    required super.child,
  });

  /// The document the sheet was opened for, or null when opened from the
  /// library (global settings only).
  final String? bookPath;

  /// Whether reader-preference groups currently edit this book (true) or the
  /// global preferences (false).
  final bool scoped;

  final ValueChanged<bool> onScopedChanged;

  static SettingsScopeControl? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SettingsScopeControl>();
  }

  @override
  bool updateShouldNotify(SettingsScopeControl oldWidget) {
    return bookPath != oldWidget.bookPath ||
        scoped != oldWidget.scoped ||
        onScopedChanged != oldWidget.onScopedChanged;
  }
}

/// A settings group that communicates whether its content is scoped per book.
///
/// Wraps a [SettingsSection] and, when the sheet was opened from a reader,
/// adds a scope chip ("This book" / "All books"). Groups that are always
/// global pass `scopable: false` and get an "All books" chip.
class ScopedSettingsSection extends StatelessWidget {
  const ScopedSettingsSection({
    super.key,
    this.title,
    this.scopable = true,
    this.trailing,
    this.onReset,
    required this.rows,
  });

  final String? title;

  /// Whether this group's settings live on [ReaderPreferences] and can
  /// therefore be overridden per book. Global-only groups (appearance theme,
  /// TTS, navigation, caches, ...) pass false.
  final bool scopable;

  final Widget? trailing;
  final VoidCallback? onReset;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final control = SettingsScopeControl.maybeOf(context);
    final openedFromBook = control?.bookPath != null;
    final scoped = control?.scoped ?? false;

    return SettingsSection(
      title: title,
      // No scope UI when the sheet was opened globally.
      scope: !openedFromBook
          ? null
          : (scopable
                ? (scoped ? SettingsScope.perBook : SettingsScope.global)
                : SettingsScope.global),
      trailing: trailing,
      onReset: onReset,
      rows: rows,
    );
  }
}
