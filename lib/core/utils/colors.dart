// lib/core/utils/colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // --- LOGO GRADIENT PALETTE (5-COLOR SPECTRUM) ---
  static const Color gradientBlueStart = Color(0xFF2D62ED);
  static const Color gradientBlueMid = Color(0xFF3B82F6);
  static const Color gradientTeal = Color(0xFF2DD4BF);
  static const Color gradientGreenMid = Color(0xFF3FCF8E);
  static const Color gradientGreenEnd = Color(0xFF81F374);

  // --- NEW: Dark Theme Gradient Colors ---
  static const Color gradientDarkBlue = Color(0xFF1E3A8A); // A deep navy blue
  static const Color gradientDarkTeal =
      Color(0xFF14532D); // A dark forest green

  // Define single primary/accent for fallbacks and simple elements
  static const Color primary = gradientGreenMid;
  static const Color accent = gradientBlueMid;

  // Standard functional colors
  static const Color error = Color(0xFFE53935);

  // --- THE OFFICIAL BRAND GRADIENTS ---
  static const Gradient primaryGradient = LinearGradient(
    colors: [
      gradientBlueStart,
      gradientBlueMid,
      gradientTeal,
      gradientGreenMid,
      gradientGreenEnd
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [gradientBlueStart, gradientBlueMid],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- NEW: Dark Theme Gradient ---
  static const Gradient darkPrimaryGradient = LinearGradient(
    colors: [gradientDarkBlue, gradientDarkTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient disabledGradient = LinearGradient(
    colors: [Colors.grey, Colors.grey],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // --- THEME-SPECIFIC COLORS ---
  // Light Theme
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF7F8FA);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6E6E73);

  // Dark Theme
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
}
