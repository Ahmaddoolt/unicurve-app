// lib/core/utils/gradient_scaffold.dart

import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/custom_appbar.dart';

class GradientScaffold extends StatelessWidget {
  final CustomAppBar? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // The scaffold itself is always transparent
      backgroundColor: Colors.transparent,
      body: Container(
        // The container provides the background for the entire screen
        decoration: BoxDecoration(
          // Apply the dark gradient ONLY in dark mode
          gradient: isDarkMode ? AppColors.darkPrimaryGradient : null,
          // Apply the solid light background color ONLY in light mode
          color: isDarkMode ? null : theme.scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            // If an appBar is provided, display it
            if (appBar != null) appBar!,
            // The rest of the page content
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
