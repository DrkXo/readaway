import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  /// Whether the panels are editing this book's per-book preferences (true)
  /// or the global preferences (false).
  late bool _perBookMode;

  @override
  void initState() {
    super.initState();
    final path = widget.documentPath;
    _perBookMode =
        path != null &&
        context.read<SettingsBloc>().state.documentReaderPrefs.containsKey(
          path,
        );
  }

  void _setPerBookMode(bool enabled) {
    final path = widget.documentPath;
    if (path == null) return;
    final bloc = context.read<SettingsBloc>();
    if (enabled) {
      // Create the override starting from the current global preferences.
      bloc.updateDocumentReaderPrefs(path, (p) => p);
    } else {
      bloc.clearDocumentReaderPrefs(path);
    }
    setState(() => _perBookMode = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.documentPath;

    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTab.index,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsSheetHeader(
            title: 'Settings',
            trailing: const SettingsSheetCloseButton(),
          ),

          if (path != null)
            _PerBookOverrideBanner(
              enabled: _perBookMode,
              onChanged: _setPerBookMode,
            ),
          if (path != null) const Divider(height: 1),

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
              documentPath: _perBookMode ? path : null,
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
    );
  }
}

/// Banner shown when the settings sheet is opened from a reader, letting the
/// user choose between editing this book's preferences or the global ones.
class _PerBookOverrideBanner extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PerBookOverrideBanner({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Icon(
            LucideIcons.bookOpen,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize this book',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  enabled
                      ? 'Settings apply to this book only'
                      : 'Settings apply to all books',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}
