import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';

class VolunteerDocumentsScreen extends StatefulWidget {
  const VolunteerDocumentsScreen({super.key});

  @override
  State<VolunteerDocumentsScreen> createState() =>
      _VolunteerDocumentsScreenState();
}

class _VolunteerDocumentsScreenState extends State<VolunteerDocumentsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  String? _experienceUrl;
  String? _idCardUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingDocs();
  }

  void _showImagePreview(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Image
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
            // Close Button
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Title label at bottom
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title.tr,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadExistingDocs() async {
    if (user == null) return;
    var doc = await FirebaseFirestore.instance
        .collection('volunteers')
        .doc(user!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _experienceUrl = doc.data()?['experienceCertificateUrl'];
        _idCardUrl = doc.data()?['idCardUrl'];
      });
    }
  }

  Future<void> _uploadDocument(String fieldName) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final cloudinary = CloudinaryPublic('dooef2crr', 'TWC123', cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          pickedFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(user!.uid)
          .update({fieldName: response.secureUrl});

      setState(() {
        if (fieldName == 'experienceCertificateUrl')
          _experienceUrl = response.secureUrl;
        if (fieldName == 'idCardUrl') _idCardUrl = response.secureUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Upload Successful!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Required Documents".tr),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Please upload your documents for verification.".tr,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 32),
                  _documentTile(
                    "Experience Certificate".tr,
                    _experienceUrl,
                    () => _uploadDocument('experienceCertificateUrl'),
                  ),
                  const SizedBox(height: 24),
                  _documentTile(
                    "Civil / Resident Card".tr,
                    _idCardUrl,
                    () => _uploadDocument('idCardUrl'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _documentTile(String title, String? url, VoidCallback onTap) {
    bool hasFile = url != null && url.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasFile ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              color: hasFile ? Colors.green : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasFile ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasFile ? "Uploaded".tr : "No file selected".tr,
                    style: GoogleFonts.inter(
                      color: hasFile ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 👁️ VIEW ICON (Only shows if file exists)
          if (hasFile)
            IconButton(
              icon: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
              onPressed: () => _showImagePreview(url, title),
            ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(hasFile ? "Update".tr : "Upload".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
