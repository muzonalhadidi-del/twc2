import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:twc/screens/beneficiary/beneficiary_dashbaord.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmRequestScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const ConfirmRequestScreen({super.key, required this.data, this.firestore, this.auth});

  @override
  State<ConfirmRequestScreen> createState() => _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends State<ConfirmRequestScreen> {
  String? selectedGender;
  String? selectedVolunteer;
  String? selectedTime;
  DateTime selectedDate = DateTime.now();
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<String> _volunteerNames = [];
  String? _beneficiaryDisabilityType;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;

  final List<String> timeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '12:00 PM - 02:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _firestore = widget.firestore ?? FirebaseFirestore.instance;
    _auth = widget.auth ?? FirebaseAuth.instance;
    _speech = stt.SpeechToText();

    _firestore.collection('volunteers').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _volunteerNames = snapshot.docs.map((doc) => (doc.data()['fullName'] ?? '').toString()).toList();
        });
      }
    });

    _firestore.collection('beneficiaries').doc(_auth.currentUser?.uid).get().then((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _beneficiaryDisabilityType = doc.data()?['disabilityType'];
        });
      }
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _searchQuery = val.recognizedWords.toLowerCase();
              _searchController.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _submitRequest() async {
    if (selectedVolunteer == null ||
        selectedTime == null ||
        selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please select gender, time, and volunteer"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final String userId = _auth.currentUser?.uid ?? "";

    Future<void> sendEmergencyEmail(String recipientEmail) async {
      String username = 'twcteam.omdis@gmail.com';
      String password = 'yuqqchxotdxutvoa';

      final smtpServer = gmail(username, password);
      final message = Message()
        ..from = Address(username, 'Together We Can')
        ..recipients.add(recipientEmail)
        ..subject = 'EMERGENCY: Urgent Request Assigned'
        ..text = 'Hello,\n\nYou have just been assigned an EMERGENCY request. Please open the app and check your dashboard immediately.\n\nThank you,\nTWC Team';

      try {
        await send(message, smtpServer);
      } catch (e) {
        debugPrint('Email error: $e');
      }
    }

    try {
      Map<String, dynamic> finalData = Map.from(widget.data);
      finalData.addAll({
        'beneficiaryId': userId,
        'volunteerId': selectedVolunteer,
        'volunteerGender': selectedGender,
        'bookingTime': selectedTime,
        'bookingDate': formattedDate,
        'status': 'pending',
        'notificationStatus': 'unread',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (finalData['subService'] == "Emergency Transport") {
        finalData['isEmergency'] = true;
      }

      DocumentReference docRef = await _firestore
          .collection('beneficiaries_request')
          .add(finalData);
          
      if (finalData['isEmergency'] == true) {
        try {
          DocumentSnapshot volDoc = await _firestore.collection('volunteers').doc(selectedVolunteer).get();
          if (volDoc.exists) {
            String volEmail = volDoc.get('email');
            await sendEmergencyEmail(volEmail);
            
            // In-app notification
            await _firestore.collection('notifications').add({
              'userId': selectedVolunteer,
              'title': 'EMERGENCY ALERT',
              'body': 'You have been assigned an emergency request. Please check immediately.',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
              'type': 'emergency',
              'requestId': docRef.id,
            });
          }
        } catch (e) {
          debugPrint("Failed to send emergency alert: $e");
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccess();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
        content: Text("Error: $e"),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            Text("Success", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Request submitted successfully!", textAlign: TextAlign.center, style: GoogleFonts.inter()),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => BeneficiaryDashbaord(onThemeToggle: () {}),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 45),
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Request"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("1. Choose the Date", Icons.calendar_month),
                  _buildCalendarCard(theme),
                  const SizedBox(height: 24),

                  _buildSectionHeader("2. Choose the Time", Icons.access_time),
                  _buildTimeDropdown(theme),
                  const SizedBox(height: 24),

                  _buildSectionHeader("3. Search & Filter Volunteers", Icons.search),
                  _buildSearchAndFilter(theme),
                  const SizedBox(height: 24),

                  _buildSectionHeader("4. Select Available Volunteer", Icons.person_add),
                  _buildAvailableVolunteerList(theme),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "SUBMIT REQUEST",
                              style: TextStyle(
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          _buildFooter(colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ThemeData theme) {
    return Column(
      children: [
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _volunteerNames.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            setState(() {
              _searchQuery = selection.toLowerCase();
              _searchController.text = selection;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: (val) {
                 setState(() {
                   _searchQuery = val.toLowerCase();
                   _searchController.text = val;
                 });
              },
              decoration: InputDecoration(
                hintText: "Search volunteer by name...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : theme.colorScheme.primary,
                  ),
                  onPressed: _listen,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _genderOption("Female", theme),
              Container(height: 24, width: 1, color: Colors.grey.shade300),
              _genderOption("Male", theme),
              Container(height: 24, width: 1, color: Colors.grey.shade300),
              _genderOption("All", theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _genderOption(String gender, ThemeData theme) {
    bool isSelected =
        (selectedGender == gender) ||
        (gender == "All" && selectedGender == null);
    
    return InkWell(
      onTap: () => setState(() {
        selectedGender = (gender == "All") ? null : gender;
        selectedVolunteer = null;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              gender,
              style: GoogleFonts.inter(
                color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableVolunteerList(ThemeData theme) {
    if (selectedTime == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(
                "Please select a Time Slot first.",
                style: GoogleFonts.inter(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    Query volunteerQuery = _firestore.collection('volunteers');
    if (selectedGender != null) {
      volunteerQuery = volunteerQuery.where(
        'gender',
        isEqualTo: selectedGender,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: volunteerQuery.snapshots(),
      builder: (context, volunteerSnapshot) {
        if (!volunteerSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('beneficiaries_request')
              .where('bookingDate', isEqualTo: formattedDate)
              .where('bookingTime', isEqualTo: selectedTime)
              .snapshots(),
          builder: (context, requestSnapshot) {
            if (!requestSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            List<String> bookedVolunteerIds = requestSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['volunteerId'] ?? "").toString();
            }).toList();

            bool _isRecommended(Map<String, dynamic> data) {
              String volSkill = (data['skills'] ?? "").toString();
              String neededSkill = "";
              if (_beneficiaryDisabilityType == 'Physical disability') neededSkill = 'Physical assistance';
              else if (_beneficiaryDisabilityType == 'Sensory disability') neededSkill = 'Sensory assistance';
              else if (_beneficiaryDisabilityType == 'Intellectual disability') neededSkill = 'Intellectual assistance';
              else if (_beneficiaryDisabilityType == 'Psychological disability') neededSkill = 'Psychological assistance';
              else if (_beneficiaryDisabilityType == 'Other disability') neededSkill = 'Other assistance';

              return volSkill == neededSkill;
            }

            var availableDocs = volunteerSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              bool isBooked = bookedVolunteerIds.contains(doc.id);
              String name = (data['fullName'] ?? "").toString().toLowerCase();
              
              List<dynamic> busyDates = data['busyDates'] ?? [];
              bool isBusy = busyDates.contains(formattedDate);

              return !isBooked && !isBusy && name.contains(_searchQuery);
            }).toList();

            availableDocs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              
              bool isRecommendedA = _isRecommended(dataA);
              bool isRecommendedB = _isRecommended(dataB);
              
              if (isRecommendedA && !isRecommendedB) return -1;
              if (!isRecommendedA && isRecommendedB) return 1;
              return 0;
            });

            if (availableDocs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      "No volunteers available for this slot.",
                      style: GoogleFonts.inter(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 350),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: availableDocs.length,
                itemBuilder: (context, index) {
                  final doc = availableDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isSelected = selectedVolunteer == doc.id;
                  final bool recommended = _isRecommended(data);

                  return Card(
                    elevation: isSelected ? 2 : 0,
                    color: isSelected ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardTheme.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          color: isSelected ? Colors.white : theme.colorScheme.primary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['fullName'] ?? 'Unknown',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recommended)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Best Match",
                                    style: GoogleFonts.inter(
                                      color: Colors.amber.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          data['gender'] ?? "",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                        size: 28,
                      ),
                      onTap: () {
                        setState(() {
                          selectedVolunteer = doc.id;
                        });
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeDropdown(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_circle, color: theme.colorScheme.primary),
            value: selectedTime,
            hint: Text(
              "Select Time Slot",
              style: GoogleFonts.inter(color: Colors.grey.shade500),
            ),
            items: timeSlots
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: GoogleFonts.inter()),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() {
              selectedTime = val;
              selectedVolunteer = null;
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: theme.textTheme.bodyLarge?.color,
            ),
          ),
          child: CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
            onDateChanged: (date) => setState(() {
              selectedDate = date;
              selectedVolunteer = null;
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(Color color) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: color,
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
