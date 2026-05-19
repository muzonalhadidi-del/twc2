import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twc/screens/volunteer/certificate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'VolunteerReportScreen.dart';
import 'VolunteerScheduleScreen.dart';
import 'ReportViewerScreen.dart';

class VolunteerSelectionScreen extends StatefulWidget {
  final String mode; // "report" or "schedule" or "certificate"
  final bool hideAppBar;

  const VolunteerSelectionScreen({super.key, required this.mode, this.hideAppBar = false});

  @override
  State<VolunteerSelectionScreen> createState() => _VolunteerSelectionScreenState();
}

class _VolunteerSelectionScreenState extends State<VolunteerSelectionScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.hideAppBar ? null : AppBar(
        title: Text(
          widget.mode == "report"
              ? "Select for Report".tr
              : widget.mode == "certificate"
              ? "Select for Certificate".tr
              : "Select for Schedule".tr,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Name / Email...'.tr,
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          if (widget.mode == "report" && searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("General Growth Reports".tr, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _growthCard(context, "Volunteer Growth".tr, Icons.group_add, "volunteers"),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _growthCard(context, "Beneficiary Growth".tr, Icons.accessibility_new, "beneficiaries"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('volunteers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No volunteers found".tr, style: GoogleFonts.inter(color: Colors.grey.shade600)));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  if (searchQuery.isEmpty) return true;
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  String name = (data['fullName'] ?? '').toString().toLowerCase();
                  String email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery) || email.contains(searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(child: Text("No matching volunteers found".tr, style: GoogleFonts.inter(color: Colors.grey.shade600)));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String name = data['fullName'] ?? 'Unknown';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(data['email'] ?? '', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                        onTap: () async {
                          if (widget.mode == "report") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VolunteerReportScreen(
                                  volunteerId: doc.id,
                                  volunteerName: name,
                                ),
                              ),
                            );
                          } else if (widget.mode == "certificate") {
                            final snapshot = await FirebaseFirestore.instance.collection('beneficiaries_request').where('volunteerId', isEqualTo: doc.id).get();
                            bool hasIncomplete = false;
                            bool hasAny = false;
                            for (var req in snapshot.docs) {
                              hasAny = true;
                              if (req.data()['status'] != 'completed') {
                                hasIncomplete = true;
                                break;
                              }
                            }
                            if (hasAny && !hasIncomplete) {
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VolunteerCertificateScreen(
                                      volunteerId: doc.id,
                                    ),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("First complete all tasks".tr)),
                                );
                              }
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VolunteerScheduleScreen(
                                  volunteerId: doc.id,
                                  volunteerName: name,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _growthCard(BuildContext context, String title, IconData icon, String collection) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportViewerScreen(title: title, collection: collection),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}