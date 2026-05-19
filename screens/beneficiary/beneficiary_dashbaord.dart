import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'helpandsupport.dart';
import '../login_screen.dart';
import 'package:twc/services/auth_service.dart';
import 'package:twc/services/notification_service.dart';
import 'package:twc/widgets/color_picker_row.dart';
import 'my_requests_screen.dart';
import 'notification.dart';
import 'beneficiary_documents_screen.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/widgets/custom_bottom_nav_bar.dart';
import 'add_request.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/widgets/dynamic_background.dart';
import 'package:twc/widgets/glass_card.dart';

class BeneficiaryDashbaord extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const BeneficiaryDashbaord({super.key, required this.onThemeToggle});

  @override
  State<BeneficiaryDashbaord> createState() => _BeneficiaryDashbaordState();
}
class _BeneficiaryDashbaordState extends State<BeneficiaryDashbaord> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    NotificationService.checkUpcomingAppointments();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
      }
      return;
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(onThemeToggle: widget.onThemeToggle),
      ),
      (route) => false,
    );
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            String words = val.recognizedWords.toLowerCase();
            _processVoiceCommand(words);
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processVoiceCommand(String text) {
    if (text.isEmpty) return;
    
    String? matchedService;
    if (text.contains('مستشفى') || text.contains('موعد') || text.contains('طبيب') || text.contains('hospital') || text.contains('appointment')) {
      matchedService = 'Appointment';
    } else if (text.contains('تسوق') || text.contains('سوق') || text.contains('شراء') || text.contains('shopping') || text.contains('market')) {
      matchedService = 'Shopping';
    } else if (text.contains('نقل') || text.contains('توصيل') || text.contains('سيارة') || text.contains('transport') || text.contains('drive')) {
      matchedService = 'Transport';
    }

    if (matchedService != null) {
      setState(() => _isListening = false);
      _speech.stop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice command recognized. Opening request...')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddRequestScreen(initialService: matchedService)),
        );
      }
    }
  }

  void _showSOSDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            Text('EMERGENCY SOS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: Text(
          'This will broadcast an emergency request to all nearby volunteers. Are you sure?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _triggerSOS();
            },
            child: const Text('CONFIRM', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSOS() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      await FirebaseFirestore.instance.collection('beneficiaries_request').add({
        'beneficiaryId': currentUser?.uid,
        'volunteerId': 'unassigned',
        'isEmergency': true,
        'status': 'pending',
        'serviceType': 'Emergency SOS',
        'bookingDate': DateTime.now().toString().substring(0, 10),
        'bookingTime': 'Now',
        'beneficiaryLat': position.latitude,
        'beneficiaryLng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Send Email to Volunteers
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('beneficiaries').doc(currentUser?.uid).get();
        String name = userDoc.exists ? (userDoc.data() as Map<String, dynamic>)['fullName'] ?? 'A user' : 'A user';
        
        // Convert coordinates to address
        String address = "Lat: ${position.latitude}, Lng: ${position.longitude}";
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}".trim();
            address = address.replaceAll(RegExp(r'^,\s*'), '').replaceAll(RegExp(r',\s*$'), '');
          }
        } catch (e) {
          // Ignore reverse geocoding errors
        }

        await AuthService().sendEmergencyEmailToVolunteers(name, address);
      } catch (e) {
        if (kDebugMode) print("Failed to send emergency emails: $e");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS Alert sent to volunteers!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send SOS: $e')),
        );
      }
    }
  }

  Future<void> _updateProfileDialog() async {
    if (currentUser == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('beneficiaries')
          .doc(currentUser!.uid)
          .get();

      if (mounted) Navigator.pop(context);

      if (!doc.exists) return;
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      final nameController = TextEditingController(
        text: data['fullName'] ?? '',
      );
      final emailController = TextEditingController(text: data['email'] ?? '');
      final phoneController = TextEditingController(
        text: data['phoneNumber'] ?? '',
      );

      String? selectedGender = data['gender'];
      String? selectedDisability = data['disabilityType'];

      XFile? pickedXFile;
      Uint8List? webImage;
      String? currentImageUrl = data['profileImageUrl'];
      final ImagePicker picker = ImagePicker();

      if (!mounted) return;

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
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Update Profile".tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () async {
                            final XFile? picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              if (kIsWeb) {
                                var f = await picked.readAsBytes();
                                setDialogState(() {
                                  webImage = f;
                                  pickedXFile = picked;
                                });
                              } else {
                                setDialogState(() => pickedXFile = picked);
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
                                          currentImageUrl.isNotEmpty
                                      ? NetworkImage(currentImageUrl)
                                      : const AssetImage('images/profile.png')
                                            as ImageProvider),
                            child: const Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 15,
                                child: Icon(Icons.camera_alt, size: 18),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildField("Full Name".tr, nameController, Icons.person),
                        _buildField(
                          "Email".tr,
                          emailController,
                          Icons.email,
                          enabled: true,
                        ),
                        _buildField(
                          "Phone Number".tr,
                          phoneController,
                          Icons.phone,
                          isPhone: true,
                        ),

                        _buildDropdown(
                          "Gender".tr,
                          selectedGender,
                          ['Male', 'Female', 'Other'],
                          (val) => setDialogState(() => selectedGender = val),
                        ),

                        _buildDropdown(
                          "Disability Type".tr,
                          selectedDisability,
                          [
                            'Physical disability',
                            'Sensory disability',
                            'Intellectual disability',
                            'Psychological disability',
                            'Other disability',
                          ],
                          (val) =>
                              setDialogState(() => selectedDisability = val),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Cancel".tr),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9EA4FF),
                              ),
                              onPressed: () async {
                                String? imageUrl = currentImageUrl;
                                if (pickedXFile != null) {
                                  final cloudinary = CloudinaryPublic(
                                    'dooef2crr',
                                    'TWC123',
                                    cache: false,
                                  );
                                  CloudinaryResponse res = await cloudinary
                                      .uploadFile(
                                        CloudinaryFile.fromFile(
                                          pickedXFile!.path,
                                          resourceType:
                                              CloudinaryResourceType.Image,
                                        ),
                                      );
                                  imageUrl = res.secureUrl;
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
                                      .collection('beneficiaries')
                                      .doc(currentUser!.uid)
                                      .update({
                                        'fullName': nameController.text.trim(),
                                        'email': emailController.text.trim(),
                                        'phoneNumber': phoneController.text.trim(),
                                        'gender': selectedGender,
                                        'disabilityType': selectedDisability,
                                        'profileImageUrl': imageUrl,
                                      });
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: Text(
                                "Save Changes".tr,
                                style: const TextStyle(color: Colors.white),
                              ),
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
      if (mounted) Navigator.pop(context);
      debugPrint("Update Error: $e");
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPhone = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF9EA4FF)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    // FIX: Ensure the value exists in the list to prevent the crash
    final String? safeValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: safeValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.list, color: Color(0xFF9EA4FF)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DynamicBackground(
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('beneficiaries')
                .doc(currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          String name = data['fullName'] ?? "User";
          String? img = data['profileImageUrl'];

          return Column(
            children: [
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
                        backgroundImage: (img != null && img.isNotEmpty)
                            ? NetworkImage(img)
                            : const AssetImage('images/profile.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,'.tr,
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                          ),
                          Text(
                            name,
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
                      onPressed: _updateProfileDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMenuGrid(context),
                      const SizedBox(height: 40),
                      _buildLogoutBtn(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomBottomNavBar(
                currentIndex: 0,
                onTap: (index) {
                  if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                    );
                  } else if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                    );
                  } else if (index == 3) {
                    _updateProfileDialog();
                  }
                },
                onAddPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddRequestScreen()),
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
      
          // Floating Action Buttons for SOS and Voice Assistant
          Positioned(
            right: 20,
            bottom: 120, // above the custom bottom nav bar
            child: Column(
              children: [
                // Voice Assistant Button
                FloatingActionButton(
                  heroTag: 'mic',
                  backgroundColor: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
                  onPressed: _startListening,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                ),
                const SizedBox(height: 15),
                // SOS Button
                FloatingActionButton(
                  heroTag: 'sos',
                  backgroundColor: Colors.red,
                  onPressed: _showSOSDialog,
                  child: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // --- UI Helpers (Drawer, Buttons, etc.) ---

  // Update your _buildMenuGrid inside BeneficiaryDashbaord
  Widget _buildMenuGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          _menuBtn(
            Icons.list_alt,
            'My Requests'.tr,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
            ),
          ),
          _notifBtn(
            Icons.notifications,
            'Notifications'.tr,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          // --- ADDED THIS BUTTON ---
          _menuBtn(
            Icons.assignment_ind,
            'My Documents'.tr,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BeneficiaryDocumentsScreen(),
              ),
            ),
          ),
          _menuBtn(
            Icons.support_agent,
            'Support & helps'.tr,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportChatScreen()),
            ),
          ),
          _menuBtn(
            Icons.settings_outlined,
            'Setting'.tr,
            () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
    );
  }

  Widget _menuBtn(IconData icon, String text, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      width: 150,
      height: 130,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 36),
          ),
          const SizedBox(height: 12),
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

  Widget _notifBtn(IconData icon, String text, VoidCallback onTap) {
    return Stack(
      children: [
        _menuBtn(icon, text, onTap),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('beneficiaries_request')
              .where('beneficiaryId', isEqualTo: currentUser?.uid)
              .where('notificationStatus', isEqualTo: 'unread')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return const SizedBox.shrink();
            return Positioned(
              right: 10,
              top: 10,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text(
                  '${snapshot.data!.docs.length}',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutBtn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showLogoutDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 4,
          ),
          child: Text(
            'Logout'.tr,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Logout".tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("NO".tr),
          ),
          ElevatedButton(
            onPressed: () => _logout(context),
            child: Text("YES".tr),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF9EA4FF),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // We use a StreamBuilder here to get the latest profile image
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('beneficiaries')
                  .doc(currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String? imgUrl;
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  imgUrl = data['profileImageUrl'];
                }

                return CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white24,
                  backgroundImage: (imgUrl != null && imgUrl.isNotEmpty)
                      ? NetworkImage(imgUrl)
                      : const AssetImage('images/profile.png') as ImageProvider,
                );
              },
            ),
            const SizedBox(height: 30),
            _drawerTile(Icons.home, "Home".tr, () => Navigator.pop(context)),
            _drawerTile(Icons.dark_mode, "Change Mode".tr, () {
              widget.onThemeToggle();
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
