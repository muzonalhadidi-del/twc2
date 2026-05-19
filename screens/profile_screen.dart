import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twc/utils/app_translations.dart';
import 'package:twc/screens/video_tutorial_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isArabic;
  const ProfileScreen({super.key, required this.isArabic});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  void _showFaqDialog(BuildContext context) {
    final faqs = [
      {
        'q': isArabic ? 'كيف أقوم بالتسجيل / إنشاء حساب؟' : 'How do I register/create an account?',
        'a': isArabic ? 'انقر على "تسجيل" في شاشة البداية، اختر نوع حسابك، وقم بتعبئة بياناتك.' : 'Click on "Start" and then select "Register" on the Login Page. You can choose to register as a Beneficiary or a Volunteer. Fill in your details to create an account.'
      },
      {
        'q': isArabic ? 'نسيت كلمة المرور الخاصة بي؟' : 'I forgot my password / How do I reset my password?',
        'a': isArabic ? 'في شاشة تسجيل الدخول، انقر على "نسيت كلمة المرور؟". أدخل بريدك الإلكتروني لإرسال رابط إعادة التعيين.' : 'On the Login screen, click on "Forgot Password?". Enter your email address and we will send you a link to reset your password.'
      },
      {
        'q': isArabic ? 'كيف أقوم بتحديث ملفي الشخصي؟' : 'How do I update my profile?',
        'a': isArabic ? 'اذهب إلى ملفك الشخصي وانقر على تعديل لتغيير بريدك الإلكتروني أو رقم هاتفك.' : 'Go to the Profile tab, access your profile settings, and update your email or phone number. Remember to save your changes!'
      },
      {
        'q': isArabic ? 'كيف أطلب متطوعاً؟' : 'How do I request a volunteer?',
        'a': isArabic ? 'سجل دخولك كمستفيد، اذهب إلى لوحة التحكم الخاصة بك، وانقر على "طلب متطوع".' : 'Log in as a beneficiary, go to your dashboard, and click on "Request Volunteer". Fill in the required details and submit.'
      },
      {
        'q': isArabic ? 'ما هي الخدمات التي تقدمونها؟' : 'What services do you offer?',
        'a': isArabic ? 'نقدم خدمات التنسيق الرقمي لوسائل النقل التطوعية والمساعدة على الوصول.' : 'We offer digital coordination for volunteer transportation, environmental sustainability initiatives, and accessibility assistance.'
      },
      {
        'q': isArabic ? 'من أين أقوم بإلغاء الطلب؟' : 'Where do I cancel a request?',
        'a': isArabic ? 'اذهب إلى لوحة التحكم، عرض "طلباتي"، اختر الطلب الذي ترغب بإلغائه، وانقر على "إلغاء الطلب".' : 'Go to your Dashboard, view "My Requests", select the request you wish to cancel, and click "Cancel Request".'
      },
      {
        'q': isArabic ? 'كيف أعرض جدول التطوع الخاص بي؟' : 'How do I view my volunteer schedule?',
        'a': isArabic ? 'سجل دخولك كمتطوع، اذهب إلى لوحة التحكم وانقر على "جدولي".' : 'Log in as a volunteer, navigate to your Dashboard, and click on "My Schedule" or "Accepted Requests" to see your upcoming tasks.'
      },
      {
        'q': isArabic ? 'كيف أقوم بتسجيل الخروج؟' : 'How do I log out?',
        'a': isArabic ? 'اذهب إلى ملفك الشخصي وانقر على زر "تسجيل الخروج".' : 'Go to your Profile or Settings tab and click on the "Logout" button.'
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isArabic ? 'الأسئلة الشائعة' : 'FAQ',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              return ExpansionTile(
                title: Text(faqs[index]['q']!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(faqs[index]['a']!, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700)),
                  )
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إغلاق' : 'Close', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isArabic ? 'الملف الشخصي' : 'Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              isArabic ? 'المساعدة والدعم' : 'Help & Support',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Video Tutorial
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.play_circle_fill, color: Colors.red),
                  ),
                  title: Text(isArabic ? 'فيديو تعليمي' : 'Video Tutorial', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoTutorialScreen(isArabic: isArabic),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),

                // FAQ
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.question_answer, color: Colors.blue),
                  ),
                  title: Text(isArabic ? 'الأسئلة الشائعة' : 'FAQ', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showFaqDialog(context),
                ),
                const Divider(height: 1),

                // Contact Us
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.email, color: Colors.green),
                  ),
                  title: Text(isArabic ? 'اتصل بنا' : 'Contact Us', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'twcteam.omdis@gmail.com',
                      query: 'subject=Support Request from TWC App'
                    );
                    _launchUrl(emailLaunchUri.toString());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
