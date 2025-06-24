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
  final double devicePixelRatio;
  final double textScaleFactor;

  // Reference dimensions (iPhone 13: 390x844 logical pixels)
  static const double _referenceWidth = 390;
  // ignore: unused_field
  static const double _referenceHeight = 844;

  ScaleConfig._({
    required this.screenWidth,
    required this.screenHeight,
    required this.orientation,
    required this.devicePixelRatio,
    required this.textScaleFactor,
  });

  factory ScaleConfig(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    return ScaleConfig._(
      screenWidth: size.width,
      screenHeight: size.height,
      orientation: mediaQuery.orientation,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      // ignore: deprecated_member_use
      textScaleFactor: mediaQuery.textScaleFactor,
    );
  }

  /// Scaling factor based on screen width, adjusted for orientation
  double get scaleFactor {
    final baseFactor = screenWidth / _referenceWidth;
    // Adjust for landscape mode (wider screens may need less aggressive scaling)
    return orientation == Orientation.landscape
        ? baseFactor.clamp(0.9, 1.5)
        : baseFactor.clamp(0.8, 2.0);
  }

  /// Scales a value (e.g., padding, margin, icon size) based on screen width
  double scale(double size) {
    final scaled = size * scaleFactor;
    // Looser clamp to allow more flexibility on large screens
    return scaled.clamp(size * 0.85, size * 3.0);
  }

  /// Scales font size, respecting both screen size and user-defined textScaleFactor
  double scaleText(double fontSize) {
    // Base scaling using screen size
    final scaledFont = scale(fontSize);
    // Adjust for device pixel density to ensure crisp text
    final adjustedFont = scaledFont / (devicePixelRatio / 2.0).clamp(1.0, 1.5);
    // Flutter applies textScaleFactor automatically, so we return the base size
    return adjustedFont.clamp(fontSize * 0.9, fontSize * 2.5);
  }

  /// Returns a percentage of the screen's width
  double widthPercentage(double percentage) {
    final p = percentage.clamp(0.0, 1.0);
    return screenWidth * p;
  }

  /// Returns a percentage of the screen's height
  double heightPercentage(double percentage) {
    final p = percentage.clamp(0.0, 1.0);
    return screenHeight * p;
  }

  /// Enhanced tablet detection
  bool get isTablet {
    final shortestSide =
        screenWidth < screenHeight ? screenWidth : screenHeight;
    return shortestSide >= 600 && devicePixelRatio >= 1.5;
  }

  /// Adjusts scaling for tablets
  double tabletScale(double size) {
    return isTablet ? scale(size) * 1.2 : scale(size);
  }

  /// Adjusts font scaling for tablets
  double tabletScaleText(double fontSize) {
    return isTablet ? scaleText(fontSize) * 1.15 : scaleText(fontSize);
  }
}
