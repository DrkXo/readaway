import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Chrome for the settings bottom sheet, plus a navigator for its pages.
///
/// The sheet is a single modal. Everything inside it — the tabbed settings
/// page and any sub-page (voice library, custom fonts) — is a page on the
/// [Navigator] this widget owns, so opening a sub-page pushes *within* the
/// sheet instead of stacking a second modal on top of it.
///
/// The navigator is pushed imperatively rather than driven by the router on
/// purpose: a bottom-sheet route caches its content widget (Flutter's
/// `_ModalScope`), so a route-level page swap inside a sheet never reaches the
/// widget tree.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.home});

  /// The sheet's root page, i.e. the tabbed settings page.
  final Widget home;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings-sheet');

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
              Flexible(
                child: SettingsSheetScope(
                  navigatorKey: _navigatorKey,
                  child: Navigator(
                    key: _navigatorKey,
                    onGenerateRoute: (settings) => MaterialPageRoute<void>(
                      settings: settings,
                      builder: (context) => widget.home,
                    ),
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

/// Gives pages inside the [SettingsSheet] access to its navigator.
class SettingsSheetScope extends InheritedWidget {
  const SettingsSheetScope({
    super.key,
    required this.navigatorKey,
    required super.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  /// The sheet's navigator, or null when [context] is outside the sheet.
  static GlobalKey<NavigatorState>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SettingsSheetScope>()
      ?.navigatorKey;

  @override
  bool updateShouldNotify(SettingsSheetScope oldWidget) =>
      navigatorKey != oldWidget.navigatorKey;
}

/// Pushes [page] on top of the settings sheet's current page.
///
/// Must be called from inside the sheet (from a panel, or anything else the
/// sheet rendered). [Navigator.pop] on the pushed page — the back arrow, the
/// system back gesture — returns to the page underneath instead of closing the
/// sheet.
void pushSettingsPage(BuildContext context, Widget page) {
  final navigator = SettingsSheetScope.maybeOf(context)?.currentState;
  assert(
    navigator != null,
    'pushSettingsPage() called outside of the settings sheet',
  );
  navigator?.push(MaterialPageRoute<void>(builder: (context) => page));
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
