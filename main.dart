import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Ensure this path matches your file structure
import 'screens/start_page.dart';
import 'screens/main_tab_screen.dart';
import 'package:twc/utils/accessibility_manager.dart';
import 'package:twc/utils/settings_manager.dart';

Future<void> _createAdminUser() async {
  try {
    final adminEmail = "admin@disabilityapp.com";
    final adminPassword = "Admin123@";

    final adminQuery = await FirebaseFirestore.instance
        .collection('admins')
        .where('email', isEqualTo: adminEmail)
        .limit(1)
        .get();

    if (adminQuery.docs.isEmpty) {
      try {
        final adminCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );

        await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminCredential.user!.uid)
            .set({
              'email': adminEmail,
              'createdAt': DateTime.now(),
              'isSuperAdmin': true,
            });
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) print("Auth check: ${e.code}");
      }
    }
  } catch (e) {
    if (kDebugMode) print("Admin setup error: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDaeTOSeqek_A6O4lb9TBkoT5zpeS90-7s",
        appId: "1:824131407632:android:2fd3db055f37adb5941f95",
        messagingSenderId: "824131407632",
        projectId: "together-we-can-5d6e9",
        storageBucket: "together-we-can-5d6e9.appspot.com",
      ),
    );

    await _createAdminUser();
    await SettingsManager.initialize();
    await AccessibilityManager.initialize();
  } catch (e) {
    if (kDebugMode) print("Firebase/Settings init error: $e");
  }

  runApp(const DisabilityVolunteerApp());
}

class DisabilityVolunteerApp extends StatefulWidget {
  const DisabilityVolunteerApp({super.key});

  @override
  State<DisabilityVolunteerApp> createState() => _DisabilityVolunteerAppState();
}

class _DisabilityVolunteerAppState extends State<DisabilityVolunteerApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsManager.isArabicNotifier,
      builder: (context, isArabic, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: SettingsManager.themeNotifier,
          builder: (context, themeMode, child) {
            return ValueListenableBuilder<double>(
              valueListenable: AccessibilityManager.fontScaleNotifier,
              builder: (context, scale, child) {
                return ValueListenableBuilder<Color?>(
                  valueListenable: SettingsManager.iconColorNotifier,
                  builder: (context, iconColor, child) {
                    return MaterialApp(
                      title: 'Together We Can',
                      debugShowCheckedModeBanner: false,
                      themeMode: themeMode,

                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(textScaleFactor: scale),
                          child: Directionality(
                            textDirection: isArabic
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: child!,
                          ),
                        );
                      },

                      theme: ThemeData(
                        useMaterial3: true,
                        brightness: Brightness.light,
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: iconColor ?? const Color(0xFF6C63FF),
                          primary: iconColor ?? const Color(0xFF6C63FF),
                          secondary: const Color(0xFF9EA4FF),
                          background: const Color(0xFFF8F9FA),
                          surface: Colors.white,
                        ),
                        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
                        textTheme: GoogleFonts.interTextTheme(
                          ThemeData.light().textTheme,
                        ),
                        iconTheme: iconColor != null
                            ? IconThemeData(color: iconColor)
                            : null,
                        appBarTheme: AppBarTheme(
                          elevation: 0,
                          centerTitle: true,
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.black87,
                          titleTextStyle: GoogleFonts.inter(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        cardTheme: CardThemeData(
                          color: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        elevatedButtonTheme: ElevatedButtonThemeData(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C63FF),
                              width: 2,
                            ),
                          ),
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),

                      darkTheme: ThemeData(
                        useMaterial3: true,
                        brightness: Brightness.dark,
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: iconColor ?? const Color(0xFF9EA4FF),
                          brightness: Brightness.dark,
                          primary: iconColor ?? const Color(0xFF9EA4FF),
                          secondary: const Color(0xFF6C63FF),
                          background: const Color(0xFF121212),
                          surface: const Color(0xFF1E1E1E),
                        ),
                        scaffoldBackgroundColor: const Color(0xFF121212),
                        textTheme: GoogleFonts.interTextTheme(
                          ThemeData.dark().textTheme,
                        ),
                        iconTheme: iconColor != null
                            ? IconThemeData(color: iconColor)
                            : null,
                        appBarTheme: AppBarTheme(
                          elevation: 0,
                          centerTitle: true,
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          titleTextStyle: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        cardTheme: CardThemeData(
                          color: const Color(0xFF1E1E1E),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.grey.shade800,
                              width: 1,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        elevatedButtonTheme: ElevatedButtonThemeData(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9EA4FF),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade800),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF9EA4FF),
                              width: 2,
                            ),
                          ),
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),

                      home: MainTabScreen(
                        onThemeToggle: SettingsManager.toggleTheme,
                        onLanguageToggle: SettingsManager.toggleLanguage,
                        isArabic: isArabic,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
