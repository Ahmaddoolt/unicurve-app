// lib/pages/uni_admin/profile_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/glass_loading_overlay.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/settings/general_settings_section.dart';
import 'package:unicurve/pages/uni_admin/providers/uni_admin_provider.dart';

class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminProfileAsync = ref.watch(adminProfileProvider);
    final scaleConfig = context.scaleConfig;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'settings'.tr,
    );

    final bodyContent =
        _buildContent(context, ref, scaleConfig, adminProfileAsync);

    if (isDarkMode) {
      return GradientScaffold(
        appBar: appBar,
        body: bodyContent,
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
      );
    }
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ScaleConfig scaleConfig,
    AsyncValue<Map<String, dynamic>> adminProfileAsync,
  ) {
    return GlassLoadingOverlay(
      isLoading: adminProfileAsync.isLoading && !adminProfileAsync.hasValue,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(scaleConfig.scale(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'profile_information'.tr),
            SizedBox(height: scaleConfig.scale(12)),
            if (adminProfileAsync.hasError)
              Card(
                color: AppColors.error.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'error_generic'.trParams(
                          {'error': adminProfileAsync.error.toString()}),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              )
            else if (adminProfileAsync.hasValue)
              _buildProfileInfoCard(
                  context, scaleConfig, adminProfileAsync.value!),
            SizedBox(height: scaleConfig.scale(32)),
            // --- THE KEY FIX IS HERE ---
            // We are passing the user role to the shared settings widget.
            const GeneralSettingsSection(userRole: 'admin'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, ScaleConfig scaleConfig,
      Map<String, dynamic> admin) {
    final university = admin['universities'];
    final String fullName =
        (admin['first_name'] != null && admin['last_name'] != null)
            ? '${admin['first_name']} ${admin['last_name']}'
            : 'N/A';
    final String email = admin['email'] ?? 'N/A';
    final String universityName =
        university != null ? university['name'] : 'N/A';
    final String position = admin['position'] ?? 'N/A';

    return GlassCard(
      padding: EdgeInsets.symmetric(
        vertical: scaleConfig.scale(8),
        horizontal: scaleConfig.scale(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(context,
              icon: Icons.person_outline,
              label: 'full_name'.tr,
              value: fullName),
          const Divider(),
          _buildInfoRow(context,
              icon: Icons.email_outlined,
              label: 'email_address'.tr,
              value: email),
          const Divider(),
          _buildInfoRow(context,
              icon: Icons.school_outlined,
              label: 'university'.tr,
              value: universityName),
          const Divider(),
          _buildInfoRow(context,
              icon: Icons.work_outline,
              label: 'position'.tr,
              value: position,
              isLast: true),
        ],
      ),
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

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: scaleConfig.scale(12)),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.textTheme.bodyMedium?.color,
            size: scaleConfig.scale(22),
          ),
          SizedBox(width: scaleConfig.scale(16)),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}