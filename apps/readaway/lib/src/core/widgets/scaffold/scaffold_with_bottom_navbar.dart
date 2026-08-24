part of '../core_widgets.dart';

class NavigationItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const NavigationItem({
    required this.label,
    required this.icon,
    this.onTap,
  });
}

class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({
    super.key,
    required this.navigationShell,
    this.scrollController,
  });

  List<NavigationItem> _items() => [
    NavigationItem(label: 'Library', icon: LucideIcons.home),
    NavigationItem(
      label: 'Settings',
      icon: LucideIcons.userPlus,
    ),
  ];

  final StatefulNavigationShell navigationShell;

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: _items()
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
