import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  static final ValueNotifier<bool> isArabicNotifier = ValueNotifier(false);
  static final ValueNotifier<Color?> iconColorNotifier = ValueNotifier(null);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load Language
    final isArabic = prefs.getBool('isArabic') ?? false;
    isArabicNotifier.value = isArabic;

    // Load Icon Color
    final iconColorValue = prefs.getInt('iconColor');
    if (iconColorValue != null) {
      iconColorNotifier.value = Color(iconColorValue);
    }
  }

  static Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (themeNotifier.value == ThemeMode.light) {
      themeNotifier.value = ThemeMode.dark;
      await prefs.setBool('isDarkTheme', true);
    } else {
      themeNotifier.value = ThemeMode.light;
      await prefs.setBool('isDarkTheme', false);
    }
  }

  static Future<void> toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    isArabicNotifier.value = !isArabicNotifier.value;
    await prefs.setBool('isArabic', isArabicNotifier.value);
  }

  static Future<void> setIconColor(Color? color) async {
    final prefs = await SharedPreferences.getInstance();
    iconColorNotifier.value = color;
    if (color != null) {
      await prefs.setInt('iconColor', color.value);
    } else {
      await prefs.remove('iconColor');
    }
  }
}
