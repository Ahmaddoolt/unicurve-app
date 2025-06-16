// lib/pages/uni_admin/profile_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/general_settings_section.dart';
import 'package:unicurve/pages/uni_admin/providers/uni_admin_provider.dart';
// 1. Import the new reusable widget

class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminProfileAsync = ref.watch(adminProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('settings'.tr, style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Profile Information Section ---
          Text('profile_information'.tr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          adminProfileAsync.when(
            data: (admin) {
              final university = admin['universities'];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow('full_name'.tr, '${admin['first_name']} ${admin['last_name']}'),
                      _buildInfoRow('email_address'.tr, admin['email']),
                      _buildInfoRow('university'.tr, university != null ? university['name'] : 'N/A'),
                      _buildInfoRow('position'.tr, admin['position'], isLast: true),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
          
          const SizedBox(height: 32),

          // 2. Use the new reusable widget here.
          // This one widget now handles both Preferences and Account sections.
          const GeneralSettingsSection(),

        ],
      ),
    );
  }

  // This helper method is only used for the profile info, so it stays here.
  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}