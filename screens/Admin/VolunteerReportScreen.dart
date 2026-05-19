import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';

class VolunteerReportScreen extends StatefulWidget {
  final String volunteerId;
  final String volunteerName;

  const VolunteerReportScreen({
    super.key,
    required this.volunteerId,
    required this.volunteerName,
  });

  @override
  State<VolunteerReportScreen> createState() => _VolunteerReportScreenState();
}

class _VolunteerReportScreenState extends State<VolunteerReportScreen> {
  Map<String, dynamic>? volunteerData;
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final volDoc = await FirebaseFirestore.instance.collection('volunteers').doc(widget.volunteerId).get();
      if (volDoc.exists) {
        volunteerData = volDoc.data();
      }

      final reqSnapshot = await FirebaseFirestore.instance.collection('beneficiaries_request').where('volunteerId', isEqualTo: widget.volunteerId).get();
      requests = reqSnapshot.docs.map((e) => e.data()).toList();

    } catch (e) {
      debugPrint("Error fetching report data: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Volunteer Report".tr)),
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    int totalTasks = requests.length;
    int completedTasks = requests.where((r) => r['status'] == 'completed').length;
    int incompleteTasks = totalTasks - completedTasks;
    double completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Detailed Report".tr),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Volunteer Header
              _buildHeader(isDark, primaryColor),
              const SizedBox(height: 24),
              
              // 2. Main Dashboard Card
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2F33) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSectionHeader("Status Summary", Icons.analytics),
                    const Divider(height: 1),
                    
                    // Timeline & Status
                    _buildRowItem(
                      "Status",
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(totalTasks == 0 ? "No Tasks Assigned" : "${(completionRate * 100).toStringAsFixed(0)}% Completed", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: primaryColor)),
                              Text("$completedTasks / $totalTasks Tasks", style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: completionRate,
                            backgroundColor: Colors.grey.shade300,
                            color: completedTasks == totalTasks && totalTasks > 0 ? Colors.green : Colors.orange,
                            minHeight: 16,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      )
                    ),
                    const Divider(height: 1),
                    
                    // Description
                    _buildRowItem(
                      "Skills",
                      Text(
                        volunteerData?['skills'] ?? 'No specific skills listed.',
                        style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black87),
                      )
                    ),
                    const Divider(height: 1),

                    // Metrics (Circular Chart equivalent)
                    _buildRowItem(
                      "Metrics",
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCircularMetric(
                            value: completionRate, 
                            label: "Completion Rate", 
                            color: Colors.green
                          ),
                          _buildCircularMetric(
                            value: totalTasks == 0 ? 0.0 : incompleteTasks / totalTasks, 
                            label: "Pending Rate", 
                            color: Colors.orange
                          ),
                        ],
                      )
                    ),
                    const Divider(height: 1),

                    // Completed Tasks Dots
                    _buildRowItem(
                      "Tasks Done",
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(completedTasks, (index) {
                              return Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                          if (completedTasks == 0)
                            Text("No completed tasks yet", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    ),
                    const Divider(height: 1),
                    
                    // Incomplete Tasks Dots
                    _buildRowItem(
                      "Tasks Pending",
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(incompleteTasks, (index) {
                              return Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                          if (incompleteTasks == 0)
                            Text("No pending tasks", style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Action Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back to Reports".tr, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2F33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: volunteerData?['profileImageUrl'] != null && volunteerData!['profileImageUrl'].toString().isNotEmpty 
                ? NetworkImage(volunteerData!['profileImageUrl']) 
                : null,
            child: volunteerData?['profileImageUrl'] == null || volunteerData!['profileImageUrl'].toString().isEmpty
                ? Icon(Icons.person, size: 40, color: primaryColor)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.volunteerName,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        volunteerData?['email'] ?? "Unknown Email",
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      volunteerData?['phoneNumber'] ?? 'N/A',
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildRowItem(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildCircularMetric({required double value, required String label, required Color color}) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                backgroundColor: Colors.grey.shade200,
                color: color,
                strokeWidth: 8,
              ),
              Center(
                child: Text(
                  "${(value * 100).toStringAsFixed(0)}%",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
