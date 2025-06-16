// lib/core/utils/scale_config.dart

import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  ThemeData get appTheme => Theme.of(this);
  TextTheme get appTextTheme => Theme.of(this).textTheme;
  ScaleConfig get scaleConfig => ScaleConfig(this);
}

class ScaleConfig {
  final double screenWidth;
  final double screenHeight;
  final Orientation orientation;

  // --- INTERNAL ---: These are the base dimensions we scale from.
  // Using common iPhone dimensions as a reference.
  static const double _referenceWidth = 375;
  static const double _referenceHeight = 812;

  ScaleConfig._({
    required this.screenWidth,
    required this.screenHeight,
    required this.orientation,
  });

  factory ScaleConfig(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    return ScaleConfig._(
      screenWidth: size.width,
      screenHeight: size.height,
      orientation: mediaQuery.orientation,
    );
  }

  /// The general scaling factor, based on the screen's width.
  /// This is the most common and reliable method for scaling.
  double get scaleFactor => screenWidth / _referenceWidth;

  /// Scales a value (like padding, margin, icon size, etc.) based on the screen width.
  /// This keeps your UI elements proportional.
  /// The clamp prevents elements from becoming too small on tiny screens or excessively large on huge screens.
  double scale(double size) {
    return (size * scaleFactor).clamp(size * 0.8, size * 2.5);
  }

  /// **--- CORRECTED FONT SCALING ---**
  /// Scales a font size based on the screen width.
  ///
  /// **Why this is correct:**
  /// 1. We calculate a base font size that is proportional to the screen (`scale(fontSize)`).
  /// 2. We then let Flutter's rendering engine automatically multiply this result by the
  ///    system's text scale factor (`MediaQuery.of(context).textScaleFactor`).
  ///
  /// This way, your fonts scale with the screen size, AND they respect the user's
  /// accessibility settings without you having to manage `textScaleFactor` manually.
  /// This fixes the bug where text became too large on devices with custom font settings.
  double scaleText(double fontSize) {
    // We simply use the general scale method. Fonts are just another size.
    // Flutter will handle the rest regarding system font size settings.
    return scale(fontSize);
  }

  /// Returns a percentage of the screen's width.
  /// Useful for elements that should take up a specific portion of the screen.
  double widthPercentage(double percentage) {
    // Ensure percentage is between 0.0 and 1.0
    final p = percentage.clamp(0.0, 1.0);
    return screenWidth * p;
  }

  /// Returns a percentage of the screen's height.
  double heightPercentage(double percentage) {
    // Ensure percentage is between 0.0 and 1.0
    final p = percentage.clamp(0.0, 1.0);
    return screenHeight * p;
  }

  /// A simple check for tablet-sized devices.
  bool get isTablet {
    // A common way to check for a tablet is by the shortest side of the screen.
    final shortestSide = screenWidth < screenHeight ? screenWidth : screenHeight;
    return shortestSide > 600;
  }
}