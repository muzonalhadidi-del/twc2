import 'package:flutter/material.dart';
import 'package:twc/screens/about_us.dart';
import 'package:twc/screens/login_screen.dart';
import 'package:twc/screens/beneficiary/helpandsupport.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/widgets/dynamic_background.dart';

class StartPage extends StatelessWidget {
  final VoidCallback onThemeToggle;
  const StartPage({super.key, required this.onThemeToggle});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return DynamicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupportChatScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
      body: Container(
        child: SafeArea(
          child: Stack(
            children: [
              // Top title
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Together We Can',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              // Removed ColorPickerRow here

              // Center illustration (use an asset image)
              Positioned(
                top: size.height * 0.15,
                left: 24,
                right: 24,
                bottom: size.height * 0.30,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/elderly.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              // Buttons at the bottom
              Positioned(
                left: 24,
                right: 24,
                bottom: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start button (prominent)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(
                                onThemeToggle: onThemeToggle,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Start'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // About us button (muted)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutUsScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: const BorderSide(color: Colors.white, width: 1.5),
                          ),
                        ),
                        child: Text(
                          'About us'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Status bar icons imitation (optional)
            Positioned(top: 12, left: 12, child: Row(children: [
                  
                ],
              )),
          ],
        ),
      ),
      ),
    ));
  }
}
