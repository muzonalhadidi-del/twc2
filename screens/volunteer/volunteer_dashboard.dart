import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twc/screens/volunteer/certificate.dart';
import 'package:twc/screens/volunteer/vlounteer_list.dart';
import 'package:twc/screens/volunteer/volunteer_documents_screen.dart';
import 'package:twc/screens/volunteer/volunteer_sechdule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:twc/services/notification_service.dart';
import 'package:twc/widgets/color_picker_row.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../login_screen.dart';
import 'package:twc/screens/beneficiary/helpandsupport.dart';
import 'package:twc/screens/tracking_screen.dart';
import 'package:twc/widgets/custom_bottom_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/widgets/dynamic_background.dart';
import 'package:twc/widgets/glass_card.dart';
import 'package:twc/utils/app_translations.dart';

class VolunteerDashboard extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const VolunteerDashboard({super.key, required this.onThemeToggle});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  @override
  void initState() {
    super.initState();
    _updateActivityAndCheckNotifications();
    NotificationService.checkUpcomingAppointments();
  }

  Future<void> _updateActivityAndCheckNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Update lastActive
    await FirebaseFirestore.instance.collection('volunteers').doc(user.uid).update({
      'lastActive': FieldValue.serverTimestamp(),
    });

    // Check notifications
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          var data = doc.data();
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(data['title'] ?? 'Notification'),
                content: Text(data['body'] ?? ''),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          doc.reference.update({'isRead': true});
        }
      }
    });
  }



  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
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

  Future<void> _updateProfileDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7A7EFF)),
        ),
      ),
    );

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user.uid)
          .get();
      if (context.mounted) Navigator.pop(context);

      if (!doc.exists) return;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      final nameController = TextEditingController(
        text: data['fullName'] ?? '',
      );
      final emailController = TextEditingController(
        text: data['email'] ?? '',
      );
      final genderController = TextEditingController(
        text: data['gender'] ?? '',
      );
      final phoneController = TextEditingController(
        text: data['phoneNumber'] ?? '',
      );

      // Image handling variables
      XFile? pickedXFile;
      Uint8List? webImage; // For web preview
      String? currentImageUrl = data['profileImageUrl'];
      final ImagePicker picker = ImagePicker();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Profile Image Picker
                        GestureDetector(
                          onTap: () async {
                            final XFile? picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              if (kIsWeb) {
                                // On Web, we read as bytes
                                var f = await picked.readAsBytes();
                                setDialogState(() {
                                  webImage = f;
                                  pickedXFile = picked;
                                });
                              } else {
                                setDialogState(() {
                                  pickedXFile = picked;
                                });
                              }
                            }
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: pickedXFile != null
                                ? (kIsWeb
                                      ? MemoryImage(webImage!)
                                      : FileImage(File(pickedXFile!.path))
                                            as ImageProvider)
                                : (currentImageUrl != null &&
                                          currentImageUrl!.isNotEmpty
                                      ? NetworkImage(currentImageUrl!)
                                      : const AssetImage('images/profile.png')),
                            child: const Align(
                              alignment: Alignment.bottomRight,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildModernTextField(
                          "Full Name",
                          nameController,
                          Icons.person_outline,
                        ),
                        _buildModernTextField(
                          "Email",
                          emailController,
                          Icons.email_outlined,
                        ),
                        _buildModernTextField(
                          "Gender",
                          genderController,
                          Icons.transgender,
                        ),
                        _buildModernTextField(
                          "Phone Number",
                          phoneController,
                          Icons.phone_android,
                          isPhone: true,
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7A7EFF),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                if (phoneController.text.trim().length < 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Phone must be 10+ digits"),
                                    ),
                                  );
                                  return;
                                }

                                String? imageUrl = currentImageUrl;

                                if (pickedXFile != null) {
                                  try {
                                    final cloudinary = CloudinaryPublic(
                                      'dooef2crr',
                                      'TWC123',
                                      cache: false,
                                    );

                                    // Cloudinary upload works for both web (path) and mobile
                                    CloudinaryResponse response =
                                        await cloudinary.uploadFile(
                                          CloudinaryFile.fromFile(
                                            pickedXFile!.path,
                                            resourceType:
                                                CloudinaryResourceType.Image,
                                          ),
                                        );
                                    imageUrl = response.secureUrl;
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Upload error: $e"),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                  if (emailController.text.trim() != data['email']) {
                                    try {
                                      await FirebaseAuth.instance.currentUser!
                                          .verifyBeforeUpdateEmail(emailController.text.trim());
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Verification email sent to new address. Please verify to complete the change.")),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Failed to update email: $e")),
                                      );
                                      return;
                                    }
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('volunteers')
                                      .doc(user.uid)
                                      .update({
                                        'fullName': nameController.text.trim(),
                                        'email': emailController.text.trim(),
                                        'gender': genderController.text.trim(),
                                        'phoneNumber': phoneController.text.trim(),
                                        'profileImageUrl': imageUrl,
                                      });
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: const Text("Save Changes"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildModernTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF7A7EFF)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF7A7EFF), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DynamicBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('volunteers')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String displayName = "Loading...";
            String? imageUrl;
            if (snapshot.hasData && snapshot.data!.exists) {
              Map<String, dynamic> data =
                  snapshot.data!.data() as Map<String, dynamic>;
              displayName = data['fullName'] ?? "User";
              imageUrl = data['profileImageUrl'];
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          Icon(Icons.volunteer_activism, color: Theme.of(context).colorScheme.primary, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            "TWC Volunteer".tr,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48), // Balancing the back button
                    ],
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('beneficiaries_request')
                      .where('isEmergency', isEqualTo: true)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, reqSnapshot) {
                    if (reqSnapshot.hasData && reqSnapshot.data!.docs.isNotEmpty) {
                      var docs = reqSnapshot.data!.docs.where((d) {
                        var data = d.data() as Map<String, dynamic>;
                        return data['volunteerId'] == user?.uid || data['volunteerId'] == 'unassigned';
                      }).toList();

                      if (docs.isNotEmpty) {
                        final doc = docs.first;
                        final data = doc.data() as Map<String, dynamic>;
                        final bool isUnassigned = data['volunteerId'] == 'unassigned';

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade300, width: 2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isUnassigned
                                      ? "GENERAL EMERGENCY ALERT: Tap to accept nearby request!"
                                      : "EMERGENCY ALERT: You have a pending emergency request!",
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.check, color: Colors.white, size: 20),
                                  onPressed: () {
                                    if (isUnassigned) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Accept Emergency Request?'),
                                          content: const Text('Are you sure you want to take this emergency request?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                await FirebaseFirestore.instance.collection('beneficiaries_request').doc(doc.id).update({
                                                  'volunteerId': user?.uid,
                                                });
                                                if (context.mounted) {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(requestId: doc.id, userType: 'volunteer')));
                                                }
                                              },
                                              child: const Text('Accept', style: TextStyle(color: Colors.white)),
                                            )
                                          ],
                                        )
                                      );
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(requestId: doc.id, userType: 'volunteer')));
                                    }
                                  }
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: ColorPickerRow(),
                ),
                // Profile Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  padding: const EdgeInsets.all(20),
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
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                              ? NetworkImage(imageUrl)
                              : const AssetImage('images/profile.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Volunteer'.tr,
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                            ),
                            Text(
                              displayName,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.white, size: 30),
                        onPressed: () => _updateProfileDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _menuButton(
                            context,
                            "SCHEDULE".tr,
                            Icons.calendar_month,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VolunteerScheduleScreens(mode: ''),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _menuButton(
                                  context,
                                  "LIST".tr,
                                  Icons.list_alt,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const VolunteerCompleteListScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _menuButton(
                                  context,
                                  "CERTIFICATE".tr,
                                  Icons.workspace_premium,
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) return;
                                    final snapshot = await FirebaseFirestore.instance.collection('beneficiaries_request').where('volunteerId', isEqualTo: user.uid).get();
                                    bool hasIncomplete = false;
                                    bool hasAny = false;
                                    for (var req in snapshot.docs) {
                                      hasAny = true;
                                      if (req.data()['status'] != 'completed') {
                                        hasIncomplete = true;
                                        break;
                                      }
                                    }
                                    if (hasAny && !hasIncomplete) {
                                      if (context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const VolunteerCertificateScreen(),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("First complete all tasks".tr)),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _menuButton(
                            context,
                            "UPLOAD DOCUMENTS".tr,
                            Icons.cloud_upload_outlined,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VolunteerDocumentsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                              ),
                              onPressed: () => _showLogoutDialog(context),
                              child: Text("Logout".tr, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CustomBottomNavBar(
                  currentIndex: 0,
                  onTap: (index) {
                    if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VolunteerCompleteListScreen()),
                      );
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                      );
                    } else if (index == 3) {
                      _updateProfileDialog(context);
                    }
                  },
                  onAddPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VolunteerScheduleScreens(mode: '')),
                      );
                  },
                ),
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
            );
          },
        ),
      ),
    ));
  }

  Widget _menuButton(
    BuildContext context,
    String text,
    IconData icon, {
    required VoidCallback onPressed,
  }) {
    return GlassCard(
      onTap: onPressed,
      height: 100,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
