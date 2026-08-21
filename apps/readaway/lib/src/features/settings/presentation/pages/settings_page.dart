import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:readaway/src/features/settings/presentation/widgets/theme_mode_changer_widget.dart';

import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        // Adjust alpha / opacity to your preference (e.g. 0.85 - 0.95)
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header: Title & Close Button
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
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Sheet Body
            Flexible(
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: const [
                      ThemeModeChangerWidget(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
