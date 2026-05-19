import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twc/screens/registration_type_screen.dart';
import 'package:twc/services/auth_service.dart';
import 'package:twc/widgets/custom_text_field.dart';
import 'package:twc/utils/validators.dart';
import 'forgot_password_screen.dart';
import 'register_beneficiary_screen.dart';
import 'register_volunteer_screen.dart';
import 'beneficiary_volunteer_dashboard.dart';
import 'Admin/admin_dashboard.dart';
import 'volunteer/volunteer_dashboard.dart';
import 'beneficiary/beneficiary_dashbaord.dart';
import 'force_change_password_screen.dart';
import 'force_change_password_screen.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:twc/utils/app_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/widgets/dynamic_background.dart';
import 'package:twc/widgets/glass_card.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onThemeToggle; // Add this
  final AuthService? authService; // Add DI

  const LoginScreen({
    super.key,
    required this.onThemeToggle,
    this.authService,
  }); // Update constructor

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final AuthService _authService;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Add this import at the top

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final user = await _authService.loginUser(email, password);
      if (user == null) return;

      String? userType = await _authService.getUserType(user.uid);

      // --- Trigger Web-Safe Notification ---
      _sendWebLoginEmail(email);

      if (mounted) {
        String userName = "User";
        if (userType != 'admin' && userType != null) {
          String collection = userType == 'volunteer' ? 'volunteers' : 'beneficiaries';
          try {
            var userDoc = await FirebaseFirestore.instance.collection(collection).doc(user.uid).get();
            if (userDoc.exists) {
              userName = userDoc.get('fullName') ?? "User";
            }
          } catch(e) {}
        } else if (userType == 'admin') {
          userName = "Admin";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to TWC $userName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      bool requiresPasswordChange = false;
      if (userType == 'volunteer') {
        var doc = await FirebaseFirestore.instance.collection('volunteers').doc(user.uid).get();
        if (doc.exists && doc.data()!['requiresPasswordChange'] == true) {
          requiresPasswordChange = true;
        }
      } else if (userType == 'beneficiary') {
        var doc = await FirebaseFirestore.instance.collection('beneficiaries').doc(user.uid).get();
        if (doc.exists && doc.data()!['requiresPasswordChange'] == true) {
          requiresPasswordChange = true;
        }
      }

      if (requiresPasswordChange) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ForceChangePasswordScreen(
                userType: userType!,
                onThemeToggle: widget.onThemeToggle,
              ),
            ),
          );
        }
        return;
      }

      //  Navigation Logic
      if (userType == 'admin' || email == AuthService.adminEmail) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(onThemeToggle: widget.onThemeToggle),
          ),
        );
        return;
      }

      if (userType == 'volunteer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VolunteerDashboard(onThemeToggle: widget.onThemeToggle),
          ),
        );
        return;
      }

      if (userType == 'beneficiary') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BeneficiaryDashbaord(onThemeToggle: widget.onThemeToggle),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User role not found."),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Web-safe Email Function using EmailJS (or any HTTP-based API)
  Future<void> _sendWebLoginEmail(String recipientEmail) async {
    // Use your actual IDs from EmailJS
    const String serviceId = 'service_itam0vn';
    const String templateId = 'template_nfa9wej';
    const String publicKey = 'uZCtwv_G_7ZiCeTVX';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    // Clean format for the email: "Monday, 09 March 2026"
    final String currentTime = DateFormat(
      'EEEE, dd MMMM yyyy',
    ).format(DateTime.now());

    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'user_email': recipientEmail, // The "To" address in EmailJS
            'login_time': currentTime,
            'from_name': 'The TWC Team', // Matches {{login_time}} in template
          },
        }),
      );
      debugPrint('Login email triggered for $recipientEmail');
    } catch (e) {
      debugPrint('Email error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      size: 28,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Hero(
                                    tag: 'logo',
                                    child: Image.network(
                                      'https://res.cloudinary.com/dv2x9fveq/image/upload/v1765480794/IMG_4695_k6exsh.png',
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Login'.tr,
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 40),

                              Card(
                                elevation: 4,
                                shadowColor: Colors.black12,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Email'.tr,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                              CustomTextField(
                                controller: _emailController,
                                labelText: '',
                                hintText: '',
                                keyboardType: TextInputType.emailAddress,
                                errorText: Validators.validateEmail(
                                  _emailController.text,
                                ),
                              ),

                                      const SizedBox(height: 24),

                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Password'.tr,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                              CustomTextField(
                                controller: _passwordController,
                                labelText: '',
                                hintText: '',
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                errorText: Validators.validatePassword(
                                  _passwordController.text,
                                ),
                              ),

                                      const SizedBox(height: 16),

                                      // Forgot Password
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            'Forgot Password?'.tr,
                                            style: GoogleFonts.inter(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 32),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 55,
                                        child: ElevatedButton(
                                          onPressed: _isLoading ? null : _login,
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
                                                  'LOGIN',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    letterSpacing: 1.2,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Register Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ".tr,
                                    style: GoogleFonts.inter(color: Colors.grey.shade600),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RegistrationTypeScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Register here',
                                      style: GoogleFonts.inter(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
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
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
}
