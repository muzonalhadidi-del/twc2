import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';

class ManageRequestsScreen extends StatelessWidget {
  const ManageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Manage Requests (Assignments)".tr),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('beneficiaries_request')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests found."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              String service = data['serviceType'] ?? 'Unknown';
              String detail = data['subService'] ?? data['details'] ?? 'No detail';
              String status = data['status'] ?? 'pending';
              String currentVolunteerId = data['volunteerId'] ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "$service - $detail",
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'done' ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase().tr,
                              style: GoogleFonts.inter(
                                color: status == 'done' ? Colors.green.shade700 : Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            "${data['bookingDate']}  •  ${data['bookingTime']}",
                            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<DocumentSnapshot>(
                        future: currentVolunteerId.isNotEmpty
                            ? FirebaseFirestore.instance
                                .collection('volunteers')
                                .doc(currentVolunteerId)
                                .get()
                            : null,
                        builder: (ctx, volSnapshot) {
                          String volName = "Not Assigned";
                          if (volSnapshot.hasData && volSnapshot.data!.exists) {
                            var vData =
                                volSnapshot.data!.data() as Map<String, dynamic>;
                            volName = vData['fullName'] ?? "Unknown";
                          }
                          return Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Assigned To: $volName".tr,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showAssignDialog(context, doc.id, service),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.person_add, color: Colors.white, size: 20),
                          label: Text(
                            "Manually Assign".tr,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAssignDialog(
      BuildContext context, String requestId, String serviceType) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            "Select Volunteer to Assign".tr,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('volunteers')
                  .where('userType', isEqualTo: 'volunteer')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
                }

                var volunteers = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: volunteers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var vDoc = volunteers[index];
                    var vData = vDoc.data() as Map<String, dynamic>;
                    String name = vData['fullName'] ?? 'Unknown';
                    String skill = vData['skills'] ?? 'General';
                    
                    bool isRecommended = false;
                    if (serviceType == 'Transport' && skill == 'Transport') isRecommended = true;
                    if (serviceType == 'Appointment' && skill == 'Medical') isRecommended = true;
                    if (serviceType == 'Shopping' && skill == 'Caregiver') isRecommended = true;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      subtitle: Text("Skill: $skill".tr, style: GoogleFonts.inter(fontSize: 12)),
                      trailing: isRecommended 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.orange.shade400, size: 16),
                              const SizedBox(width: 4),
                              Text("Recommended".tr, style: GoogleFonts.inter(fontSize: 10, color: Colors.orange.shade600, fontWeight: FontWeight.bold)),
                            ],
                          ) 
                        : null,
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('beneficiaries_request')
                            .doc(requestId)
                            .update({
                              'volunteerId': vDoc.id,
                              'volunteerGender': vData['gender'] ?? 'Unknown',
                            });
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }
}
