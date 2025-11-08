import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_button.dart';
import 'package:unicurve/core/utils/custom_snackbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/data/services/auth_services.dart';
import 'package:unicurve/pages/all_apps/all_apps_page.dart';
import 'package:unicurve/pages/auth/login/login_view.dart';
import 'package:unicurve/settings/settings_provider.dart';
import 'package:url_launcher/url_launcher.dart'; 
class GeneralSettingsSection extends ConsumerWidget {
  final String userRole;

  const GeneralSettingsSection({
    super.key,
    this.userRole = 'student',
  });
  
  Future<void> _launchPrivacyPolicyURL(BuildContext context) async {
    final Uri url = Uri.parse('https://doc-hosting.flycricket.io/unicurve/82b23e0f-4776-44dd-b2db-85ed7ebb7656/privacy');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showFeedbackSnackbar(
          context,
          'error_launch_url'.tr,
          isError: true,
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Lottie.asset(
              'assets/5loading.json',
              width: 150,
              height: 150,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    _showLoadingDialog(context);

    final authService = AuthService();
    try {
      final prefs = await SharedPreferences.getInstance();

      final onboardingCompleted =
          prefs.getBool('onboarding_completed') ?? false;
      final themeIndex = prefs.getInt('themeMode');
      final langCode = prefs.getString('languageCode');
      final countryCode = prefs.getString('countryCode');

      await prefs.clear();

      await prefs.setBool('onboarding_completed', onboardingCompleted);
      if (themeIndex != null) await prefs.setInt('themeMode', themeIndex);
      if (langCode != null) await prefs.setString('languageCode', langCode);
      if (countryCode != null) {
        await prefs.setString('countryCode', countryCode);
      }

      await authService.signOut();

      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_unexpected'.trParams({'error': e.toString()})),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    _showLoadingDialog(context);
    final authService = AuthService();
    try {
      await authService.deleteCurrentUserAccount();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Account deleted successfully.'.tr),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleConfig = context.scaleConfig;
    final bool showAccountSection = userRole != 'super_admin';

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSectionHeader(context, 'preferences'.tr),
        SizedBox(height: scaleConfig.scale(12)),
        GlassCard(
          padding: EdgeInsets.symmetric(
            vertical: scaleConfig.scale(8),
            horizontal: scaleConfig.scale(16),
          ),
          child: Column(
            children: [
              _ThemeSelector(),
              const Divider(),
              _LanguageSelector(),
            ],
          ),
        ),

        SizedBox(height: scaleConfig.scale(32)),
        _buildSectionHeader(context, 'About'.tr),
        SizedBox(height: scaleConfig.scale(12)),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.apps, color: AppColors.accent),
                title: Text(
                  'Our Apps'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllAppsPage()),
                  );
                },
              ),
              const Divider(height: 1), 
              ListTile(
                leading: const Icon(Icons.shield_outlined, color: AppColors.accent),
                title: Text(
                  'Privacy Policy'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _launchPrivacyPolicyURL(context),
              ),
            ],
          ),
        ),

        if (showAccountSection) ...[
          SizedBox(height: scaleConfig.scale(32)),
          _buildSectionHeader(context, 'account'.tr),
          SizedBox(height: scaleConfig.scale(12)),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text(
                    'log_out'.tr,
                    style: const TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    final confirmed = await _showLogoutConfirmation(context);
                    if (confirmed == true) {
                      await _handleLogout(context, ref);
                    }
                  },
                ),
                if(userRole == 'student' || userRole == 'admin') ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppColors.error),
                    title: Text(
                      'Delete Account'.tr,
                      style: const TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      final confirmed = await _showDeleteConfirmation(context);
                      if (confirmed == true) {
                        await _handleDeleteAccount(context, ref);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: scaleConfig.scaleText(18),
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : theme.textTheme.titleLarge?.color,
          ),
        ),
        SizedBox(height: scaleConfig.scale(4)),
        Container(
          height: 3,
          width: scaleConfig.scale(40),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('log_out'.tr, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text('log_out_confirmation'.tr,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('cancel'.tr,
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color)),
                    ),
                    const SizedBox(width: 8),
                    CustomButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      text: 'log_out'.tr,
                      backgroundColor: AppColors.error,
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    const titleText = 'Confirm Deletion';
    const contentText = 'Are you sure you want to permanently delete your account? All of your data will be erased and this action cannot be undone.';
    const confirmButtonText = 'Delete';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: GlassCard(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText.tr,
                  style:
                      theme.textTheme.titleLarge?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                Text(
                  contentText.tr,
                  style: theme.textTheme.bodyMedium
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('cancel'.tr,
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color)),
                    ),
                    const SizedBox(width: 8),
                    CustomButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      text: confirmButtonText.tr,
                      backgroundColor: AppColors.error,
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final scaleConfig = context.scaleConfig;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('app_theme'.tr, style: Theme.of(context).textTheme.bodyLarge),
          Row(
            children: [
              _ToggleButton(
                icon: Icons.light_mode_outlined,
                isSelected: themeMode == ThemeMode.light,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
              ),
              SizedBox(width: scaleConfig.scale(8)),
              _ToggleButton(
                icon: Icons.dark_mode_outlined,
                isSelected: themeMode == ThemeMode.dark,
                onTap: () =>
                    ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);
    final scaleConfig = context.scaleConfig;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('language'.tr, style: Theme.of(context).textTheme.bodyLarge),
          Row(
            children: [
              _ToggleButton(
                text: 'EN',
                isSelected: currentLocale.languageCode == 'en',
                onTap: () =>
                    ref.read(languageProvider.notifier).setLanguage('en', 'US'),
              ),
              SizedBox(width: scaleConfig.scale(8)),
              _ToggleButton(
                text: 'AR',
                isSelected: currentLocale.languageCode == 'ar',
                onTap: () =>
                    ref.read(languageProvider.notifier).setLanguage('ar', 'SA'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData? icon;
  final String? text;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton(
      {this.icon, this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: scaleConfig.scale(50),
        height: scaleConfig.scale(40),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected
              ? null
              : (isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : theme.scaffoldBackgroundColor),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? null
              : Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : theme.dividerColor),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                )
              : Text(
                  text ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
        ),
      ),
    );
  }
}