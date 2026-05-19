import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageBeneficiaryScreen extends StatefulWidget {
  const ManageBeneficiaryScreen({super.key});

  @override
  State<ManageBeneficiaryScreen> createState() => _ManageBeneficiaryScreenState();
}

class _ManageBeneficiaryScreenState extends State<ManageBeneficiaryScreen> {
  String searchQuery = "";


  // 🗑 DELETE
  Future<void> _deleteBeneficiary(BuildContext context, String docId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to remove this beneficiary?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('beneficiaries')
          .doc(docId)
          .delete();
    }
  }

  // 👁 VIEW DETAILS
  void _viewDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Beneficiary Details".tr,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailItem(context, "Full Name".tr, data['fullName']),
              _detailItem(context, "Email".tr, data['email']),
              _detailItem(context, "Gender".tr, data['gender']),
              _detailItem(context, "Disability".tr, data['disabilityType']),
              _detailItem(context, "User Type".tr, data['userType']),
              if (data['disabilityCardUrl'] != null && data['disabilityCardUrl'].toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text("Disability Card:".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(data['disabilityCardUrl'], fit: BoxFit.contain),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            data['disabilityCardUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(child: Text("Error loading image".tr)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Close".tr,
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(BuildContext context, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: "${value ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }

  void _showBeneficiaryForm(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) {
    final nameController = TextEditingController(text: data?['fullName'] ?? '');
    final emailController = TextEditingController(text: data?['email'] ?? '');

    List<String> genderOptions = ['Male', 'Female', 'Other'];
    List<String> disabilityOptions = [
      'Physical disability',
      'Sensory disability',
      'Intellectual disability',
      'Psychological disability',
      'Other disability',
    ];

    String selectedGender = data?['gender'] ?? 'Male';
    String selectedDisability = data?['disabilityType'] ?? 'Other disability';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            docId == null ? "Add Beneficiary".tr : "Update Beneficiary".tr,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(context, nameController, "Full Name".tr),
                const SizedBox(height: 16),
                _buildTextField(context, emailController, "Email".tr),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: _inputDecoration(context, "Gender".tr),
                  items: genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedGender = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDisability,
                  decoration: _inputDecoration(context, "Disability Type".tr),
                  items: disabilityOptions
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedDisability = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel".tr, style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(email)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid email format'.tr)));
                  }
                  return;
                }

                final Map<String, dynamic> payload = {
                  'fullName': nameController.text.trim(),
                  'email': email,
                  'gender': selectedGender,
                  'disabilityType': selectedDisability,
                  'userType': 'beneficiary',
                  if (docId == null) 'requiresPasswordChange': true,
                };

                if (docId == null) {
                  try {
                    final authService = AuthService();
                    String generatedPassword = authService.generateRandomPassword();
                    User? newUser = await authService.adminCreateUser(payload['email'] as String, generatedPassword);
                    if (newUser != null) {
                      payload['createdAt'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance
                          .collection('beneficiaries')
                          .doc(newUser.uid)
                          .set(payload);
                      await authService.sendAdminCreatedEmail(payload['email'] as String, payload['fullName'] as String, generatedPassword);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User added and email sent successfully!'.tr)));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                } else {
                  await FirebaseFirestore.instance
                      .collection('beneficiaries')
                      .doc(docId)
                      .update(payload);
                }
                if (context.mounted) Navigator.pop(ctx);
              },
              child: Text(docId == null ? "Add".tr : "Update".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(context, label),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showBeneficiaryForm(context),
        icon: const Icon(Icons.add),
        label: Text("Add".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        title: Text("Manage Beneficiary".tr),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: "Search by disability".tr,
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    searchQuery = val.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('beneficiaries')
                      .where('userType', isEqualTo: 'beneficiary')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }
                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No beneficiaries found".tr,
                          style: GoogleFonts.inter(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      if (searchQuery.isEmpty) return true;
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      String disability = (data['disabilityType'] ?? '').toString().toLowerCase();
                      return disability.contains(searchQuery);
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No matching beneficiaries".tr,
                          style: GoogleFonts.inter(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return _beneficiaryRow(
                          context,
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 80), // for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _beneficiaryRow(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['fullName'] ?? '',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        data['disabilityType'] ?? 'None',
                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (data['disabilityCardUrl'] != null && data['disabilityCardUrl'].toString().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.credit_card, color: Colors.blueAccent),
                    onPressed: () async {
                      final url = Uri.parse(data['disabilityCardUrl']);
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    tooltip: "View Disability Card",
                  ),
                IconButton(
                  icon: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                  onPressed: () => _viewDetails(context, data),
                  tooltip: "View Detail",
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showBeneficiaryForm(context, docId: docId, data: data),
                  tooltip: "Edit",
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteBeneficiary(context, docId),
                  tooltip: "Delete",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
