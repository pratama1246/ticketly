import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// TICKETLY — App Theme
// Semua color token dari DESIGN.md / input.css
// Jangan definisikan warna di luar file ini
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Background
  static const Color screenBg = Color(0xFFFFFDE7);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Primary Actions
  static const Color bluePrimary = Color(0xFF072AC8);
  static const Color bluePrimaryHover = Color(0xFF0626B4);
  static const Color bluePrimaryLight = Color(0xFFE6EAFA);

  // Secondary
  static const Color blueSecondary = Color(0xFF1E96FC);
  static const Color blueSecondaryLight = Color(0xFFE9F5FF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Border
  static const Color borderDefault = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF072AC8);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Accent
  static const Color accentYellow = Color(0xFFFFC600);
  static const Color accentYellowBright = Color(0xFFFCF300);

  // Ticket Tier Colors
  static const Color tierDreamZone = Color(0xFF4ADE80);
  static const Color tierFutureZone = Color(0xFF60A5FA);
  static const Color tierCat1 = Color(0xFFFBBF24);
  static const Color tierCat2 = Color(0xFFF472B6);
  static const Color tierCat3 = Color(0xFFF87171);
  static const Color tierCat4 = Color(0xFFA78BFA);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle pageTitleStyle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle sectionHeadingStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle cardTitleStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle bodyStyle = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle labelStyle = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle captionStyle = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.4,
  );

  static TextStyle ctaTextStyle = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle linkStyle = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.bluePrimary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.bluePrimary,
  );

  static TextStyle priceStyle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

class AppSpacing {
  AppSpacing._();

  static const double screenHorizontal = 16;
  static const double sectionVertical = 24;
  static const double cardGap = 12;
  static const double cardPadding = 12;
  static const double elementGap = 8;
}

class AppRadius {
  AppRadius._();

  static const double card = 16;
  static const double cardSmall = 12;
  static const double input = 12;
  static const double button = 999;
  static const double badge = 999;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> bottomNavShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, -2),
    ),
  ];
}
