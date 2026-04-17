import 'package:flutter/material.dart';

class AppColors {
  // Primary - Elegant Navy
  static const Color primary = Color(0xFF00008B);
  static const Color primaryLight = Color(0xFF2A2A9A);
  static const Color primaryDark = Color(0xFF000055);

  // Accents - Sky & Soft Ocean
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentSoft = Color(0xFFF0F9FF);

  // Luxury Palette
  static const Color gold = Color(0xFFD4AF37);
  static const Color platinum = Color(0xFFE5E4E2);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color glassWhite = Color(0xB3FFFFFF); // 70% white

  // Dark mode - Deep Night
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // Status & Progress
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);
  static const Color attendanceBar =
      Color(0xFFE2E8F0); // Grey background for progress bars
  static const Color attendanceFill = Color(0xFF00008B); // Blue fill

  // Subject Backgrounds (Soft colors for icons)
  static const Color subMath = Color(0xFFDBEAFE);
  static const Color subFrench = Color(0xFFFEE2E2);
  static const Color subScience = Color(0xFFD1FAE5);

  // Shadows & Borders
  static const Color borderColor = Color(0xFFF1F5F9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF2A2A9A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.9),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
  ];
}
