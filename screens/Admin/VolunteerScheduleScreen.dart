import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';

class VolunteerScheduleScreen extends StatefulWidget {
  final String volunteerId;
  final String volunteerName;

  const VolunteerScheduleScreen({
    super.key,
    required this.volunteerId,
    required this.volunteerName,
  });

  @override
  State<VolunteerScheduleScreen> createState() =>
      _VolunteerScheduleScreenState();
}

class _VolunteerScheduleScreenState extends State<VolunteerScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _bookedEvents = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadVolunteerBookings();
  }

  void _loadVolunteerBookings() {
    FirebaseFirestore.instance
        .collection('beneficiaries_request')
        .where('volunteerId', isEqualTo: widget.volunteerId)
        .snapshots()
        .listen((snapshot) {
          final Map<DateTime, List<dynamic>> data = {};

          for (var doc in snapshot.docs) {
            try {
              var rawDate = doc['bookingDate']; // Stored as "2026-03-04"
              DateTime date;

              if (rawDate is Timestamp) {
                date = rawDate.toDate();
              } else {
                // Updated pattern to match your Firestore screenshot exactly
                date = DateFormat(
                  "yyyy-MM-dd",
                ).parse(rawDate.toString().trim());
              }

              final day = DateTime(date.year, date.month, date.day);
              if (data[day] == null) data[day] = [];
              data[day]!.add(doc.data());
            } catch (e) {
              debugPrint("Parsing error for doc ${doc.id}: $e");
            }
          }

          if (mounted) {
            setState(() {
              _bookedEvents = data;
            });
          }
        });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _bookedEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("${widget.volunteerName}'s Schedule".tr),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  markerDecoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: GoogleFonts.inter(),
                  weekendTextStyle: GoogleFonts.inter(color: Colors.redAccent),
                ),
                headerStyle: HeaderStyle(
                  titleTextStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                  formatButtonVisible: false,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text("Reserved day".tr, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _getEventsForDay(_selectedDay!).isEmpty
                ? Center(child: Text("No bookings for this day".tr, style: GoogleFonts.inter(color: Colors.grey.shade600)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _getEventsForDay(_selectedDay!).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final booking = _getEventsForDay(_selectedDay!)[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.access_time,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(booking['serviceType'] ?? "Service".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.watch_later_outlined, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text("Time: ${booking['bookingTime']}".tr, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text("Location: ${booking['address'] ?? 'Not set'}".tr, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("Back".tr, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
