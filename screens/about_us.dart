import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: Back button on left, Image on right
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, size: 28),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                Image.network(
                                  'https://res.cloudinary.com/dv2x9fveq/image/upload/v1765480794/IMG_4695_k6exsh.png',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'About Us'.tr,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 30),

                            // About Us Content
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Environmental Sustainability'.tr,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'The Together We Can platform supports environmental sustainability by adopting a fully digital approach to volunteer coordination, which significantly reduces reliance on paper-based processes and minimizes physical resource consumption. By using cloud infrastructure instead of on-site hardware, the system lowers energy usage and prevents the accumulation of electronic waste.'.tr,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Additionally, the AI-driven matching and optimized transportation features help reduce unnecessary travel, decreasing fuel consumption and carbon emissions.'.tr,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Through these practices, the project contributes to greener operations and aligns with global sustainability goals and Oman Vision 2040\'s commitment to environmentally responsible digital solutions.'.tr,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Vision 2040 Badge
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Oman Vision 2040'.tr,
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Committed to environmentally responsible digital solutions'.tr,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Spacer to push content up and footer down
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    // Footer
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
        },
      ),
    );
  }
}
