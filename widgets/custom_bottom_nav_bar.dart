import 'package:flutter/material.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/widgets/glass_card.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddPressed;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF22242A) : const Color(0xFFF3EDF7);
    Color iconColor = isDark ? Colors.white : Colors.black;
    Color selectedColor = const Color(0xFF7A7EFF); // New specific purple color

    return SizedBox(
      height: 90,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background pill
          GlassCard(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            height: 65,
            padding: EdgeInsets.zero,
            borderRadius: 35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home'.tr,
                  isSelected: currentIndex == 0,
                  color: currentIndex == 0 ? selectedColor : iconColor,
                  onTap: () => onTap(0),
                ),
                _navItem(
                  icon: Icons.list_alt,
                  activeIcon: Icons.list_alt,
                  label: 'My Task'.tr,
                  isSelected: currentIndex == 1,
                  color: currentIndex == 1 ? selectedColor : iconColor,
                  onTap: () => onTap(1),
                ),
                const SizedBox(width: 50), // Space for the center FAB
                _navItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Message'.tr,
                  isSelected: currentIndex == 2,
                  color: currentIndex == 2 ? selectedColor : iconColor,
                  onTap: () => onTap(2),
                ),
                _navItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile'.tr,
                  isSelected: currentIndex == 3,
                  color: currentIndex == 3 ? selectedColor : iconColor,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
          // Center FAB
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: onAddPressed,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: selectedColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
