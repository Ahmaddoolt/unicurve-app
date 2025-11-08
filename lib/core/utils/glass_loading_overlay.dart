// lib/core/utils/glass_loading_overlay.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // --- FIX: Import the Lottie package ---

class GlassLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const GlassLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The main content of the page, which is always visible
        child,

        // The overlay, which is conditionally visible on top
        if (isLoading)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.black
                      .withOpacity(0.2), // Slightly darker for better contrast
                  child: Center(
                    // --- THE KEY CHANGE IS HERE ---
                    // Replace CircularProgressIndicator with the Lottie animation
                    child: Lottie.asset(
                      'assets/5loading.json',
                      width: 150, // Adjust size as needed
                      height: 150, // Adjust size as needed
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
