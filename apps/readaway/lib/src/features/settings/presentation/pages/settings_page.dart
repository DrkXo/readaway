import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.showScopeToggle = true});

  final bool showScopeToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: DefaultTabController(
            length: 5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header: title & close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                  child: Row(
                    children: [
                      Text(
                        'Settings',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                TabBar(
                  isScrollable: false,
                  tabAlignment: TabAlignment.fill,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      icon: Icon(
                        LucideIcons.type,
                      ),
                      text: 'Font',
                    ),
                    Tab(
                      icon: Icon(
                        LucideIcons.space,
                      ),
                      text: 'Layout',
                    ),
                    Tab(
                      icon: Icon(
                        LucideIcons.hand,
                      ),
                      text: 'Behavior',
                    ),
                    Tab(
                      icon: Icon(
                        LucideIcons.palette,
                      ),
                      text: 'Appearance',
                    ),
                    Tab(
                      icon: Icon(
                        LucideIcons.mic,
                      ),
                      text: 'TTS',
                    ),
                  ],
                ),

                Flexible(
                  child: TabBarView(
                    children: [
                      SettingsFontPanel(showScopeToggle: showScopeToggle),
                      SettingsLayoutPanel(showScopeToggle: showScopeToggle),
                      const SettingsBehaviorPanel(),
                      const SettingsAppearancePanel(),
                      SettingsTtsPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
