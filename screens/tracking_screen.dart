import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:twc/screens/live_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackingScreen extends StatefulWidget {
  final String requestId;
  final String userType; // 'volunteer' or 'beneficiary'

  const TrackingScreen({
    super.key,
    required this.requestId,
    required this.userType,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isCompleting = false;

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  final LocationService _locationService = LocationService();
  
  Marker? _volunteerMarker;
  Marker? _beneficiaryMarker;
  Set<Polyline> _polylines = {};
  String _etaText = 'Calculating...';
  final LatLng _initialPosition = const LatLng(23.5880, 58.3829); // Default to Muscat, Oman

  void _updateDistanceAndETA() {
    if (_volunteerMarker != null && _beneficiaryMarker != null) {
      double distMeters = Geolocator.distanceBetween(
        _volunteerMarker!.position.latitude,
        _volunteerMarker!.position.longitude,
        _beneficiaryMarker!.position.latitude,
        _beneficiaryMarker!.position.longitude,
      );

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              _volunteerMarker!.position,
              _beneficiaryMarker!.position,
            ],
            color: const Color(0xFF7A7EFF),
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          )
        };

        double timeSeconds = distMeters / 11.1; // 40 km/h avg speed
        int timeMinutes = (timeSeconds / 60).round();
        double distKm = distMeters / 1000;

        if (timeMinutes < 1) {
          _etaText = 'Arriving soon (${distMeters.round()} m)';
        } else {
          _etaText = 'Est. Time: $timeMinutes mins (${distKm.toStringAsFixed(1)} km)';
        }
      });
      
      if (_mapController != null) {
        LatLngBounds bounds;
        final lat1 = _volunteerMarker!.position.latitude;
        final lat2 = _beneficiaryMarker!.position.latitude;
        final lng1 = _volunteerMarker!.position.longitude;
        final lng2 = _beneficiaryMarker!.position.longitude;
        
        bounds = LatLngBounds(
          southwest: LatLng(lat1 < lat2 ? lat1 : lat2, lng1 < lng2 ? lng1 : lng2),
          northeast: LatLng(lat1 > lat2 ? lat1 : lat2, lng1 > lng2 ? lng1 : lng2),
        );
        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    if (widget.userType == 'volunteer') {
      _startVolunteerTracking();
      _loadBeneficiaryLocation();
    } else {
      _listenToVolunteerLocation();
    }
  }

  Future<void> _requestPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startVolunteerTracking() async {
    try {
      final locationStream = await _locationService.getLocationStream();
      _locationSubscription = locationStream.listen((Position position) {
        final currentLatLng = LatLng(position.latitude, position.longitude);
        
        // Update Firestore
        FirebaseFirestore.instance.collection('live_tracking').doc(widget.requestId).set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update local map
        if (mounted) {
          setState(() {
            _volunteerMarker = Marker(
              markerId: const MarkerId('volunteer'),
              position: currentLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'You are here'),
            );
          });
          if (_beneficiaryMarker == null) {
            _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
          }
          _updateDistanceAndETA();
        }
      });
    } catch (e) {
      debugPrint("Error starting tracking: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start location tracking: $e')),
        );
      }
    }
  }

  void _listenToVolunteerLocation() {
    FirebaseFirestore.instance
        .collection('live_tracking')
        .doc(widget.requestId)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        final lat = data['latitude'] as double;
        final lng = data['longitude'] as double;
        final newLatLng = LatLng(lat, lng);

        setState(() {
          _volunteerMarker = Marker(
            markerId: const MarkerId('volunteer'),
            position: newLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Volunteer Location'),
          );
        });

        if (_beneficiaryMarker == null) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
        }
        _updateDistanceAndETA();
      }
    });
  }

  Future<void> _loadBeneficiaryLocation() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('beneficiaries_request').doc(widget.requestId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('beneficiaryLat') && data.containsKey('beneficiaryLng')) {
          final lat = data['beneficiaryLat'] as double;
          final lng = data['beneficiaryLng'] as double;
          final beneficiaryLatLng = LatLng(lat, lng);
          
          if (mounted) {
            setState(() {
              _beneficiaryMarker = Marker(
                markerId: const MarkerId('beneficiary'),
                position: beneficiaryLatLng,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Beneficiary Location'),
              );
            });
            _updateDistanceAndETA();
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading beneficiary location: $e");
    }
  }

  Future<void> _completeTask() async {
    setState(() => _isCompleting = true);
    try {
      final docRef = FirebaseFirestore.instance.collection('beneficiaries_request').doc(widget.requestId);
      
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        
        await docRef.update({'status': 'done'});

        // Add Gamification Points
        bool isEmergency = data['isEmergency'] == true;
        int pointsToAdd = isEmergency ? 20 : 10;
        await FirebaseFirestore.instance.collection('volunteers').doc(data['volunteerId']).update({
          'points': FieldValue.increment(pointsToAdd),
        });

        // Notify Beneficiary
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': data['beneficiaryId'],
          'title': 'Task Completed',
          'body': 'Your request has been marked as completed. Please evaluate the volunteer.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'evaluation',
          'requestId': widget.requestId,
          'volunteerId': data['volunteerId'],
        });

        // Stop tracking
        _locationSubscription?.cancel();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task completed successfully!')),
          );
          Navigator.pop(context); // Go back
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _launchGoogleMapsNavigation() async {
    if (_beneficiaryMarker == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beneficiary location not loaded yet.'.tr)),
        );
      }
      return;
    }
    
    final lat = _beneficiaryMarker!.position.latitude;
    final lng = _beneficiaryMarker!.position.longitude;
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch Google Maps'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themePurple = Color(0xFF9EA4FF);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Live Tracking'.tr, 
          style: GoogleFonts.inter(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _initialPosition,
                        zoom: 14.0,
                      ),
                      markers: {
                        if (_volunteerMarker != null) _volunteerMarker!,
                        if (_beneficiaryMarker != null) _beneficiaryMarker!,
                      },
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        if (_volunteerMarker != null) {
                           _mapController?.animateCamera(CameraUpdate.newLatLng(_volunteerMarker!.position));
                        }
                      },
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.directions_car, color: themePurple, size: 30),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.userType == 'volunteer' 
                                        ? 'En route to Beneficiary'.tr 
                                        : 'Volunteer is arriving'.tr,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 16,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    Text(_etaText.tr, style: GoogleFonts.inter(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (widget.userType == 'volunteer')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _launchGoogleMapsNavigation,
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: Text(
                        'Start Navigation'.tr,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isCompleting ? null : _completeTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isCompleting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Complete Task'.tr,
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            
          // Chat Button (For both)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveChatScreen(
                        requestId: widget.requestId,
                        currentUserId: user.uid,
                        otherUserId: '',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat, color: Colors.white),
                label: Text(
                  'Live Chat'.tr,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A7EFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
