import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/pages/auth/login/login_page.dart';
import 'package:unicurve/pages/uni_admin/providers/settings_provider.dart';

/// A reusable widget that contains the general settings for
/// Preferences (Theme, Language) and Account (Logout).
class GeneralSettingsSection extends ConsumerWidget {
  const GeneralSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final currentLocale = ref.watch(languageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Preferences Section ---
        Text('preferences'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildThemeSelector(context, themeMode, ref),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildLanguageSelector(context, currentLocale, ref),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // --- Account Section ---
        Text('account'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text('log_out'.tr, style: const TextStyle(color: AppColors.error)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('log_out'.tr),
                  content: Text('log_out_confirmation'.tr),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('cancel'.tr)),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('log_out'.tr, style: const TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (confirmed == true) {
                await AuthService().signOut();
                // ignore: use_build_context_synchronously
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeMode currentTheme, WidgetRef ref) {
    // If the saved theme is 'system', default to 'dark' in the UI to avoid errors,
    // as we are only providing 'light' and 'dark' options now.
    final ThemeMode uiThemeValue = currentTheme == ThemeMode.system ? ThemeMode.dark : currentTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('app_theme'.tr, style: const TextStyle(fontSize: 16)),
          CupertinoSlidingSegmentedControl<ThemeMode>(
            groupValue: uiThemeValue, // Use the safe UI value
            thumbColor: AppColors.primary,
            backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
            onValueChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setTheme(value);
              }
            },
            // REMOVED the ThemeMode.system option
            children: {
              ThemeMode.light: Padding(padding: const EdgeInsets.all(8), child: Text('light'.tr, style: TextStyle(color: uiThemeValue == ThemeMode.light ? Colors.white : Theme.of(context).colorScheme.onBackground))),
              ThemeMode.dark: Padding(padding: const EdgeInsets.all(8), child: Text('dark'.tr, style: TextStyle(color: uiThemeValue == ThemeMode.dark ? Colors.white : Theme.of(context).colorScheme.onBackground))),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, Locale currentLocale, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('language'.tr, style: const TextStyle(fontSize: 16)),
          CupertinoSlidingSegmentedControl<String>(
            groupValue: currentLocale.languageCode,
            thumbColor: AppColors.primary,
            backgroundColor: Theme.of(context).colorScheme.background.withOpacity(0.5),
            onValueChanged: (String? value) {
              if (value == 'en') {
                ref.read(languageProvider.notifier).setLanguage('en', 'US');
              } else if (value == 'ar') {
                ref.read(languageProvider.notifier).setLanguage('ar', 'SA');
              }
            },
            children: {
              'en': Padding(padding: const EdgeInsets.all(8), child: Text('english'.tr, style: TextStyle(color: currentLocale.languageCode == 'en' ? Colors.white : Theme.of(context).colorScheme.onBackground))),
              'ar': Padding(padding: const EdgeInsets.all(8), child: Text('arabic'.tr, style: TextStyle(color: currentLocale.languageCode == 'ar' ? Colors.white : Theme.of(context).colorScheme.onBackground))),
            },
          ),
        ],
      ),
    );
  }
}