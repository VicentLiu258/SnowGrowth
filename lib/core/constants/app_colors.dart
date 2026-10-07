import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary (IC Signature Gold / Amber)
  static const Color primary = Color(0xFFF5A623);
  static const Color primaryHover = Color(0xFFE09510);
  static const Color primaryPress = Color(0xFFC9830A);
  static const Color primaryLight = Color(0xFFFFF8EB);
  static const Color primaryBorder = Color(0xFFFCE8BD);

  // Brand accents
  static const Color brandGreen = Color(0xFF0DC101);
  static const Color brandBlue = Color(0xFF3B82F6);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color telegram = Color(0xFF229ED9);
  static const Color agentBlue = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFEF4444);
  static const Color danger = Color(0xFFDC2626);

  // Surfaces
  static const Color background = Color(0xFFF4F6FA);
  static const Color cardBackground = Colors.white;
  static const Color surfaceHover = Color(0xFFF9FAFB);
  static const Color surfaceActive = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF8C93A4);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Borders
  static const Color border = Color(0xFFEAECF0);
  static const Color borderLight = Color(0xFFF1F3F5);
  static const Color divider = Color(0xFFF3F4F6);

  // Tool icon tints
  static const Color iconBgOrange = Color(0xFFFFF4E6);
  static const Color iconColorOrange = Color(0xFFF97316);
  static const Color iconBgGold = Color(0xFFFEF7DC);
  static const Color iconColorGold = Color(0xFFD97706);
  static const Color iconBgRose = Color(0xFFFFE4E8);
  static const Color iconColorRose = Color(0xFFE11D48);
  static const Color iconBgBlue = Color(0xFFE0F2FE);
  static const Color iconColorBlue = Color(0xFF0284C7);

  // Home top gradient
  static const Color gradientStart = Color(0xFFECE7F9);
  static const Color gradientMid = Color(0xFFE3EEFC);
  static const Color gradientEnd = Color(0xFFDDF1FE);

  static const LinearGradient homeTopGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
    stops: [0.0, 0.52, 1.0],
  );

  // Backward-compatible aliases used by older widgets/tests
  static const Color emerald50 = Color(0xFFFFF8EB);
  static const Color emerald100 = Color(0xFFFCE8BD);
  static const Color emerald500 = primary;
  static const Color emerald600 = primaryHover;
  static const Color emerald700 = primaryPress;

  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = textMuted;
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = textSecondary;
  static const Color gray700 = Color(0xFF374151);
  static const Color gray900 = textPrimary;
}
