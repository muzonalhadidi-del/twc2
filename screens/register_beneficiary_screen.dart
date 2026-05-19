import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:twc/services/auth_service.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:twc/utils/validators.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/widgets/dynamic_background.dart';
import 'package:twc/widgets/glass_card.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class RegisterBeneficiaryScreen extends StatefulWidget {
  final AuthService? authService;
  final CloudinaryPublic? cloudinary;

  const RegisterBeneficiaryScreen({super.key, this.authService, this.cloudinary});

  @override
  _RegisterBeneficiaryScreenState createState() =>
      _RegisterBeneficiaryScreenState();
}

class _RegisterBeneficiaryScreenState extends State<RegisterBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _civilIdController = TextEditingController();
  final TextEditingController _disabilityController = TextEditingController();

  late final AuthService _authService;
  late final CloudinaryPublic _cloudinary;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _cloudinary = widget.cloudinary ?? CloudinaryPublic('dooef2crr', 'TWC123', cache: false);
  }

  // --- NEW VARIABLES FOR IMAGE ---
  File? _imageFile;
  Uint8List? _webImage;
  File? _disabilityCardFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _disabilityTypes = [
    'Physical disability',
    'Sensory disability',
    'Intellectual disability',
    'Psychological disability',
    'Other disability',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _civilIdController.dispose();
    _disabilityController.dispose();
    super.dispose();
  }

  // --- NEW: PICK IMAGE FUNCTION ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        // For Web: Read bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          // We use a dummy File object or just keep _imageFile null on web
          _imageFile = File(pickedFile.path);
        });
      } else {
        // For Mobile: Normal File usage
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    }
  }

  // --- NEW: OCR LOGIC FOR CIVIL ID ---
  Future<void> _scanCivilId() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String extractedDigits = "";
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          // Look for an 8 or more digit number which could be a Civil ID
          final RegExp regExp = RegExp(r'\b\d{8,14}\b');
          final match = regExp.firstMatch(line.text);
          if (match != null) {
            extractedDigits = match.group(0)!;
            break;
          }
        }
        if (extractedDigits.isNotEmpty) break;
      }

      await textRecognizer.close();

      if (extractedDigits.isNotEmpty) {
        setState(() {
          _civilIdController.text = extractedDigits;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Civil ID extracted successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not detect Civil ID number. Please enter manually.')),
          );
        }
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_imageFile == null || _disabilityCardFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload profile image and disability card')));
        setState(() => _isLoading = false);
        return;
      }

      String profileImageUrl = "";

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _imageFile!.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      profileImageUrl = response.secureUrl;

      String disabilityCardUrl = "";
      CloudinaryResponse cardResponse = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _disabilityCardFile!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'beneficiary_cards'
        ),
      );
      disabilityCardUrl = cardResponse.secureUrl;

      // --- UPDATED: SEND profileImageUrl TO AUTH SERVICE ---
      final user = await _authService.registerBeneficiary(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        disabilityType: _disabilityController.text.trim(),
        profileImage: profileImageUrl,
        disabilityCardUrl: disabilityCardUrl,
        civilIdText: _civilIdController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (user != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  ImageProvider? _imageProvider() {
    if (kIsWeb) {
      return _webImage != null ? MemoryImage(_webImage!) : null;
    } else {
      return _imageFile != null ? FileImage(_imageFile!) : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final inputFill = isDark ? Colors.grey[800]! : const Color(0xFF9EA0F2);
    final footerFill = isDark ? Colors.grey[900]! : const Color(0xFF9EA0F2);
    final redButton = Theme.of(context).colorScheme.primary;

    InputDecoration inputDecoration({String? hintText}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        filled: true,
        fillColor: inputFill,
        border: InputBorder.none,
      );
    }

    return DynamicBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Register Beneficiary'.tr),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // --- NEW: PROFILE IMAGE PICKER UI ---
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  backgroundImage: _imageProvider(),
                                  child: (_webImage == null && _imageFile == null)
                                      ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : null,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Information',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Full Name
                              Text(
                                'Full Name'.tr,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fullNameController,
                                validator: Validators.validateFullName,
                                decoration: const InputDecoration(hintText: 'Enter Your Name'),
                              ),

                              const SizedBox(height: 20),
                              // Civil ID with OCR Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Civil ID'.tr,
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  TextButton.icon(
                                    onPressed: _scanCivilId,
                                    icon: const Icon(Icons.document_scanner, size: 18),
                                    label: Text("Scan ID".tr, style: const TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _civilIdController,
                                keyboardType: TextInputType.number,
                                validator: (val) => val != null && val.length >= 8 ? null : 'Enter valid Civil ID',
                                decoration: const InputDecoration(hintText: 'e.g. 12345678'),
                              ),

                              const SizedBox(height: 20),
                              // Email
                              Text(
                                'Email'.tr,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                validator: Validators.validateEmail,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(hintText: 'email@example.com'),
                              ),

                              const SizedBox(height: 20),
                              // Password
                              Text(
                                'Password'.tr,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: Validators.validatePassword,
                                decoration: InputDecoration(
                                  hintText: '******',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              // Phone
                              Text(
                                'Phone No'.tr,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                validator: Validators.validatePhone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(hintText: '9X XX XX XX'),
                              ),

                              const SizedBox(height: 32),
                              
                              Text(
                                'Disability Details',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Disability Dropdown
                              Text(
                                'Disability Type'.tr,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(hintText: 'Select Disability Type'),
                                items: _disabilityTypes
                                    .map((t) => DropdownMenuItem(value: t, child: Text(t.tr)))
                                    .toList(),
                                onChanged: (v) => _disabilityController.text = v ?? '',
                                validator: (v) => (v == null || v.isEmpty) ? 'Please select' : null,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              Text(
                                'Disability Card Upload'.tr,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                                    if (image != null) {
                                      setState(() => _disabilityCardFile = File(image.path));
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                                  label: Text(
                                    _disabilityCardFile != null ? 'Card Selected' : 'Upload Disability Card',
                                    style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'REGISTER'.tr,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
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
  }
}
