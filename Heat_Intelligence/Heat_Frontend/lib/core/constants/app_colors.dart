import 'package:flutter/material.dart';

/// Centralized color palette for Heat Detection Intelligence
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color accent = Color(0xFFFF6D00);

  // Heat risk colors
  static const Color heatHigh = Color(0xFFE53935);
  static const Color heatHighLight = Color(0xFFFF8A80);
  static const Color heatModerate = Color(0xFFFFA726);
  static const Color heatModerateLight = Color(0xFFFFE0B2);
  static const Color heatSafe = Color(0xFF43A047);
  static const Color heatSafeLight = Color(0xFFC8E6C9);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2C2C2C);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textDarkMode = Color(0xFFE0E0E0);

  // Chart gradient
  static const List<Color> heatGradient = [
    Color(0xFF43A047),
    Color(0xFFFFA726),
    Color(0xFFE53935),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFE53935)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns risk color based on score (0.0 - 1.0)
  static Color getRiskColor(double riskScore) {
    if (riskScore >= 0.75) return heatHigh;
    if (riskScore >= 0.40) return heatModerate;
    return heatSafe;
  }

  /// Returns risk background color based on score
  static Color getRiskBackgroundColor(double riskScore) {
    if (riskScore >= 0.75) return heatHighLight;
    if (riskScore >= 0.40) return heatModerateLight;
    return heatSafeLight;
  }
}
