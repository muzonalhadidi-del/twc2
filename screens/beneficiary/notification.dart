import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    // Use Theme.of to get colors that adapt to Dark/Light mode
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black;
    final Color cardColor = const Color(0xFF9EA4FF).withOpacity(0.8);

    return Scaffold(
      // backgroundColor automatically uses theme's scaffoldBackgroundColor
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('beneficiaries_request')
                  .where('beneficiaryId', isEqualTo: currentUserId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // This often happens if the Firestore Index isn't created yet
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No notifications found.",
                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isUnread =
                        (data['notificationStatus'] ?? 'unread') == 'unread';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isUnread 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                                  : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                                border: Border.all(
                                  color: isUnread ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${data['serviceType'] ?? 'Service'}",
                                        style: GoogleFonts.inter(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (isUnread)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            "NEW",
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _infoRow("Name", data['name'], isUnread, context),
                                  _infoRow("Type", data['subService'], isUnread, context),
                                  _infoRow("Time", data['bookingTime'], isUnread, context),
                                  _infoRow("Date", data['bookingDate'], isUnread, context),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              FirebaseFirestore.instance
                                  .collection('beneficiaries_request')
                                  .doc(doc.id)
                                  .update({'notificationStatus': 'read'});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isUnread ? Colors.transparent : Colors.green.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isUnread ? Colors.grey.shade400 : Colors.green.shade600, 
                                  width: 2
                                ),
                              ),
                              child: Icon(
                                Icons.check,
                                color: isUnread ? Colors.grey.shade400 : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
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

  Widget _infoRow(
    String label,
    dynamic value,
    bool isUnread,
    BuildContext context,
  ) {
    Color rowTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              "${value ?? 'N/A'}",
              style: GoogleFonts.inter(
                color: rowTextColor,
                fontSize: 14,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
