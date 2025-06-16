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
    url: 'https://llsiaszwjqejufchefds.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxsc2lhc3p3anFlanVmY2hlZmRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NjQwOTcsImV4cCI6MjA2NDQ0MDA5N30.RYxhKWgu7tvohsRVqmh_rt1UFEJTojsG2O2WlRQJ6S4',
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