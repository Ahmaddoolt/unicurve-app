// lib/localization/translations.dart
import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'settings': 'Settings',
      'profile_information': 'Profile Information',
      'full_name': 'Full Name',
      'email_address': 'Email Address',
      'university': 'University',
      'position': 'Position',
      'preferences': 'Preferences',
      'app_theme': 'App Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'language': 'Language',
      'english': 'English',
      'arabic': 'Arabic',
      'account': 'Account',
      'log_out': 'Log Out',
      'log_out_confirmation': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
    },
    'ar_SA': {
      'settings': 'الإعدادات',
      'profile_information': 'معلومات الملف الشخصي',
      'full_name': 'الاسم الكامل',
      'email_address': 'البريد الإلكتروني',
      'university': 'الجامعة',
      'position': 'المنصب',
      'preferences': 'التفضيلات',
      'app_theme': 'سمة التطبيق',
      'light': 'فاتح',
      'dark': 'داكن',
      'system': 'النظام',
      'language': 'اللغة',
      'english': 'الإنجليزية',
      'arabic': 'العربية',
      'account': 'الحساب',
      'log_out': 'تسجيل الخروج',
      'log_out_confirmation': 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
      'cancel': 'إلغاء',
    }
  };
}