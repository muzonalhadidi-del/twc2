import 'package:twc/utils/settings_manager.dart';

class AppTranslations {
  static const Map<String, String> ar = {
    // Login Screen
    'Login': 'تسجيل الدخول',
    'Email :': 'البريد الإلكتروني :',
    'Password :': 'كلمة المرور :',
    'Forgot Password?': 'نسيت كلمة المرور؟',
    "Don't have an account? ": "ليس لديك حساب؟ ",
    'Register here': 'سجل هنا',
    'SUBMIT': 'إرسال',
    
    // Registration Type Screen
    'Register as Volunteer': 'سجل كمتطوع',
    'Register as Beneficiary': 'سجل كمستفيد',

    // Register Screens
    'Full Name :': 'الاسم الكامل :',
    'Phone No :': 'رقم الهاتف :',
    'Gender :': 'الجنس :',
    'Primary Skill :': 'المهارة الأساسية :',
    'CV Upload :': 'رفع السيرة الذاتية :',
    'Civil ID Upload :': 'رفع البطاقة المدنية :',
    'Disability Type :': 'نوع الإعاقة :',
    'Disability Card Upload :': 'رفع بطاقة الإعاقة :',
    'REGISTER': 'تسجيل',

    // Gender/Skill/Disability Dropdown Options
    'Male': 'ذكر',
    'Female': 'أنثى',
    'Other': 'آخر',
    'Physical disability': 'إعاقة جسدية',
    'Sensory disability': 'إعاقة حسية',
    'Intellectual disability': 'إعاقة فكرية',
    'Psychological disability': 'إعاقة نفسية',
    'Other disability': 'إعاقة أخرى',

    // Beneficiary Dashboard
    'Home': 'الرئيسية',
    'Change Mode': 'تغيير المظهر',
    'My Requests': 'طلباتي',
    'Notifications': 'الإشعارات',
    'My Documents': 'مستنداتي',
    'Support & helps': 'الدعم والمساعدة',
    'Setting': 'الإعدادات',
    'Logout': 'تسجيل الخروج',
    'Confirm Logout': 'تأكيد تسجيل الخروج',
    'NO': 'لا',
    'YES': 'نعم',
    'Update Profile': 'تحديث الملف الشخصي',
    'Cancel': 'إلغاء',
    'Save Changes': 'حفظ التغييرات',

    // Start Page
    'Get Started': 'ابدأ الآن',
    'Already have an account?': 'لديك حساب بالفعل؟',
    'Start': 'ابدأ',
    'About us': 'من نحن',

    // Volunteer Radar
    'Volunteer Radar': 'رادار المتطوعين',
    'Location permission required': 'صلاحية الموقع مطلوبة',
    'Scanning Area...': 'جاري مسح المنطقة...',
    'volunteers nearby': 'متطوعين بالقرب منك',

    // Live Chat
    'Live Chat': 'المحادثة المباشرة',
    'Type a message...': 'اكتب رسالة...',
    'No messages yet. Start the conversation!': 'لا توجد رسائل بعد. ابدأ المحادثة!',
  };
}

extension StringTranslateExtension on String {
  String get tr {
    bool isArabic = SettingsManager.isArabicNotifier.value;
    if (!isArabic) return this;
    return AppTranslations.ar[this] ?? this;
  }
}
