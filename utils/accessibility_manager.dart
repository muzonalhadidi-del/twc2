import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityManager {
  // التحكم في حجم الخط
  static final ValueNotifier<double> fontScaleNotifier = ValueNotifier(1.0);

  // Text To Speech
  static final FlutterTts _flutterTts = FlutterTts();
  static bool isTtsEnabled = false;

  // تهيئة القيم المحفوظة
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    fontScaleNotifier.value = prefs.getDouble('fontScale') ?? 1.0;
    isTtsEnabled = prefs.getBool('isTtsEnabled') ?? false;

    // إعدادات الصوت
    await _flutterTts.setLanguage("ar-SA"); // عربي (غيّرها إذا تحتاج)
    await _flutterTts.setSpeechRate(0.5);
  }

  // تكبير الخط
  static Future<void> increaseFontSize() async {
    if (fontScaleNotifier.value < 1.5) {
      fontScaleNotifier.value += 0.1;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontScale', fontScaleNotifier.value);
    }
  }

  // تصغير الخط
  static Future<void> decreaseFontSize() async {
    if (fontScaleNotifier.value > 0.8) {
      fontScaleNotifier.value -= 0.1;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('fontScale', fontScaleNotifier.value);
    }
  }

  // تشغيل / إيقاف TTS (نسخة واحدة فقط ✔️)
  static Future<void> toggleTts(bool enable) async {
    isTtsEnabled = enable;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTtsEnabled', enable);

    if (!enable) {
      await _flutterTts.stop();
    }
  }

  // قراءة النص
  static Future<void> speak(String text) async {
    if (isTtsEnabled && text.isNotEmpty) {
      await _flutterTts.stop(); // يمنع تداخل الأصوات
      await _flutterTts.speak(text);
    }
  }

  // إيقاف الصوت يدويًا
  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}