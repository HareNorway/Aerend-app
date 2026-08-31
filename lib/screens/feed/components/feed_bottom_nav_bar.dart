import 'package:flutter/material.dart';

import '../../../theme/sc_saas_theme.dart';

enum FeedShellTab { home, explore }

class FeedBottomNavBar extends StatelessWidget {
  const FeedBottomNavBar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  final FeedShellTab activeTab;
  final ValueChanged<FeedShellTab> onTabSelected;

  static const double _iconSize = 28;
  static const double _barHeight = 56;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: ScSaasThemeTokens.shadowCard,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: [
              _NavItem(
                isActive: activeTab == FeedShellTab.home,
                activeIcon: Icons.home_rounded,
                inactiveIcon: Icons.home_outlined,
                onTap: () => onTabSelected(FeedShellTab.home),
              ),
              _NavItem(
                isActive: activeTab == FeedShellTab.explore,
                activeIcon: Icons.explore_rounded,
                inactiveIcon: Icons.explore_outlined,
                onTap: () => onTabSelected(FeedShellTab.explore),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onTap,
  });

  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Icon(
              isActive ? activeIcon : inactiveIcon,
              size: FeedBottomNavBar._iconSize,
              color: isActive
                  ? ScSaasThemeTokens.primary
                  : ScSaasThemeTokens.gray500,
            ),
          ),
        ),
      ),
    );
  }
}
