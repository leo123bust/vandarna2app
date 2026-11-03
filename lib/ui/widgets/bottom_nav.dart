import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon, activeIcon;
}

/// Bottom navigation with the six main sections.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const items = <_NavItem>[
    _NavItem('Карта', Icons.map_outlined, Icons.map_rounded),
    _NavItem('Търсене', Icons.search_rounded, Icons.search_rounded),
    _NavItem('Сгради', Icons.apartment_outlined, Icons.apartment_rounded),
    _NavItem('Добави', Icons.add_circle_outline_rounded, Icons.add_circle_rounded),
    _NavItem('Любими', Icons.star_border_rounded, Icons.star_rounded),
    _NavItem('Профил', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(color: c.bg, border: Border(top: BorderSide(color: c.outline))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(20),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedScale(
                      scale: i == index ? 1.14 : 1.0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Icon(i == index ? items[i].activeIcon : items[i].icon,
                          size: 26, color: i == index ? c.navActive : c.textMuted),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == index ? FontWeight.w800 : FontWeight.w500,
                        color: i == index ? c.navActive : c.textMuted,
                      ),
                      child: Text(items[i].label),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
