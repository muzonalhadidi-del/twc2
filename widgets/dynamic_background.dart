import 'package:flutter/material.dart';

class DynamicBackground extends StatelessWidget {
  final Widget child;

  const DynamicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Modern elegant colors
    final Color color1 = isDark ? const Color(0xFF1E153A) : const Color(0xFFF3E5F5); // Deep Purple / Soft Lavender
    final Color color2 = isDark ? const Color(0xFF0F0B29) : const Color(0xFFE8EAF6); // Very dark blue / Soft Blue
    final Color accent1 = isDark ? const Color(0xFF6C63FF).withOpacity(0.3) : const Color(0xFF9EA4FF).withOpacity(0.4);
    final Color accent2 = isDark ? const Color(0xFFB39DDB).withOpacity(0.2) : const Color(0xFFF48FB1).withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
      child: Stack(
        children: [
          // Top right glowing orb
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent1,
              ),
            ),
          ),
          // Bottom left glowing orb
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent2,
              ),
            ),
          ),
          // The glass/blur layer over the background shapes is handled by the cards themselves,
          // but we can add a subtle noise or full-screen blur if we want.
          // For performance, we'll let the GlassCard do the blurring.
          
          SafeArea(child: child),
        ],
      ),
    );
  }
}
