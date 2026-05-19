import 'package:twc/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twc/services/notification_service.dart';
import 'package:twc/screens/Admin/VolunteerSelectionScreen.dart';
import 'package:twc/widgets/color_picker_row.dart';
import 'package:twc/screens/Admin/ManageBeneficiaryScreen.dart';
import 'package:twc/widgets/color_picker_row.dart';
import 'package:twc/screens/Admin/ManageRequestsScreen.dart';
import '../login_screen.dart';
import '../volunteer/manage_volunteer_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/widgets/dynamic_background.dart';
import 'package:twc/widgets/glass_card.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const AdminDashboard({super.key, required this.onThemeToggle});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    _checkInactiveVolunteers();
    NotificationService.checkUpcomingAppointments();
  }

  Future<void> _checkInactiveVolunteers() async {
    try {
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('volunteers')
          .where('reminderSent', isNotEqualTo: true)
          .get();

      final authService = AuthService();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['lastActive'] != null) {
          final lastActive = (data['lastActive'] as Timestamp).toDate();
          if (lastActive.isBefore(oneWeekAgo)) {
            // Send email
            String email = data['email'] ?? '';
            String name = data['fullName'] ?? '';
            if (email.isNotEmpty) {
              await authService.sendInactivityReminderEmail(email, name);
            }

            // Add notification
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': doc.id,
              'title': 'We Miss You!',
              'body': 'Please update your schedule and availability.',
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
              'type': 'reminder',
            });

            // Mark reminder as sent
            await doc.reference.update({'reminderSent': true});
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking inactive volunteers: $e");
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(onThemeToggle: widget.onThemeToggle),
        ),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logout failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("NO"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _logout(context);
              },
              child: const Text("YES"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DynamicBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // 🔽 المحتوى القابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 🔝 Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child:
                            Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface),
                          ),
                          Hero(
                            tag: 'logo',
                            child: Image.asset('assets/images/twc.png', height: 40),
                          ),
                          const SizedBox(width: 24), // Balance the row
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: ColorPickerRow(),
                    ),
                    const SizedBox(height: 20),

                    // 🏷 Title Header
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 36),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Together We Can",
                                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                                ),
                                Text(
                                  "Admin Portal",
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔘 Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _adminButton(context, "Manage volunteer", Icons.volunteer_activism, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const ManageVolunteerScreen(),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          _adminButton(context, "Manage Beneficiary", Icons.people, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const ManageBeneficiaryScreen(),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          _adminButton(context, "Manage Requests", Icons.list_alt, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const ManageRequestsScreen(),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          _adminButton(context, "See schedule", Icons.calendar_month, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const VolunteerSelectionScreen(
                                    mode: "schedule"),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          _adminButton(context, "All Reports", Icons.assessment, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const VolunteerSelectionScreen(mode: "report"),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          _adminButton(context, "Generate Certificates", Icons.workspace_premium, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const VolunteerSelectionScreen(
                                    mode: "certificate"),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // 🚪 Logout Button (ثابت)
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
               child: SizedBox(
                 width: double.infinity,
                 height: 55,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.red.shade600,
                     foregroundColor: Colors.white,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(16),
                     ),
                     elevation: 4,
                   ),
                   onPressed: () => _showLogoutDialog(context),
                   child: Text(
                     "LOGOUT",
                     style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                   ),
                 ),
               ),
             ),

            // ⬇ Footer (ثابت)
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

  // 🔘 Button Widget
  static Widget _adminButton(BuildContext context, String text, IconData icon, {required VoidCallback onTap}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: EdgeInsets.zero,
      onTap: onTap,
      height: 70,
      borderRadius: 16,
      child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
    );
  }
}