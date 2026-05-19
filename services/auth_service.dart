import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:twc/services/encryption_service.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Admin credentials (permanent, never expire)
  static const String adminEmail = "admin@disabilityapp.com";
  static const String adminPassword = "Admin123@";

  // Login user - handles both admin and regular users
  Future<User?> loginUser(String email, String password) async {
    try {
      if (kDebugMode) {
        print("Attempting login for: $email");
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        print("Login successful for: ${userCredential.user!.uid}");
      }

      // Check if admin login
      if (email == adminEmail) {
        // Ensure admin is saved to Firestore
        await _firestore.collection('admins').doc(userCredential.user!.uid).set(
          {'email': email, 'createdAt': DateTime.now(), 'isSuperAdmin': true},
          SetOptions(merge: true),
        );

        if (kDebugMode) {
          print("Admin user saved to Firestore");
        }
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("Firebase Auth Error: ${e.code} - ${e.message}");
      }

      // Special handling for admin account creation
      if (email == adminEmail &&
          (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
        if (kDebugMode) {
          print("Admin not found, attempting to create...");
        }
        return await _createAdminAccount(email, password);
      }

      rethrow;
    }
  }

  // Create admin account if it doesn't exist
  Future<User?> _createAdminAccount(String email, String password) async {
    try {
      if (kDebugMode) {
        print("Creating admin account...");
      }
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save admin to Firestore
      await _firestore.collection('admins').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': DateTime.now(),
        'isSuperAdmin': true,
      });

      if (kDebugMode) {
        print("Admin account created successfully!");
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("Error creating admin: ${e.code} - ${e.message}");
      }
      throw Exception("Failed to create admin account: ${e.message}");
    }
  }

  // Check if phone number exists
  Future<bool> _isPhoneNumberExists(String phoneNumber) async {
    String encryptedPhone = EncryptionHelper.encryptData(phoneNumber);
    
    final benfQuery = await _firestore
        .collection('beneficiaries')
        .where('phoneNumber', isEqualTo: encryptedPhone)
        .get();

    if (benfQuery.docs.isNotEmpty) return true;

    final volQuery = await _firestore
        .collection('volunteers')
        .where('phoneNumber', isEqualTo: encryptedPhone)
        .get();

    return volQuery.docs.isNotEmpty;
  }

  // Register beneficiary
  Future<User?> registerBeneficiary({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String disabilityType,
    required String profileImage,
    required String disabilityCardUrl,
    required String civilIdText,
  }) async {
    try {
      if (await _isPhoneNumberExists(phoneNumber)) {
        throw Exception("this phone number is already exit");
      }
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore
          .collection('beneficiaries')
          .doc(userCredential.user!.uid)
          .set({
            'fullName': fullName,
            'email': email,
            'phoneNumber': EncryptionHelper.encryptData(phoneNumber),
            'disabilityType': disabilityType,
            'profileImage': profileImage,
            'disabilityCardUrl': disabilityCardUrl,
            'civilIdText': civilIdText,
            'userType': 'beneficiary',
            'createdAt': DateTime.now(),
          });

      // Send welcome email
      await _sendWelcomeEmail(email, fullName);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("Register beneficiary error: ${e.code} - ${e.message}");
      }
      throw Exception(e.message ?? "Registration failed");
    }
  }

  // Register volunteer
  Future<User?> registerVolunteer({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String gender,
    required String profileImageUrl,
    required String skills,
    required List<String> assistanceTypes,
    required String cvUrl,
    required String civilIdUrl,
    required String civilIdText,
  }) async {
    try {
      if (await _isPhoneNumberExists(phoneNumber)) {
        throw Exception("this phone number is already exit");
      }
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore
          .collection('volunteers')
          .doc(userCredential.user!.uid)
          .set({
            'fullName': fullName,
            'email': email,
            'phoneNumber': EncryptionHelper.encryptData(phoneNumber),
            'gender': gender,
            'skills': skills,
            'assistanceTypes': assistanceTypes,
            'cvUrl': cvUrl,
            'civilIdUrl': civilIdUrl,
            'civilIdText': civilIdText,
            'profileImageUrl': profileImageUrl,
            'userType': 'volunteer',
            'createdAt': DateTime.now(),
          });

      // Send welcome email
      await _sendWelcomeEmail(email, fullName);

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print("Register volunteer error: ${e.code} - ${e.message}");
      }
      throw Exception(e.message ?? "Registration failed");
    }
  }

  Future<void> _sendWelcomeEmail(String recipientEmail, String name) async {
    String username = 'twcteam.omdis@gmail.com';
    String password = 'yuqqchxotdxutvoa'; 

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Together We Can Team')
      ..recipients.add(recipientEmail)
      ..subject = 'Welcome to Together We Can!'
      ..text = 'مرحباً $name,\n\nتم تسجيلك بنجاح. نحن سعداء بانضمامك إلينا.\n\nمع تحيات,\nفريق TWC\n\n-----------------------------\n\nHello $name,\n\nYou have been successfully registered. We are thrilled to have you join our community.\n\nBest Regards,\nTWC Team';

    try {
      await send(message, smtpServer);
      if (kDebugMode) print('Welcome email sent to $recipientEmail');
    } catch (e) {
      if (kDebugMode) print('Failed to send welcome email: $e');
    }
  }

  // Generate random password
  String generateRandomPassword() {
    const length = 8;
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Create user from admin side without logging out admin
  Future<User?> adminCreateUser(String email, String password) async {
    try {
      FirebaseApp app = await Firebase.initializeApp(
          name: 'SecondaryApp', options: Firebase.app().options);
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: app)
          .createUserWithEmailAndPassword(email: email, password: password);
      await app.delete();
      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print("Admin create user error: $e");
      }
      rethrow;
    }
  }

  Future<void> sendAdminCreatedEmail(String recipientEmail, String name, String password) async {
    String username = 'twcteam.omdis@gmail.com';
    String passwordEmail = 'yuqqchxotdxutvoa'; 

    final smtpServer = gmail(username, passwordEmail);
    final message = Message()
      ..from = Address(username, 'Together We Can Team')
      ..recipients.add(recipientEmail)
      ..subject = 'Your Account Details - Together We Can'
      ..text = 'مرحباً $name,\n\nتم إنشاء حسابك بنجاح من قبل الإدارة.\n\nتفاصيل الدخول الخاصة بك:\nالبريد الإلكتروني: $recipientEmail\nكلمة المرور: $password\n\nيرجى تغيير كلمة المرور بعد الدخول.\n\nمع تحيات,\nفريق TWC\n\n-----------------------------\n\nHello $name,\n\nYour account has been successfully created by the administration.\n\nYour login details are:\nEmail: $recipientEmail\nPassword: $password\n\nPlease change your password after logging in.\n\nBest Regards,\nTWC Team';

    try {
      await send(message, smtpServer);
      if (kDebugMode) print('Account details email sent to $recipientEmail');
    } catch (e) {
      if (kDebugMode) print('Failed to send account details email: $e');
    }
  }

  Future<void> sendInactivityReminderEmail(String recipientEmail, String name) async {
    String username = 'twcteam.omdis@gmail.com';
    String password = 'yuqqchxotdxutvoa'; 

    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Together We Can Team')
      ..recipients.add(recipientEmail)
      ..subject = 'We Miss You! Update Your Schedule'
      ..text = 'مرحباً $name,\n\nلقد لاحظنا غيابك عن تطبيقنا لأكثر من أسبوع. يرجى الدخول لتحديث جدولك وتلقي طلبات جديدة.\n\nمع تحيات,\nفريق TWC\n\n-----------------------------\n\nHello $name,\n\nWe noticed you haven''t been active on the app for over a week. Please log in to update your schedule and receive new requests.\n\nBest Regards,\nTWC Team';

    try {
      await send(message, smtpServer);
      if (kDebugMode) print('Reminder email sent to $recipientEmail');
    } catch (e) {
      if (kDebugMode) print('Failed to send reminder email: $e');
    }
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      if (kDebugMode) {
        print("Attempting to send password reset email to: $email");
      }

      // Basic validation: check if it's a test email
      if (email == "f1@gmail.com" || email.isEmpty) {
        throw Exception(
          "Please use a real, registered email address for password reset.",
        );
      }

      await _auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        print("Password reset email sent successfully to: $email");
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
          "Firebase Auth Error during password reset: ${e.code} - ${e.message}",
        );
      }

      // Handle specific Firebase error codes
      String userMessage;
      switch (e.code) {
        case 'network-request-failed':
          userMessage =
              "Network error. Please check your internet connection and try again.";
          break;
        case 'user-not-found':
          // For security, don't reveal that the user doesn't exist
          userMessage =
              "If an account exists with this email, a reset link has been sent.";
          break;
        case 'invalid-email':
          userMessage =
              "The email address is not valid. Please check and try again.";
          break;
        case 'too-many-requests':
          userMessage = "Too many attempts. Please try again later.";
          break;
        default:
          userMessage = "Failed to send reset email: ${e.message}";
      }
      throw Exception(userMessage);
    } catch (e) {
      // Catch any other unexpected errors
      if (kDebugMode) {
        print("Unexpected error in forgotPassword: $e");
      }
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check user type
  Future<String?> getUserType(String uid) async {
    try {
      if (kDebugMode) {
        print("🔍 Checking user type for UID: $uid");
      }

      // Check if user is admin by email (works offline)
      try {
        final user = _auth.currentUser;
        if (user != null && user.email == adminEmail) {
          if (kDebugMode) {
            print("✅ User is admin (by email check)");
          }
          return 'admin';
        }
      } catch (e) {
        if (kDebugMode) {
          print("Email check error: $e");
        }
      }

      // Try online check
      try {
        // Check if beneficiary
        final beneficiaryDoc = await _firestore
            .collection('beneficiaries')
            .doc(uid)
            .get();
        if (beneficiaryDoc.exists) return 'beneficiary';

        // Check if volunteer
        final volunteerDoc = await _firestore
            .collection('volunteers')
            .doc(uid)
            .get();
        if (volunteerDoc.exists) return 'volunteer';

        // Check if admin
        final adminDoc = await _firestore.collection('admins').doc(uid).get();
        if (adminDoc.exists) return 'admin';
      } catch (e) {
        if (kDebugMode) {
          print("⚠️ Firestore query failed (might be offline): $e");
        }
        // Return null if offline - will use email check in login screen
        return null;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Get user type error: $e");
      }
      return null;
    }
  }

  Future<void> sendEmergencyEmailToVolunteers(String beneficiaryName, String locationDetails) async {
    try {
      final volunteersQuery = await _firestore.collection('volunteers').get();
      List<String> volunteerEmails = [];
      for (var doc in volunteersQuery.docs) {
        String? email = doc.data()['email'];
        if (email != null && email.isNotEmpty) {
          volunteerEmails.add(email);
        }
      }

      if (volunteerEmails.isEmpty) return;

      String username = 'twcteam.omdis@gmail.com';
      String password = 'yuqqchxotdxutvoa'; 

      final smtpServer = gmail(username, password);
      
      for (String email in volunteerEmails) {
        final message = Message()
          ..from = Address(username, 'TWC Emergency System')
          ..recipients.add(email)
          ..subject = '🚨 EMERGENCY SOS REQUEST 🚨'
          ..text = 'عاجل: \nالمستفيد $beneficiaryName يحتاج إلى مساعدة طارئة الآن.\nالموقع/التفاصيل: $locationDetails\nالرجاء تسجيل الدخول إلى التطبيق لقبول الطلب فوراً.\n\nURGENT:\nBeneficiary $beneficiaryName needs immediate emergency assistance.\nLocation/Details: $locationDetails\nPlease log into the app to accept the request immediately.';

        try {
          await send(message, smtpServer);
        } catch (e) {
          if (kDebugMode) print('Failed to send SOS to $email: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error sending emergency emails: $e');
    }
  }
}