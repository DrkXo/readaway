import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/services.dart';
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

  @override
  void initState() {
    super.initState();
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

    return BlocListener<SettingsBloc, SettingsState>(
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
        child: DefaultTabController(
          length: 5,
          initialIndex: widget.initialTab.index,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SettingsSheetHeader(
                title: 'Settings',
                trailing: SettingsSheetCloseButton(),
              ),

              if (path != null)
                _BookScopeBanner(
                  scoped: _scoped,
                  onChanged: _setScoped,
                ),

              const TabBar(
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: EdgeInsets.symmetric(horizontal: 6),
                tabs: [
                  Tab(
                    icon: Icon(LucideIcons.type, size: 18),
                    text: 'Font',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.space, size: 18),
                    text: 'Layout',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.hand, size: 18),
                    text: 'Behavior',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.palette, size: 18),
                    text: 'Appearance',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.mic, size: 18),
                    text: 'TTS',
                  ),
                ],
              ),

              Flexible(
                child: ReaderPrefsScope(
                  documentPath: _scoped ? path : null,
                  child: const TabBarView(
                    children: [
                      SettingsFontPanel(),
                      SettingsLayoutPanel(),
                      SettingsBehaviorPanel(),
                      SettingsAppearancePanel(),
                      SettingsTtsPanel(),
                    ],
                  ),
                ),
              ),
            ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scoped
            ? scheme.secondaryContainer.withValues(alpha: 0.3)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scoped
              ? scheme.secondary.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.bookOpen,
            size: 18,
            color: scoped ? scheme.secondary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Customize this book',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  scoped
                      ? 'Settings apply to this book only'
                      : 'Settings apply to all books',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: scoped
                ? 'Editing only this book — toggle to edit all books'
                : 'Editing all books — toggle to edit only this book',
            child: Transform.scale(
              scale: 0.8,
              alignment: Alignment.centerRight,
              child: Semantics(
                label: 'Customize settings for this book',
                child: Switch(
                  value: scoped,
                  onChanged: onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
