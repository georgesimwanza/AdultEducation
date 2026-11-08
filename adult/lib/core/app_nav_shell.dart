import 'package:flutter/material.dart';

import 'package:adult/core/responsive.dart';
import 'package:adult/screens/color.dart';

class NavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// The app's navigation frame, shared by students and admins so both look
/// the same: a rounded bottom bar on phones, an icon rail on tablets and a
/// labelled side panel on desktop.
class AppNavShell extends StatefulWidget {
  const AppNavShell({
    super.key,
    required this.destinations,
    required this.screens,
    this.subtitle,
  }) : assert(destinations.length == screens.length);

  final List<NavDestination> destinations;
  final List<Widget> screens;

  /// Small label under the brand in the side panel (e.g. "Admin").
  final String? subtitle;

  @override
  State<AppNavShell> createState() => _AppNavShellState();
}

class _AppNavShellState extends State<AppNavShell> {
  int _selectedIndex = 0;

  /// Tablet: icon rail. Desktop: the rail extends into a labelled side panel.
  Widget _buildWide(BuildContext context) {
    final extended = context.isDesktop;
    return Scaffold(
      backgroundColor: EduColors.background,
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: EduColors.surface,
              border: Border(right: BorderSide(color: EduColors.border)),
            ),
            child: SafeArea(
              child: NavigationRail(
                extended: extended,
                minExtendedWidth: 220,
                backgroundColor: EduColors.surface,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) =>
                    setState(() => _selectedIndex = i),
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                indicatorColor: EduColors.primarySoft,
                selectedIconTheme: const IconThemeData(
                  color: EduColors.primary,
                  size: 23,
                ),
                unselectedIconTheme: IconThemeData(
                  color: EduColors.textSecondary,
                  size: 23,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: EduColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: EduColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Same brand badge as the login header.
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: EduColors.primary,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: EduColors.onPrimary, size: 20),
                          ),
                          if (extended) ...[
                            const SizedBox(width: 10),
                            const Text(
                              'PAMODZI',
                              style: TextStyle(
                                color: EduColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (extended && widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: EduColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                destinations: [
                  for (final item in widget.destinations)
                    NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.activeIcon),
                      label: Text(item.label),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: widget.screens),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMobile) return _buildWide(context);
    final items = widget.destinations;
    return Scaffold(
      backgroundColor: EduColors.background,
      body: IndexedStack(index: _selectedIndex, children: widget.screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: EduColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A3D5CFF),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      data: items[i],
                      selected: i == _selectedIndex,
                      // More than four tabs: a narrower pill so it fits.
                      pillWidth: items.length > 4 ? 46 : 60,
                      onTap: () => setState(() => _selectedIndex = i),
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

class _NavItem extends StatelessWidget {
  final NavDestination data;
  final bool selected;
  final double pillWidth;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.pillWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pill behind the icon grows in when the tab is active.
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: selected ? pillWidth : 36,
            height: 34,
            decoration: BoxDecoration(
              color: selected ? EduColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              selected ? data.activeIcon : data.icon,
              size: 23,
              color: selected ? EduColors.primary : EduColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? EduColors.primary : EduColors.textSecondary,
            ),
            child: Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
