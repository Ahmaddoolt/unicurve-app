// lib/pages/all_apps/all_apps_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart'; // --- FIX: Import the Lottie package ---
import 'package:unicurve/core/utils/custom_appbar.dart';
import 'package:unicurve/core/utils/gradient_scaffold.dart';
import 'package:unicurve/data/services/app_hub_service.dart';
import 'package:unicurve/pages/all_apps/widgets/my_app_card.dart';

class AllAppsPage extends ConsumerWidget {
  const AllAppsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final appsAsync = ref.watch(allAppsProvider);

    final appBar = CustomAppBar(
      useGradient: !isDarkMode,
      title: 'Our Apps'.tr,
    );

    // --- FIX: The body content no longer needs the GlassLoadingOverlay ---
    // The .when() block will now handle the loading state directly.
    final bodyContent = RefreshIndicator(
      onRefresh: () => ref.refresh(allAppsProvider.future),
      color: theme.primaryColor,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: appsAsync.when(
        data: (apps) {
          // If there's no data, show an informative message.
          if (apps.isEmpty) {
            return const Center(child: Text('No apps to show right now.'));
          }
          // If there is data, build the list.
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              return MyAppCard(app: apps[index]);
            },
          );
        },
        // --- FIX: Display the Lottie animation directly in the 'loading' state ---
        loading: () => Center(
          child: Lottie.asset(
            'assets/5loading.json', // Your Lottie animation file
            width: 150,
            height: 150,
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
      ),
    );

    if (isDarkMode) {
      return GradientScaffold(appBar: appBar, body: bodyContent);
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: appBar,
        body: bodyContent,
      );
    }
  }
}