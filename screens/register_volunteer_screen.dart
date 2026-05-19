import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:twc/services/auth_service.dart';
import 'package:twc/utils/validators.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/widgets/dynamic_background.dart';
import 'package:twc/widgets/glass_card.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class RegisterVolunteerScreen extends StatefulWidget {
  final AuthService? authService;
  final CloudinaryPublic? cloudinary;

  const RegisterVolunteerScreen({super.key, this.authService, this.cloudinary});

  @override
  _RegisterVolunteerScreenState createState() =>
      _RegisterVolunteerScreenState();
}

class _RegisterVolunteerScreenState extends State<RegisterVolunteerScreen> {
  late final CloudinaryPublic _cloudinary;
  late final AuthService _authService;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _civilIdController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedGender;
  String? _selectedSkill;
  XFile? _pickedFile;
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _skillOptions = [
    'Physical assistance',
    'Sensory assistance',
    'Intellectual assistance',
    'Psychological assistance',
    'Other assistance'
  ];
  XFile? _cvFile;
  XFile? _civilIdFile;

  @override
  void initState() {
    super.initState();
    _cloudinary = widget.cloudinary ?? CloudinaryPublic('dooef2crr', 'TWC123', cache: false);
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _civilIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image != null) {
      setState(() {
        _pickedFile = image;
      });
    }
  }

  // --- NEW: OCR LOGIC FOR CIVIL ID ---
  Future<void> _scanCivilId() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final inputImage = InputImage.fromFilePath(pickedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String extractedDigits = "";
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
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

    if (_pickedFile == null || _cvFile == null || _civilIdFile == null) {
      _showSnackBar('Please complete all fields, and uploads', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _pickedFile!.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'volunteers',
        ),
      );

      String imageUrl = response.secureUrl;

      CloudinaryResponse cvResponse = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(_cvFile!.path, resourceType: CloudinaryResourceType.Image, folder: 'volunteers_cv'),
      );
      String cvUrl = cvResponse.secureUrl;

      CloudinaryResponse civilIdResponse = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(_civilIdFile!.path, resourceType: CloudinaryResourceType.Image, folder: 'volunteers_civilId'),
      );
      String civilIdUrl = civilIdResponse.secureUrl;

      final user = await _authService.registerVolunteer(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gender: _selectedGender!,
        skills: _selectedSkill ?? 'Other assistance',
        profileImageUrl: imageUrl,
        assistanceTypes: [_selectedSkill ?? 'Other assistance'],
        cvUrl: cvUrl,
        civilIdUrl: civilIdUrl,
        civilIdText: _civilIdController.text.trim(),
      );

      if (user != null) {
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar('Registration successful!', Colors.green);
        }
      } else {
        throw Exception("Registration failed.");
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final inputFill = isDark ? Colors.grey[800]! : const Color(0xFF9EA0F2);
    final footerPurple = isDark ? Colors.grey[900]! : const Color(0xFF9EA0F2);
    final redButton = Theme.of(context).colorScheme.primary;

    InputDecoration inputDecoration({String? hintText}) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: InputBorder.none,
      );
    }

    final labelStyle = TextStyle(
      fontFamily: 'Georgia',
      fontSize: 18,
      color: Theme.of(context).textTheme.bodyLarge?.color,
    );

    return DynamicBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Register Volunteer'.tr),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image
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
                                  backgroundImage: _pickedFile != null ? NetworkImage(_pickedFile!.path) : null,
                                  child: _pickedFile == null
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

                              Text('Full Name'.tr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fullNameController,
                                validator: Validators.validateFullName,
                                decoration: const InputDecoration(hintText: 'Enter Your Name'),
                              ),
                              const SizedBox(height: 20),

                              Text('Email'.tr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                validator: Validators.validateEmail,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(hintText: 'email@example.com'),
                              ),
                              const SizedBox(height: 20),

                              Text('Password'.tr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
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

                              Text('Phone No'.tr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                validator: Validators.validatePhone,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(hintText: '9X XX XX XX'),
                              ),
                              const SizedBox(height: 20),

                              Text('Gender'.tr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(hintText: 'Select Gender'),
                                value: _selectedGender,
                                items: _genderOptions
                                    .map((g) => DropdownMenuItem(value: g, child: Text(g.tr)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedGender = v),
                                validator: (v) => v == null ? 'Please select' : null,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              Text(
                                'Skills & Documents',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text('Primary Skill'.tr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(hintText: 'Select Primary Skill'),
                                value: _selectedSkill,
                                items: _skillOptions
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s.tr)))
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedSkill = v),
                                validator: (v) => v == null ? 'Please select' : null,
                              ),
                              const SizedBox(height: 20),

                              Text('CV Upload'.tr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                                    if (file != null) setState(() => _cvFile = file);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                                  label: Text(
                                    _cvFile != null ? 'CV Selected' : 'Upload CV',
                                    style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Text('Civil ID Upload'.tr, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                                    if (file != null) setState(() => _civilIdFile = file);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary),
                                  label: Text(
                                    _civilIdFile != null ? 'ID Selected' : 'Upload Civil ID',
                                    style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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