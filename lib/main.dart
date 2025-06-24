import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/localization/translations.dart';
import 'package:unicurve/core/theme/app_theme.dart';
import 'package:unicurve/pages/initialization_screen.dart'; // Import the new screen
import 'package:unicurve/settings/settings_provider.dart';

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
      translations: AppTranslations(),
      locale: locale,
      fallbackLocale: const Locale('en', 'US'),
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const InitializationScreen(),
    );
  }
}
