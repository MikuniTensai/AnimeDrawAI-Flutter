import 'package:flutter/material.dart';

class AnimatedBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurfaceVariant;

    final List<_NavItemData> items = [
      _NavItemData(icon: Icons.home, label: "Home"),
      _NavItemData(icon: Icons.search, label: "Explore"),
      _NavItemData(icon: Icons.photo_library, label: "Gallery"),
      _NavItemData(icon: Icons.star, label: "Chat"),
      _NavItemData(icon: Icons.person, label: "Profile"),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SafeArea(
        child: Container(
          height: 64.0,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: _NavItem(
                    icon: item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    primaryColor: primaryColor,
                    unselectedColor: unselectedColor,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  _NavItemData({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final Color unselectedColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = primaryColor;
    final inactiveColor = unselectedColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.2)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 24.0,
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          secondChild: const SizedBox(height: 0),
          crossFadeState: isSelected
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
