import 'package:flutter/material.dart';
import 'package:twc/utils/settings_manager.dart';
import 'package:twc/utils/app_translations.dart';

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color?>(
      valueListenable: SettingsManager.iconColorNotifier,
      builder: (context, currentColor, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Change Theme Color".tr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildColorOption(null, 'Default'.tr, currentColor),
                  _buildColorOption(Colors.grey, 'Grey'.tr, currentColor),
                  _buildColorOption(Colors.blue, 'Blue'.tr, currentColor),
                  _buildColorOption(Colors.teal, 'Light'.tr, currentColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorOption(Color? color, String label, Color? currentColor) {
    bool isSelected = currentColor?.value == color?.value;
    return GestureDetector(
      onTap: () => SettingsManager.setIconColor(color),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color ?? const Color(0xFF6C63FF),
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
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
