import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';

class VolunteerCertificateScreen extends StatefulWidget {
  final String? volunteerId;
  const VolunteerCertificateScreen({super.key, this.volunteerId});

  @override
  State<VolunteerCertificateScreen> createState() =>
      _VolunteerCertificateScreenState();
}

class _VolunteerCertificateScreenState
    extends State<VolunteerCertificateScreen> {
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = widget.volunteerId ?? FirebaseAuth.instance.currentUser?.uid ?? "";
  }

  final String todayDate = DateFormat('d/M/yyyy').format(DateTime.now());
  bool _isDownloading = false;

  // Constants for styling to match the image
  static const Color themePurple = Color(0xFF9EA4FF);
  static const Color darkBrown = Color(0xFF5D4037);
  static const Color darkGrey = Color(0xFF424242);

  Future<String> _getVolunteerName() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(currentUserId)
          .get();
      if (doc.exists) {
        return doc.get('fullName') ?? "User Name";
      }
    } catch (e) {
      debugPrint("Error fetching name: $e");
    }
    return "User Name";
  }

  // --- PDF GENERATION LOGIC ---
  Future<void> _generateAndDownloadPDF(
    String volunteerName,
    String volunteerType,
  ) async {
    setState(() => _isDownloading = true);

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.merriweatherRegular();
    final boldFont = await PdfGoogleFonts.merriweatherBold();
    final bgImage = await imageFromAssetBundle('assets/images/certificate.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Image(bgImage, fit: pw.BoxFit.fill),
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: 140),
                    pw.Text(
                      "CERTIFICATE",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 34,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      "OF RECOGNITION",
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 18,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      "THIS CERTIFICATE IS PRESENTED TO",
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      volunteerName.toUpperCase(),
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 30,
                        color: PdfColors.brown900,
                      ),
                    ),
                    pw.SizedBox(height: 25),
                    pw.Text(
                      "IN RECOGNITION OF",
                      style: pw.TextStyle(font: font, fontSize: 12),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      volunteerType.toUpperCase(),
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 28,
                        letterSpacing: 2,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 25),
                    pw.SizedBox(
                      width: 300,
                      child: pw.Text(
                        "FOR YOUR OUTSTANDING PERFORMANCE AND DEDICATION",
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ),
                    pw.SizedBox(height: 70),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 180),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            todayDate,
                            style: pw.TextStyle(font: boldFont, fontSize: 14),
                          ),
                          pw.Container(
                            width: 80,
                            height: 1,
                            color: PdfColors.black,
                          ),
                          pw.Text(
                            "Date",
                            style: pw.TextStyle(font: font, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
    setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Certificate'.tr),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Hero(
              tag: 'logo',
              child: Image.asset(
                'assets/images/twc.png',
                width: 40,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.handshake, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getVolunteerName(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String name = snapshot.data ?? "User Name";
          String userType = "VOLUNTEER";

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Background Image
                      Image.asset(
                        "assets/images/certificate.png",
                        fit: BoxFit.contain,
                      ),

                      // 2. All Text Labels and Dynamic Content
                      Positioned(
                        top: 150,
                        child: Column(
                          children: [
                            Text(
                              "CERTIFICATE",
                              style: GoogleFonts.merriweather(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: darkGrey,
                              ),
                            ),
                            Text(
                              "OF RECOGNITION",
                              style: GoogleFonts.merriweather(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkGrey,
                              ),
                            ),
                            const SizedBox(height: 35),
                            Text(
                              "THIS CERTIFICATE IS PRESENTED TO",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              name,
                              style: GoogleFonts.merriweather(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: darkBrown,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "IN RECOGNITION OF",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              userType,
                              style: GoogleFonts.merriweather(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: darkGrey,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 280,
                              child: Text(
                                "FOR YOUR OUTSTANDING PERFORMANCE AND DEDICATION",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Date Section
                      Positioned(
                        bottom: 150,
                        left: 105,
                        child: Column(
                          children: [
                            Text(
                              todayDate,
                              style: GoogleFonts.merriweather(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Date",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- DOWNLOAD BUTTON ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading
                        ? null
                        : () => _generateAndDownloadPDF(name, userType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download, color: Colors.white),
                    label: Text(
                      _isDownloading ? "Generating PDF...".tr : "Download as PDF".tr,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
          );
        },
      ),
    );
  }
}
