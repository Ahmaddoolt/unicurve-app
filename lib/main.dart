import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicurve/core/localization/translations.dart';
import 'package:unicurve/core/theme/app_theme.dart';
import 'package:unicurve/pages/initialization_screen.dart';
import 'package:unicurve/settings/settings_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final appHubSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  final appHubUrl = dotenv.env['APP_HUB_SUPABASE_URL'];
  final appHubAnonKey = dotenv.env['APP_HUB_SUPABASE_ANON_KEY'];

  if (appHubUrl == null || appHubAnonKey == null) {
    throw Exception('App Hub Supabase credentials not found in .env file.');
  }

  return SupabaseClient(appHubUrl, appHubAnonKey);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
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