import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Chrome for the settings bottom sheet.
///
/// The sheet is a single modal managed as a GoRouter [ShellRoute]. Everything
/// inside it — the tabbed settings page and any sub-page (voice library,
/// custom fonts) — is rendered via the shell's nested [Navigator] passed in
/// as [child].
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key, required this.child});

  /// The ShellRoute's nested navigator.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header row for a page inside the [SettingsSheet]: a title, an optional
/// leading control (sub-pages use a back arrow to return to the tabbed root)
/// and an optional trailing control (the root uses a close button to dismiss
/// the whole sheet).
class SettingsSheetHeader extends StatelessWidget {
  const SettingsSheetHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(leading == null ? 20 : 8, 8, 8, 4),
          child: Row(
            children: [
              ?leading,
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// Back arrow for a sub-page of the settings sheet.
///
/// Pops the sheet's own navigator, so the tabbed settings page is revealed
/// rather than the whole sheet being dismissed.
class SettingsSheetBackButton extends StatelessWidget {
  const SettingsSheetBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.chevronLeft),
      tooltip: 'Back to settings',
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

/// Close button for the sheet's root page.
///
/// Pops the *root* navigator: [Navigator.pop] alone would only unwind the
/// sheet's own navigator, which is already at its root page.
class SettingsSheetCloseButton extends StatelessWidget {
  const SettingsSheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.x),
      tooltip: 'Close settings',
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
    );
  }
}
