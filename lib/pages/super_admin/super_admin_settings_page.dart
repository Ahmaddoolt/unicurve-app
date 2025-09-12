import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/settings/general_settings_section.dart';

class SuperAdminSettingsPage extends ConsumerWidget {
  const SuperAdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color? darkerColor = Theme.of(context).scaffoldBackgroundColor;
    Color? lighterColor = Theme.of(context).cardColor;
    Color? primaryTextColor = Theme.of(context).textTheme.bodyLarge?.color;

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
        children: const [GeneralSettingsSection()],
      ),
    );
  }
}
