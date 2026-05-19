import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';

class VolunteerRadarScreen extends StatefulWidget {
  const VolunteerRadarScreen({super.key});

  @override
  State<VolunteerRadarScreen> createState() => _VolunteerRadarScreenState();
}

class _VolunteerRadarScreenState extends State<VolunteerRadarScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initRadar();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initRadar() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    _loadNearbyVolunteers();
  }

  Future<void> _loadNearbyVolunteers() async {
    if (_currentPosition == null) return;

    // Fetch up to 5 volunteers from Firestore to simulate them being nearby
    final snapshot = await FirebaseFirestore.instance.collection('volunteers').limit(5).get();
    
    Set<Marker> newMarkers = {};
    
    // Add User Marker
    newMarkers.add(
      Marker(
        markerId: const MarkerId('user'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "You are here"),
      )
    );

    final random = Random();
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Generate a random nearby location (within ~2km)
      double latOffset = (random.nextDouble() - 0.5) * 0.02;
      double lngOffset = (random.nextDouble() - 0.5) * 0.02;
      
      LatLng randomLocation = LatLng(
        _currentPosition!.latitude + latOffset,
        _currentPosition!.longitude + lngOffset,
      );

      newMarkers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: randomLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: data['fullName'] ?? 'Active Volunteer',
            snippet: "Ready to help",
          ),
        )
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _isLoading = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
          13.5
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Volunteer Radar'.tr,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          if (_currentPosition != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 13.5,
              ),
              markers: _markers,
              myLocationEnabled: false, // Custom marker used instead
              zoomControlsEnabled: false,
              onMapCreated: (controller) => _mapController = controller,
            ),
            
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_currentPosition == null)
            Center(
              child: Text(
                'Location permission required'.tr, 
                style: GoogleFonts.inter(fontSize: 18, color: Colors.grey)
              )
            ),

          // Radar Overlay Effect
          if (!_isLoading && _currentPosition != null)
            IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return Container(
                      width: 250 * _radarController.value,
                      height: 250 * _radarController.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.green.withOpacity(1 - _radarController.value),
                          width: 2,
                        ),
                        color: Colors.green.withOpacity((1 - _radarController.value) * 0.2),
                      ),
                    );
                  },
                ),
              ),
            ),
            
          // Bottom Info Sheet
          if (!_isLoading && _currentPosition != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 10))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.radar, color: Colors.blue.shade700, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Scanning Area...".tr,
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_markers.length - 1} volunteers nearby".tr,
                            style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
