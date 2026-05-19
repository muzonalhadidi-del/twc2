import 'package:flutter/material.dart';
import 'package:twc/utils/accessibility_manager.dart';
import 'package:twc/utils/settings_manager.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final VoidCallback onLanguageToggle;
  final bool isArabic;

  const SettingsScreen({
    super.key, 
    required this.onThemeToggle,
    required this.onLanguageToggle,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الإعدادات' : 'Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Icon Color Theming
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              isArabic ? 'لون الأيقونات' : 'Icon Color',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ValueListenableBuilder<Color?>(
            valueListenable: SettingsManager.iconColorNotifier,
            builder: (context, currentColor, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorOption(null, 'Default', currentColor),
                  _buildColorOption(Colors.grey, 'Grey', currentColor),
                  _buildColorOption(Colors.blue, 'Blue', currentColor),
                  _buildColorOption(Colors.teal, 'Light', currentColor),
                ],
              );
            },
          ),
          const Divider(),

          // Theme Toggle
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(isArabic ? 'تغيير المظهر' : 'Change Mode'),
            trailing: IconButton(
              icon: const Icon(Icons.sync),
              onPressed: onThemeToggle,
            ),
          ),
          const Divider(),
          
          // Language Toggle
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(isArabic ? 'اللغة' : 'Language'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isArabic ? 'العربية' : 'English'),
                Switch(
                  value: isArabic,
                  onChanged: (val) => onLanguageToggle(),
                  activeColor: const Color(0xFF9EA4FF),
                ),
              ],
            ),
          ),
          const Divider(),

          // Font Size
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              isArabic ? 'حجم الخط' : 'Font Size', 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: AccessibilityManager.fontScaleNotifier,
            builder: (context, scale, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                    onPressed: () => AccessibilityManager.decreaseFontSize(),
                  ),
                  Text("${(scale * 100).toInt()}%", style: const TextStyle(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                    onPressed: () => AccessibilityManager.increaseFontSize(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color? color, String label, Color? currentColor) {
    bool isSelected = currentColor?.value == color?.value;
    return GestureDetector(
      onTap: () => SettingsManager.setIconColor(color),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color ?? Colors.black,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.deepPurple : Colors.transparent,
                width: 3,
              ),
            ),
            child: color == null
                ? const Icon(Icons.color_lens, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
