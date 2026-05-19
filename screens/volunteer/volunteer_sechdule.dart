import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/screens/tracking_screen.dart';

class VolunteerScheduleScreens extends StatefulWidget {
  const VolunteerScheduleScreens({super.key, required String mode});

  @override
  State<VolunteerScheduleScreens> createState() =>
      _VolunteerScheduleScreenState();
}

class _VolunteerScheduleScreenState extends State<VolunteerScheduleScreens> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  DateTime _focusedDay = DateTime.now();
  String _fullName = "Volunteer"; // Default placeholder
  String _recurrenceType = "Daily";
  bool _isSavingSchedule = false;
  DateTime? _selectedDay;
  List<DateTime> _busyDates = [];

  // Color constants
  static const Color themePurple = Color(0xFF9EA4FF);
  static const Color reservedRed = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  // Fetch the logged-in user's name from Firestore
  Future<void> _fetchUserName() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('volunteers') // Adjust collection name if needed
          .doc(currentUserId)
          .get();
      if (userDoc.exists) {
        setState(() {
          _fullName = userDoc.get('fullName') ?? "Volunteer";
          final Map<String, dynamic>? dataMap = userDoc.data() as Map<String, dynamic>?;
          if (dataMap != null) {
            if (dataMap.containsKey('recurrenceType')) {
              _recurrenceType = dataMap['recurrenceType'];
            }
            if (dataMap.containsKey('busyDates')) {
              List<dynamic> busyList = dataMap['busyDates'];
              _busyDates = busyList.map((e) => DateTime.parse(e.toString())).toList();
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching name/schedule: $e");
    }
  }

  Future<void> _saveSchedulePreference(String type) async {
    setState(() => _isSavingSchedule = true);
    try {
      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(currentUserId)
          .update({'recurrenceType': type});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Schedule preference saved!".tr)),
        );
      }
    } catch (e) {
      debugPrint("Error saving schedule: $e");
    } finally {
      if (mounted) setState(() => _isSavingSchedule = false);
    }
  }

  Future<void> _toggleBusyStatus(DateTime date) async {
    bool isBusy = _busyDates.any((d) => isSameDay(d, date));
    
    setState(() {
      if (isBusy) {
        _busyDates.removeWhere((d) => isSameDay(d, date));
      } else {
        _busyDates.add(date);
      }
    });

    try {
      await FirebaseFirestore.instance
          .collection('volunteers')
          .doc(currentUserId)
          .update({
            'busyDates': _busyDates
                .map((d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}")
                .toList()
          });
    } catch (e) {
      debugPrint("Error updating busy dates: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("My Schedule".tr),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetching all bookings where volunteerId matches the logged-in user
        stream: FirebaseFirestore.instance
            .collection('beneficiaries_request')
            .where('volunteerId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 1. Process Data: Extract reserved dates and booking details
          List<DateTime> reservedDates = [];
          List<Map<String, dynamic>> scheduleDetails = [];

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              String? dateString =
                  data['bookingDate']; // Expecting "YYYY-MM-DD"

              if (dateString != null && dateString.isNotEmpty) {
                try {
                  DateTime parsedDate = DateTime.parse(dateString);
                  reservedDates.add(parsedDate);
                  data['id'] = doc.id;
                  
                  // Filter by selected day if one is selected
                  if (_selectedDay == null || isSameDay(parsedDate, _selectedDay)) {
                    scheduleDetails.add(data);
                  }
                } catch (e) {
                  debugPrint("Error parsing date: $e");
                }
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
              // Displaying Logged-in User Full Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${_fullName.toUpperCase()} SCHEDULE",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),

              // Availability Preference
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text("Availability: ".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _recurrenceType,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: "Daily", child: Text("Daily")),
                          DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _recurrenceType = val);
                            _saveSchedulePreference(val);
                          }
                        },
                      ),
                    ),
                    if (_isSavingSchedule)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Calendar Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: GoogleFonts.inter(color: Theme.of(context).textTheme.bodyLarge?.color),
                    weekendTextStyle: GoogleFonts.inter(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  // Marking reserved dates in Red
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      // Check if 'day' exists in our 'reservedDates' list
                      bool isReserved = reservedDates.any(
                        (d) => isSameDay(d, day),
                      );
                      bool isBusy = _busyDates.any(
                        (d) => isSameDay(d, day),
                      );

                      if (isReserved) {
                        return Center(
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: const BoxDecoration(
                              color: reservedRed,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      } else if (isBusy) {
                        return Center(
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 15),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: reservedRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Reserved day".tr,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Busy day".tr,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              if (_selectedDay != null && !reservedDates.any((d) => isSameDay(d, _selectedDay)))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _toggleBusyStatus(_selectedDay!),
                      icon: Icon(
                        _busyDates.any((d) => isSameDay(d, _selectedDay)) ? Icons.check_circle : Icons.block,
                        color: Colors.white,
                      ),
                      label: Text(
                        _busyDates.any((d) => isSameDay(d, _selectedDay)) ? "Mark as Available".tr : "Mark as Busy".tr,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _busyDates.any((d) => isSameDay(d, _selectedDay)) ? Colors.green : Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Booking Details".tr,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_selectedDay != null)
                        TextButton(
                          onPressed: () => setState(() => _selectedDay = null),
                          child: Text("Show All".tr, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary)),
                        )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Schedule Details List
              scheduleDetails.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No bookings found.".tr,
                          style: GoogleFonts.inter(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: scheduleDetails.length,
                        itemBuilder: (context, index) {
                          var item = scheduleDetails[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            shadowColor: Colors.black12,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${item['name']}",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Divider(),
                                  ),
                                  _buildDetailRow(context, Icons.build_circle_outlined, "Service: ${item['serviceType']}"),
                                  _buildDetailRow(context, Icons.build_circle_outlined, "Sub-Service: ${item['subService'] ?? 'N/A'}"),
                                  _buildDetailRow(context, Icons.access_time, "Time: ${item['bookingTime']}"),
                                  _buildDetailRow(context, Icons.calendar_today, "Date: ${item['bookingDate']}"),
                                  _buildDetailRow(context, Icons.location_on_outlined, "Address: ${item['address'] ?? 'No address'}"),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TrackingScreen(
                                              requestId: item['id'],
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
                                ],
                              ),
                            ),
                          );
                        },
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
          ));
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
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
}
