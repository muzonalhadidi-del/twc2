import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twc/services/auth_service.dart';
import 'package:twc/screens/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:twc/services/location_service.dart';

class BeneficiaryVolunteerDashboard extends StatefulWidget {
  final String userType;

  const BeneficiaryVolunteerDashboard({super.key, required this.userType});

  @override
  _BeneficiaryVolunteerDashboardState createState() =>
      _BeneficiaryVolunteerDashboardState();
}

class _BeneficiaryVolunteerDashboardState
    extends State<BeneficiaryVolunteerDashboard> {
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  Position? currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _startLocationTracking();
  }

  // ✅ FIXED: معالجة Future<Stream> + إذن الموقع
  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions are permanently denied.");
        return;
      }

      // 🔥 الحل هنا (await)
      final stream = await _locationService.getLocationStream();

      _positionStreamSubscription?.cancel();

      _positionStreamSubscription = stream.listen((Position position) {
        if (!mounted) return;
        setState(() {
          currentPosition = position;
        });
      });
    } catch (e) {
      debugPrint("Location tracking error: $e");
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // ✅ FIXED: إضافة try-catch
  Future<void> _loadUserData() async {
    final currentUser = _authService.getCurrentUser();

    if (currentUser != null) {
      final collection = widget.userType == 'beneficiary'
          ? 'beneficiaries'
          : 'volunteers';

      try {
        final doc = await FirebaseFirestore.instance
            .collection(collection)
            .doc(currentUser.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ FIXED: onThemeToggle
  Future<void> _signOut() async {
    final shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(onThemeToggle: () {}),
        ),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F0FB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 80,
              width: double.infinity,
              color: const Color(0xFF9EA0F2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.userType.capitalize()} Dashboard',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: Colors.white, size: 28),
                    onPressed: _signOut,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 40),
                child: Column(
                  children: [
                    // User Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_circle,
                              size: 80, color: Color(0xFF9EA0F2)),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome,',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _userData?['fullName'] ?? 'Guest User',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9EA0F2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 📍 Live Location
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on,
                                  color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text(
                                'Live Location Tracking',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          currentPosition == null
                              ? const Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text("Fetching GPS..."),
                            ],
                          )
                              : Column(
                            children: [
                              Text(
                                  "Lat: ${currentPosition!.latitude}"),
                              Text(
                                  "Lng: ${currentPosition!.longitude}"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              height: 64,
              width: double.infinity,
              color: const Color(0xFF9EA0F2),
              alignment: Alignment.center,
              child: const Text(
                '© Copyright',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// helper
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}