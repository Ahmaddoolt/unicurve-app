import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/settings/general_settings_section.dart';
import 'package:unicurve/pages/uni_admin/providers/uni_admin_provider.dart';

class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminProfileAsync = ref.watch(adminProfileProvider);
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    Color? secondaryTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: lighterColor,
      appBar: AppBar(
        title: Text('settings'.tr, style: TextStyle(color: primaryTextColor)),
        backgroundColor: darkerColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'profile_information'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          adminProfileAsync.when(
            data: (admin) {
              final university = admin['universities'];
              final String fullName =
                  (admin['first_name'] != null && admin['last_name'] != null)
                      ? '${admin['first_name']} ${admin['last_name']}'
                      : 'N/A';
              final String email = admin['email'] ?? 'N/A';
              final String universityName =
                  university != null ? university['name'] : 'N/A';
              final String position = admin['position'] ?? 'N/A';

              return Card(
                color: darkerColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        secondaryTextColor!,
                        'full_name'.tr,
                        fullName,
                      ),
                      _buildInfoRow(
                        context,
                        secondaryTextColor,
                        'email_address'.tr,
                        email,
                      ),
                      _buildInfoRow(
                        context,
                        secondaryTextColor,
                        'university'.tr,
                        universityName,
                      ),
                      _buildInfoRow(
                        context,
                        secondaryTextColor,
                        'position'.tr,
                        position,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              );
            },
            loading:
                () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            error:
                (e, st) => Center(
                  child: Text(
                    'profile_load_error'.tr,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
          ),
          const SizedBox(height: 32),
          const GeneralSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    Color textColor,
    String label,
    String value, {
    bool isLast = false,
  }) {
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12, // Increased font size
            ),
          ),
          const SizedBox(width: 16), // Add a gap between label and value
          // The Expanded widget takes all remaining horizontal space
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end, // Aligns the text to the right
              overflow: TextOverflow.ellipsis, // Adds '...' if text is too long
              maxLines: 1, // Ensures the text stays on a single line
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 12, // Increased font size
              ),
            ),
          ),
        ],
      ),
    );
  }
}
