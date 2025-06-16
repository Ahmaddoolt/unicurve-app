// lib/pages/student/student_settings_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/general_settings_section.dart';
// Make sure this path to your reusable widget is correct

class StudentSettingsPage extends StatelessWidget {
  const StudentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use theme colors for consistency
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        // Use theme colors for consistency
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('settings'.tr, style: Theme.of(context).appBarTheme.titleTextStyle),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: GeneralSettingsSection(),
      ),
    );
  }
}