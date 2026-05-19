import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twc/screens/beneficiary/add_request.dart';
import 'package:twc/screens/tracking_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  static const Color themePurple = Color(0xFF9EA4FF);

  // Fetch the user's name for the welcome message
  Future<String> _getUserName() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('beneficiaries')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists) {
          return userDoc.get('fullName') ?? "User";
        }
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
    }
    return "User";
  }

  // --- RATING LOGIC ---
  Future<void> _showRatingDialog(String docId, double? existingRating) async {
    double selectedRating = existingRating ?? 5.0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("Rate Service"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("How was your experience with the volunteer?"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => selectedRating = index + 1.0);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themePurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('beneficiaries_request')
                    .doc(docId)
                    .update({
                      'rating': selectedRating,
                      'ratedAt': FieldValue.serverTimestamp(),
                    });
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Rating submitted! Thank you."),
                    ),
                  );
                }
              },
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CANCEL LOGIC ---
  Future<void> _confirmCancel(String docId, Map<String, dynamic> data) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Cancel Request?".tr),
            content: Text(
              "Are you sure you want to cancel this request?".tr,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("No".tr),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text("Yes".tr, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      // 1. Update status to 'cancelled'
      await FirebaseFirestore.instance
          .collection('beneficiaries_request')
          .doc(docId)
          .update({'status': 'cancelled'});

      // 2. Notify the volunteer if assigned
      String? volId = data['volunteerId'];
      if (volId != null && volId.isNotEmpty) {
        String beneficiaryName = await _getUserName();
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': volId, // Sent to volunteer
          'title': 'Request Cancelled',
          'body': 'Beneficiary $beneficiaryName has cancelled their ${data['serviceType']} request.',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'cancellation',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Request cancelled successfully.".tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Requests'.tr),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Hero(
              tag: 'logo',
              child: Image.asset('assets/images/twc.png', width: 40),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddRequestScreen()),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "New Request".tr,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<String>(
        future: _getUserName(),
        builder: (context, nameSnapshot) {
          if (nameSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          String userName = nameSnapshot.data ?? "User";

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('beneficiaries_request')
                .where('beneficiaryId', isEqualTo: currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty)
                return _buildEmptyState(userName);

              var docs = snapshot.data!.docs;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "My Requests".tr,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) =>
                          _buildRequestItem(docs[index]),
                    ),
                  ),
                  _buildFooter(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String status = (data['status'] ?? 'pending').toLowerCase();
    bool isDone = status == 'done';
    bool alreadyRated = data.containsKey('rating');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(data['serviceType']), color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          "${data['serviceType'] ?? 'Service'} - ${data['subService'] ?? ''}",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              "Date: ${data['bookingDate'] ?? 'N/A'}",
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
            ),
            if (data['volunteerId'] != null && data['volunteerId'].toString().isNotEmpty)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('volunteers').doc(data['volunteerId']).get(),
                builder: (context, snapshot) {
                  String volName = 'Loading...';
                  if (snapshot.hasData && snapshot.data!.exists) {
                    volName = (snapshot.data!.data() as Map<String, dynamic>)['fullName'] ?? 'Unknown';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Volunteer: $volName",
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            _buildStatusBadge(status),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDone)
              IconButton(
                tooltip: "Track Map",
                icon: const Icon(Icons.map, color: Colors.blue),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(requestId: doc.id, userType: 'beneficiary')));
                },
              ),
            // --- RATING BUTTON ---
            IconButton(
              tooltip: isDone ? "Rate Volunteer" : "Complete service to rate",
              icon: Icon(
                alreadyRated ? Icons.star : Icons.star_border,
                color: isDone ? Colors.amber : Colors.grey[300],
              ),
              onPressed: isDone
                  ? () => _showRatingDialog(doc.id, data['rating']?.toDouble())
                  : null, // Disabled if not done
            ),
            if (status != 'cancelled')
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                tooltip: "Cancel Request",
                onPressed: () => _confirmCancel(doc.id, data),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor = status == 'done' ? Colors.green[100]! : Colors.orange[100]!;
    Color txtColor = status == 'done'
        ? Colors.green[800]!
        : Colors.orange[800]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: txtColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'Transport':
        return Icons.directions_car;
      case 'Appointment':
        return Icons.event_note;
      case 'Shopping':
        return Icons.shopping_cart;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFooter() => Container(
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

  Widget _buildEmptyState(String name) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  "Hello, $name",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 60),
                Icon(Icons.assignment_outlined, size: 100, color: Colors.grey.shade300),
                const SizedBox(height: 24),
                Text(
                  "You don’t have any request yet !",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddRequestScreen()),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      "Request Service",
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }
}
