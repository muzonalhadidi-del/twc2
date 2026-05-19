import 'package:flutter/material.dart';
import 'start_page.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainTabScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;
  final bool isArabic;

  const MainTabScreen({
    super.key,
    required this.onThemeToggle,
    required this.onLanguageToggle,
    required this.isArabic,
  });

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      StartPage(onThemeToggle: widget.onThemeToggle),
      ProfileScreen(isArabic: widget.isArabic),
      SettingsScreen(
        onThemeToggle: widget.onThemeToggle,
        onLanguageToggle: widget.onLanguageToggle,
        isArabic: widget.isArabic,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant MainTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update screens if language/theme toggles change
    if (oldWidget.isArabic != widget.isArabic) {
      _screens = [
        StartPage(onThemeToggle: widget.onThemeToggle),
        ProfileScreen(isArabic: widget.isArabic),
        SettingsScreen(
          onThemeToggle: widget.onThemeToggle,
          onLanguageToggle: widget.onLanguageToggle,
          isArabic: widget.isArabic,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: widget.isArabic ? 'الرئيسية' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.isArabic ? 'الملف الشخصي' : 'Profile',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: widget.isArabic ? 'الإعدادات' : 'Settings',
          ),
        ],
      ),
    );
  }
}
