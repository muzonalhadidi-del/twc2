import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:twc/services/encryption_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageVolunteerScreen extends StatefulWidget {
  const ManageVolunteerScreen({super.key});

  @override
  State<ManageVolunteerScreen> createState() => _ManageVolunteerScreenState();
}

class _ManageVolunteerScreenState extends State<ManageVolunteerScreen> {
  String searchQuery = "";

  // 🗑 DELETE
  Future<void> _deleteVolunteer(BuildContext context, String docId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
              "Are you sure you want to remove this volunteer?",
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
          .collection('volunteers')
          .doc(docId)
          .delete();
    }
  }

  // 👁 VIEW DETAILS
  void _viewVolunteerDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Volunteer Details".tr,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailItem(context, "Full Name".tr, data['fullName']),
              _detailItem(context, "Email".tr, data['email']),
              _detailItem(context, "Phone".tr, EncryptionHelper.decryptData(data['phoneNumber'] ?? '')),
              _detailItem(context, "Gender".tr, data['gender']),
              _detailItem(context, "Primary Skill".tr, data['skills'] ?? 'General'),
              _detailItem(context, "User Type".tr, data['userType']),
              if (data['cvUrl'] != null && data['cvUrl'].toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text("CV / Resume:".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(data['cvUrl'], fit: BoxFit.contain),
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
                            data['cvUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(child: Text("Error loading CV".tr)),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text("CV / Resume: Not Uploaded".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
                ),
              if (data['civilIdUrl'] != null && data['civilIdUrl'].toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                      child: Text("Civil ID:".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(data['civilIdUrl'], fit: BoxFit.contain),
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
                            data['civilIdUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(child: Text("Error loading Civil ID".tr)),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text("Civil ID: Not Uploaded".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red)),
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

  // 📝 VOLUNTEER FORM (Create & Update)
  void _showVolunteerForm(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) {
    final nameController = TextEditingController(text: data?['fullName'] ?? '');
    final emailController = TextEditingController(text: data?['email'] ?? '');
    final phoneController = TextEditingController(
      text: EncryptionHelper.decryptData(data?['phoneNumber'] ?? ''),
    );

    List<String> genderOptions = ['Male', 'Female', 'Other'];
    String rawGender = data?['gender'] ?? 'Male';
    String formattedGender = rawGender.isNotEmpty
        ? rawGender[0].toUpperCase() + rawGender.substring(1).toLowerCase()
        : 'Male';
    String selectedGender = genderOptions.contains(formattedGender)
        ? formattedGender
        : 'Male';

    List<String> skillOptions = [
      'Physical assistance',
      'Sensory assistance',
      'Intellectual assistance',
      'Psychological assistance',
      'Other assistance'
    ];
    String rawSkill = data?['skills'] ?? 'Other assistance';
    String selectedSkill = skillOptions.contains(rawSkill) ? rawSkill : 'Other assistance';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            docId == null ? "Add Volunteer".tr : "Update Volunteer".tr,
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
                _buildTextField(context, phoneController, "Phone Number".tr, isPhone: true),
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
                  value: selectedSkill,
                  decoration: _inputDecoration(context, "Skills".tr),
                  items: skillOptions
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedSkill = val!),
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

                final payload = {
                  'fullName': nameController.text.trim(),
                  'email': email,
                  'phoneNumber': EncryptionHelper.encryptData(phoneController.text.trim()),
                  'gender': selectedGender,
                  'skills': selectedSkill,
                  'assistanceTypes': [selectedSkill],
                  'userType': 'volunteer',
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
                          .collection('volunteers')
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
                      .collection('volunteers')
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

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    bool isPhone = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
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
        onPressed: () => _showVolunteerForm(context),
        icon: const Icon(Icons.add),
        label: Text("Add".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        title: Text("Manage Volunteer".tr),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: "Search by skills".tr,
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
                      .collection('volunteers')
                      .where('userType', isEqualTo: 'volunteer')
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
                          "No volunteers found".tr,
                          style: GoogleFonts.inter(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs.where((doc) {
                      if (searchQuery.isEmpty) return true;
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      String skills = (data['skills'] ?? '').toString().toLowerCase();
                      return skills.contains(searchQuery);
                    }).toList();

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No matching volunteers".tr,
                          style: GoogleFonts.inter(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return _volunteerRow(
                          context: context,
                          docId: doc.id,
                          data: doc.data() as Map<String, dynamic>,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 80), // For FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _volunteerRow({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
  }) {
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
                  child: Icon(Icons.volunteer_activism, color: Theme.of(context).colorScheme.primary),
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
                        data['email'] ?? '',
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
                if (data['cvUrl'] != null && data['cvUrl'].toString().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.description, color: Colors.blueAccent),
                    onPressed: () async {
                      final url = Uri.parse(data['cvUrl']);
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    tooltip: "View CV",
                  ),
                if (data['civilIdUrl'] != null && data['civilIdUrl'].toString().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.badge, color: Colors.orangeAccent),
                    onPressed: () async {
                      final url = Uri.parse(data['civilIdUrl']);
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                    tooltip: "View Civil ID",
                  ),
                IconButton(
                  icon: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                  onPressed: () => _viewVolunteerDetails(context, data),
                  tooltip: "View Detail",
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showVolunteerForm(context, docId: docId, data: data),
                  tooltip: "Edit",
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteVolunteer(context, docId),
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
