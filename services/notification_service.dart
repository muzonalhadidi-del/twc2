import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class NotificationService {
  static Future<void> checkUpcomingAppointments() async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      final String tomorrowStr = tomorrow.toString().substring(0, 10);
      final String todayStr = now.toString().substring(0, 10);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('beneficiaries_request')
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['appointmentReminderSent'] == true) continue;
        
        final bookingDate = data['bookingDate'];
        if (bookingDate == null) continue;
        
        // If the booking date is tomorrow or today
        if (bookingDate == tomorrowStr || bookingDate == todayStr) {
          final beneficiaryId = data['beneficiaryId'];
          final volunteerId = data['volunteerId'];
          final serviceType = data['serviceType'] ?? 'Service';

          // Create notification for Beneficiary
          if (beneficiaryId != null) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': beneficiaryId,
              'title': 'Upcoming Appointment Reminder',
              'body': 'Your appointment for $serviceType is coming up on $bookingDate. Please be ready!',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }

          // Create notification for Volunteer
          if (volunteerId != null && volunteerId != 'unassigned') {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': volunteerId,
              'title': 'Upcoming Task Reminder',
              'body': 'You have an upcoming task: $serviceType on $bookingDate. Please be prepared.',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
          }

          // EMAIL NOTIFICATION LOGIC
          String? beneficiaryEmail;
          if (beneficiaryId != null) {
            final bDoc = await FirebaseFirestore.instance.collection('beneficiaries').doc(beneficiaryId).get();
            if (bDoc.exists) beneficiaryEmail = bDoc.data()?['email'];
          }

          String? volunteerEmail;
          if (volunteerId != null && volunteerId != 'unassigned') {
            final vDoc = await FirebaseFirestore.instance.collection('volunteers').doc(volunteerId).get();
            if (vDoc.exists) volunteerEmail = vDoc.data()?['email'];
          }

          String username = 'twcteam.omdis@gmail.com';
          String password = 'yuqqchxotdxutvoa';
          final smtpServer = gmail(username, password);

          // Send email to Beneficiary
          if (beneficiaryEmail != null && beneficiaryEmail.isNotEmpty) {
            final message = Message()
              ..from = Address(username, 'TWC Appointments')
              ..recipients.add(beneficiaryEmail)
              ..subject = 'TWC Appointment Reminder | تذكير بموعد'
              ..text = 'مرحباً، نود تذكيرك بأن لديك موعد $serviceType غداً بتاريخ $bookingDate. الرجاء الاستعداد.\n\nHello, we would like to remind you that you have an appointment for $serviceType tomorrow on $bookingDate. Please be ready.';
            try {
              await send(message, smtpServer);
            } catch (e) {
              if (kDebugMode) print('Email failed to $beneficiaryEmail: $e');
            }
          }

          // Send email to Volunteer
          if (volunteerEmail != null && volunteerEmail.isNotEmpty) {
            final message = Message()
              ..from = Address(username, 'TWC Appointments')
              ..recipients.add(volunteerEmail)
              ..subject = 'TWC Task Reminder | تذكير بمهمة تطوعية'
              ..text = 'مرحباً، نود تذكيرك بأن لديك مهمة تطوعية لتقديم $serviceType غداً بتاريخ $bookingDate.\n\nHello, we would like to remind you that you have a volunteer task to provide $serviceType tomorrow on $bookingDate.';
            try {
              await send(message, smtpServer);
            } catch (e) {
              if (kDebugMode) print('Email failed to $volunteerEmail: $e');
            }
          }

          // Mark as reminded
          await doc.reference.update({
            'appointmentReminderSent': true,
          });
          
          if (kDebugMode) {
            print("Reminder notifications sent for request ${doc.id}");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error checking upcoming appointments: $e");
      }
    }
  }
}
