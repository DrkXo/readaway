import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/services.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../bloc/settings/settings_bloc.dart';
import '../widgets/reader_prefs_scope.dart';
import '../widgets/settings_bloc_x.dart';
import '../widgets/widgets.dart';

enum SettingsTab { font, layout, behavior, appearance, tts }

class SettingsPage extends StatefulWidget {
  final SettingsTab initialTab;

  /// When set, the settings sheet edits this document's per-book preferences
  /// (with a toggle to fall back to the global preferences).
  final String? documentPath;

  const SettingsPage({
    super.key,
    this.initialTab = SettingsTab.font,
    this.documentPath,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Whether the reader-preference groups are editing this book's per-book
  /// preferences (true) or the global preferences (false).
  late bool _scoped;
  late final MetroPivotController _pivotController;

  @override
  void initState() {
    super.initState();
    _pivotController = MetroPivotController(
      length: 5,
      initialIndex: widget.initialTab.index,
    );
    final path = widget.documentPath;
    final settingsBloc = context.read<SettingsBloc>();
    _scoped =
        path != null &&
        settingsBloc.state.documentReaderPrefs.containsKey(path);
    if (path != null &&
        !settingsBloc.state.loadedDocumentPaths.contains(path)) {
      context.read<SettingsBloc>().add(
        SettingsEvent.loadDocumentPrefs(path),
      );
    }
  }

  @override
  void didUpdateWidget(SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        _pivotController.index != widget.initialTab.index) {
      _pivotController.animateTo(widget.initialTab.index);
    }
  }

  @override
  void dispose() {
    _pivotController.dispose();
    super.dispose();
  }

  void _syncScoped(SettingsState state) {
    final path = widget.documentPath;
    if (path == null || !state.loadedDocumentPaths.contains(path)) return;
    final enabled = state.documentReaderPrefs.containsKey(path);
    if (_scoped != enabled) setState(() => _scoped = enabled);
  }

  void _setScoped(bool enabled) {
    final path = widget.documentPath;
    if (path == null) return;
    final bloc = context.read<SettingsBloc>();
    if (enabled) {
      // Create the override starting from the current global preferences.
      bloc.updateDocumentReaderPrefs(path, (p) => p);
    } else {
      bloc.clearDocumentReaderPrefs(path);
    }
    setState(() => _scoped = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.documentPath;
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: appColors.readerBackground,
      body: SafeArea(
        child: BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (previous, current) =>
              previous.failure != current.failure ||
              previous.loadedDocumentPaths != current.loadedDocumentPaths,
          listener: (context, state) {
            _syncScoped(state);
            if (state.failure case final failure?) {
              context.toasts.showFailure(failure);
            }
          },
          child: SettingsScopeControl(
            bookPath: path,
            scoped: _scoped,
            onScopedChanged: _setScoped,
            child: ReaderPrefsScope(
              documentPath: _scoped ? path : null,
              child: Column(
                children: [
                  if (path != null)
                    _BookScopeBanner(
                      scoped: _scoped,
                      onChanged: _setScoped,
                    ),
                  Expanded(
                    child: MetroPivot(
                      controller: _pivotController,
                      title: 'settings',
                      trailing: const SettingsSheetCloseButton(useText: true),
                      items: const [
                        MetroPivotItem(
                          label: 'font',
                          content: SettingsFontPanel(),
                        ),
                        MetroPivotItem(
                          label: 'layout',
                          content: SettingsLayoutPanel(),
                        ),
                        MetroPivotItem(
                          label: 'behavior',
                          content: SettingsBehaviorPanel(),
                        ),
                        MetroPivotItem(
                          label: 'appearance',
                          content: SettingsAppearancePanel(),
                        ),
                        MetroPivotItem(
                          label: 'tts',
                          content: SettingsTtsPanel(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner shown when the settings sheet is opened from a reader, letting the
/// user choose between editing this book's preferences or the global ones.
class _BookScopeBanner extends StatelessWidget {
  final bool scoped;
  final ValueChanged<bool> onChanged;

  const _BookScopeBanner({
    required this.scoped,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: appColors.readerForeground.withValues(alpha: 0.04),
        border: Border(
          left: BorderSide(
            color: scoped
                ? appColors.buttonBackground
                : appColors.readerForeground.withValues(alpha: 0.3),
            width: 3.5,
          ),
          top: BorderSide(
            color: appColors.readerForeground.withValues(alpha: 0.08),
            width: 1,
          ),
          right: BorderSide(
            color: appColors.readerForeground.withValues(alpha: 0.08),
            width: 1,
          ),
          bottom: BorderSide(
            color: appColors.readerForeground.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.bookOpen,
            size: 18,
            color: scoped
                ? appColors.buttonBackground
                : appColors.readerForeground.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'customize this book',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: appColors.readerForeground,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  scoped
                      ? 'Settings apply to this book only'
                      : 'Settings apply to all books',
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.readerForeground.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: scoped
                ? 'Editing only this book — toggle to edit all books'
                : 'Editing all books — toggle to edit only this book',
            child: Semantics(
              label: 'Customize settings for this book',
              child: MetroSwitch(
                value: scoped,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
