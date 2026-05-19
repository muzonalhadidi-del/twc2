import 'package:flutter/material.dart';
import 'register_beneficiary_screen.dart';
import 'register_volunteer_screen.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/widgets/dynamic_background.dart';
import 'package:twc/widgets/glass_card.dart';

class RegistrationTypeScreen extends StatelessWidget {
  const RegistrationTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top row: Back button on left, Image on right with padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Hero(
                    tag: 'logo',
                    child: Image.network(
                      'https://res.cloudinary.com/dv2x9fveq/image/upload/v1765480794/IMG_4695_k6exsh.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Title
                    Text(
                      'Select Registration Type'.tr,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 60),

                    // Beneficiary Button (BIG PURPLE)
                    Container(
                      width: double.infinity,
                      height: 70, // Big button height
                      margin: const EdgeInsets.symmetric(vertical: 15),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterBeneficiaryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.favorite, size: 28),
                        label: Text(
                          'Register as Beneficiary'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 20, // Bigger text
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                          shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        ),
                      ),
                    ),

                    // Volunteer Button (BIG PURPLE)
                    Container(
                      width: double.infinity,
                      height: 70, // Big button height
                      margin: const EdgeInsets.symmetric(vertical: 15),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RegisterVolunteerScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.volunteer_activism, size: 28),
                        label: Text(
                          'Register as Volunteer'.tr,
                          style: GoogleFonts.inter(
                            fontSize: 20, // Bigger text
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 6,
                          shadowColor: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                        ),
                      ),
                    ),
                    // Back to Login link
                    const SizedBox(height: 40),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Goes back to login screen
                      },
                      child: Text(
                        'Back to Login',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    const SizedBox(height: 80), // Space before footer
                  ],
                ),
              ),
            ),

            // Footer - AT THE VERY BOTTOM of screen
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
                ]
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SafeArea(
                top: false,
                child: Center(
                  child: Text(
                    '@TWC2026', 
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
