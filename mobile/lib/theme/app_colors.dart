import 'package:flutter/material.dart';

class AppColors {
  // Dark Backgrounds (Default)
  static const Color background = Color(0xFF070D15);
  static const Color surface = Color(0xFF0F1824);
  static const Color surfaceElevated = Color(0xFF162334);
  static const Color surfaceLight = Color(0xFF1D2C40);

  // Dark Borders
  static const Color border = Color(0xFF1E2F46);
  static const Color borderSubtle = Color(0xFF142234);

  // Dark Text
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Light Palette (Balanced, soft Slate tones, avoiding harsh glare and eliminating all dark blues)
  static const Color lightBackground = Color(0xFFF1F5F9); // Soft slate 100
  static const Color lightSurface = Colors.white;         // Clean white cards
  static const Color lightSurfaceElevated = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurfaceLight = Color(0xFFE2E8F0);    // Slate 200 for badges/pills

  // Light Borders
  static const Color lightBorder = Color(0xFFE2E8F0);          // Slate 200
  static const Color lightBorderSubtle = Color(0xFFCBD5E1);    // Slate 300

  // Light Text
  static const Color lightTextPrimary = Color(0xFF0F172A);     // Deep Slate 900
  static const Color lightTextSecondary = Color(0xFF334155);   // Slate 700
  static const Color lightTextMuted = Color(0xFF64748B);       // Slate 500

  // Accents (Consistent across themes)
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldGlow = Color(0x3310B981);

  static const Color liveRed = Color(0xFFEF4444);
  static const Color liveRedBg = Color(0x29EF4444);

  static const Color amber = Color(0xFFF59E0B);
  static const Color amberBg = Color(0x29F59E0B);

  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);

  // Context-aware dynamic helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color bgOf(BuildContext context) => isDark(context) ? background : lightBackground;
  static Color surfaceOf(BuildContext context) => isDark(context) ? surface : lightSurface;
  static Color surfaceElevatedOf(BuildContext context) => isDark(context) ? surfaceElevated : lightSurfaceElevated;
  static Color surfaceLightOf(BuildContext context) => isDark(context) ? surfaceLight : lightSurfaceLight;

  static Color borderOf(BuildContext context) => isDark(context) ? border : lightBorder;
  static Color borderSubtleOf(BuildContext context) => isDark(context) ? borderSubtle : lightBorder;

  static Color textPrimaryOf(BuildContext context) => isDark(context) ? textPrimary : lightTextPrimary;
  static Color textSecondaryOf(BuildContext context) => isDark(context) ? textSecondary : lightTextSecondary;
  static Color textMutedOf(BuildContext context) => isDark(context) ? textMuted : lightTextMuted;
}

extension AppThemeColorsExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.background : AppColors.lightBackground;
  Color get surface => isDark ? AppColors.surface : AppColors.lightSurface;
  Color get surfaceElevated => isDark ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;
  Color get surfaceLight => isDark ? AppColors.surfaceLight : AppColors.lightSurfaceLight;
  Color get border => isDark ? AppColors.border : AppColors.lightBorder;
  Color get borderSubtle => isDark ? AppColors.borderSubtle : AppColors.lightBorder;
  Color get textPrimary => isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get textMuted => isDark ? AppColors.textMuted : AppColors.lightTextMuted;
}
