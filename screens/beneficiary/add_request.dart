import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'transport_request.dart'; // Ensure correct paths
import 'appointment_request.dart';
import 'shopping_request.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddRequestScreen extends StatefulWidget {
  final String? initialService;
  
  const AddRequestScreen({super.key, this.initialService});

  @override
  State<AddRequestScreen> createState() => _AddRequestScreenState();
}

class _AddRequestScreenState extends State<AddRequestScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String? selectedService;
  final List<String> services = ['Transport', 'Appointment', 'Shopping'];

  final List<String> _availableTools = ['Magnifier', 'Wheelchair', 'Hearing Aid', 'Walker', 'Sign Language Interpreter'];
  List<String> _selectedTools = [];

  double? _beneficiaryLat;
  double? _beneficiaryLng;

  @override
  void initState() {
    super.initState();
    selectedService = widget.initialService;
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('beneficiaries')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc.get('fullName') ?? "";
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _beneficiaryLat = position.latitude;
        _beneficiaryLng = position.longitude;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}".trim();
        address = address.replaceAll(RegExp(r'^,\s*'), '').replaceAll(RegExp(r',\s*$'), '');
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not fetch location: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Add Request'.tr),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Hero(
              tag: 'logo',
              child: Image.asset('assets/images/twc.png', width: 40),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request Details',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildLabel("Service Type:".tr),
                      _buildDropdown(),
                      const SizedBox(height: 20),
                      
                      _buildLabel("Name:".tr),
                      _buildTextField(_nameController),
                      const SizedBox(height: 20),
                      
                      _buildLabel("Address:".tr),
                      _buildTextField(
                        _addressController, 
                        hint: "E.g., Al Khuwair St, Muscat",
                        suffixIcon: Icons.location_on,
                        onSuffixTap: _getCurrentLocation,
                      ),
                      const SizedBox(height: 20),
                      
                      _buildLabel("Details:".tr),
                      _buildTextField(_detailsController, hint: "Provide extra information...", maxLines: 4),
                      const SizedBox(height: 20),

                      _buildLabel("Required Tools:".tr),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _availableTools.map((tool) {
                          final isSelected = _selectedTools.contains(tool);
                          return FilterChip(
                            label: Text(tool, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: Theme.of(context).colorScheme.primary,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTools.add(tool);
                                } else {
                                  _selectedTools.remove(tool);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedService == null) return;

                            Map<String, dynamic> requestData = {
                              'serviceType': selectedService,
                              'name': _nameController.text,
                              'address': _addressController.text,
                              'details': _detailsController.text,
                              'requiredTools': _selectedTools,
                              'beneficiaryLat': _beneficiaryLat,
                              'beneficiaryLng': _beneficiaryLng,
                            };

                            if (selectedService == 'Transport') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TransportRequestScreen(data: requestData)));
                            } else if (selectedService == 'Appointment') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentRequestScreen(data: requestData)));
                            } else if (selectedService == 'Shopping') {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ShoppingRequestScreen(data: requestData)));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            "NEXT".tr,
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  Widget _buildFooter() => Container(
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
  );

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedService,
      decoration: const InputDecoration(
        hintText: "Select service",
      ),
      items: services
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => selectedService = val),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon != null ? IconButton(
          icon: Icon(suffixIcon, color: Theme.of(context).colorScheme.primary),
          onPressed: onSuffixTap,
        ) : null,
      ),
    );
  }
}
