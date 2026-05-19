import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/widgets/custom_text_field.dart';
import 'package:twc/widgets/dynamic_background.dart';
import 'volunteer/volunteer_dashboard.dart';
import 'beneficiary/beneficiary_dashbaord.dart';

class ForceChangePasswordScreen extends StatefulWidget {
  final String userType;
  final VoidCallback onThemeToggle;

  const ForceChangePasswordScreen({
    super.key,
    required this.userType,
    required this.onThemeToggle,
  });

  @override
  State<ForceChangePasswordScreen> createState() => _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends State<ForceChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match'.tr)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(_passwordController.text);

        // Update Firestore flag
        String collection = widget.userType == 'volunteer' ? 'volunteers' : 'beneficiaries';
        await FirebaseFirestore.instance.collection(collection).doc(user.uid).update({
          'requiresPasswordChange': false,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password changed successfully!'.tr)),
          );
          if (widget.userType == 'volunteer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => VolunteerDashboard(onThemeToggle: widget.onThemeToggle)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BeneficiaryDashbaord(onThemeToggle: widget.onThemeToggle)),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e'.tr)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("Change Password".tr),
          automaticallyImplyLeading: false, // Force them to stay here
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Action Required".tr,
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your account was created by an admin. For security, please change your password now.".tr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'New Password'.tr,
                        hintText: '',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        errorText: _passwordController.text.length < 6 ? 'Password must be at least 6 characters'.tr : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password'.tr,
                        hintText: '',
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'CHANGE PASSWORD'.tr,
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
