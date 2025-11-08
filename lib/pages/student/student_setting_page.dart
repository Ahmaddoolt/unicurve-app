// lib/pages/student/student_setting_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/settings/general_settings_section.dart';

class StudentSettingsPage extends StatelessWidget {
  const StudentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'settings'.tr,
    );

    const bodyContent = SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      // --- THE KEY FIX IS HERE ---
      // We are passing the user role to the shared settings widget.
      // The default is 'student', so this is explicit but could be omitted.
      child: GeneralSettingsSection(userRole: 'student'),
    );

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
}