import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/screens/tracking_screen.dart';

class VolunteerCompleteListScreen extends StatelessWidget {
  const VolunteerCompleteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentVolunteerId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Complete List'.tr),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Complete List".tr,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('beneficiaries_request')
                  .where('volunteerId', isEqualTo: currentVolunteerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "No requests assigned to you yet.",
                          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final requests = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    var requestData =
                        requests[index].data() as Map<String, dynamic>;
                    String requestId = requests[index].id;

                    return _buildRequestCard(
                      context: context,
                      index: index + 1,
                      data: requestData,
                      requestId: requestId,
                    );
                  },
                );
              },
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> data,
    required String requestId,
  }) {
    bool isCompleted = data['status'] == 'done';
    bool isCancelled = data['status'] == 'cancelled';
    double? rating = data['rating']?.toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isCompleted 
              ? [Colors.green.shade50, Colors.green.shade100] 
              : [Theme.of(context).cardColor, Theme.of(context).cardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green.shade500 : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "$index",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${data['name'] ?? 'Unknown'}",
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(context, Icons.build_circle_outlined, "${data['serviceType'] ?? ''}: ${data['subService'] ?? 'N/A'}"),
                  _buildDetailRow(context, Icons.access_time, "${data['bookingDate'] ?? ''} at ${data['bookingTime'] ?? ''}"),
                  _buildDetailRow(context, Icons.location_on_outlined, "${data['address'] ?? 'No address'}"),
                  const SizedBox(height: 8),
                  
                  // View Location Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrackingScreen(
                              requestId: requestId,
                              userType: 'volunteer',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on, size: 18),
                      label: Text('View Location'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green.shade600 : Colors.orange.shade500,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (data['status'] ?? 'pending').toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  if (rating != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                    Row(
                      children: [
                        Text(
                          "Rating: ",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isCancelled ? null : () => _toggleStatus(requestId, data['status']),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCancelled ? Colors.red.shade100 : (isCompleted ? Colors.green.shade600 : Colors.white),
                  border: Border.all(
                    color: isCancelled ? Colors.red.shade400 : (isCompleted ? Colors.green.shade600 : Colors.grey.shade400),
                    width: 2,
                  ),
                  boxShadow: isCompleted ? [
                    BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                  ] : null,
                ),
                child: isCancelled 
                    ? const Icon(Icons.close, color: Colors.red, size: 24)
                    : (isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 24)
                        : null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(String docId, String? currentStatus) async {
    if (currentStatus == 'cancelled') return;
    // Changed to 'done' to synchronize with your beneficiary screen requirements
    String newStatus = (currentStatus == 'done') ? 'pending' : 'done';
    await FirebaseFirestore.instance
        .collection('beneficiaries_request')
        .doc(docId)
        .update({'status': newStatus});
  }

  Widget _buildFooter(BuildContext context) => Container(
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
  );
}
