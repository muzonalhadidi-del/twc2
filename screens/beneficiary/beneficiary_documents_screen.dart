import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_fonts/google_fonts.dart';

class BeneficiaryDocumentsScreen extends StatefulWidget {
  const BeneficiaryDocumentsScreen({super.key});

  @override
  State<BeneficiaryDocumentsScreen> createState() =>
      _BeneficiaryDocumentsScreenState();
}

class _BeneficiaryDocumentsScreenState
    extends State<BeneficiaryDocumentsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _disabilityCertUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingDocs();
  }

  Future<void> _loadExistingDocs() async {
    if (user == null) return;
    var doc = await FirebaseFirestore.instance
        .collection('beneficiaries')
        .doc(user!.uid)
        .get();
    if (doc.exists) {
      setState(() {
        _disabilityCertUrl = doc.data()?['disabilityCertificateUrl'];
      });
    }
  }

  Future<void> _uploadDocument() async {
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
          .collection('beneficiaries')
          .doc(user!.uid)
          .update({'disabilityCertificateUrl': response.secureUrl});

      setState(() {
        _disabilityCertUrl = response.secureUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document Uploaded Successfully!")),
        );
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

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                "Document Preview",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (url.isNotEmpty)
              Image.network(url, fit: BoxFit.contain)
            else
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Invalid Document URL"),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasFile = _disabilityCertUrl != null && _disabilityCertUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Verification Documents",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text("Uploading Document...", style: GoogleFonts.inter(fontSize: 16)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upload Documents",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Verification status helps us provide better priority support and match you with the right volunteers.",
                    style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 32),
                  _documentCard(
                    "Disability Certificate / Card",
                    hasFile,
                    () => _uploadDocument(),
                    hasFile
                        ? () => _showImagePreview(_disabilityCertUrl!)
                        : null,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _documentCard(
    String title,
    bool uploaded,
    VoidCallback onUpload,
    VoidCallback? onView,
  ) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: uploaded ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                uploaded ? Icons.verified_user : Icons.cloud_upload_outlined,
                color: uploaded ? Colors.green : Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    uploaded ? "Status: Verified" : "Status: Pending",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: uploaded ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (uploaded)
              IconButton(
                icon: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                onPressed: onView,
                tooltip: "View Document",
              ),
            ElevatedButton(
              onPressed: onUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: uploaded ? Colors.grey.shade200 : Theme.of(context).colorScheme.primary,
                foregroundColor: uploaded ? Colors.black87 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: uploaded ? 0 : 2,
              ),
              child: Text(
                uploaded ? "Update" : "Upload",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
