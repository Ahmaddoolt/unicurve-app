// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/localization/translations.dart';
import 'package:unicurve/pages/auth/login/login_page.dart';
import 'package:unicurve/pages/uni_admin/providers/settings_provider.dart';

// 1. IMPORT YOUR CUSTOM THEME FILE
import 'package:unicurve/core/theme/app_theme.dart'; // Make sure this path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yourUrl.supabase.co',
    anonKey:
        'yourKey',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(languageProvider);

    return GetMaterialApp(
      title: 'UniCurve',
      debugShowCheckedModeBanner: false,

      // --- Localization Settings ---
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: const Locale('en', 'US'),
      
      // --- THEME SETTINGS (CORRECTED) ---
      themeMode: themeMode,

      // 2. APPLY YOUR CUSTOM THEMES HERE
      theme: AppTheme.lightTheme,      // USE YOUR CUSTOM LIGHT THEME
      darkTheme: AppTheme.darkTheme,  // USE YOUR CUSTOM DARK THEME

      home: const LoginPage(),
    );
  }
}
