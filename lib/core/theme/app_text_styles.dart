import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos de texto do tema Cyberpunk
/// Exo 2 — fonte principal
/// Share Tech Mono — fonte monoespaçada (dados, XP, counters)
class AppTextStyles {
  AppTextStyles._();

  // ─── Exo 2 — Display ─────────────────────────────────────────
  static final TextStyle displayLarge = GoogleFonts.exo2(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
      );

  static final TextStyle displayMedium = GoogleFonts.exo2(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      );

  // ─── Exo 2 — Títulos ─────────────────────────────────────────
  static final TextStyle titleLarge = GoogleFonts.exo2(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static final TextStyle titleMedium = GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static final TextStyle titleSmall = GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  // ─── Exo 2 — Body ────────────────────────────────────────────
  static final TextStyle bodyLarge = GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static final TextStyle bodyMedium = GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static final TextStyle bodySmall = GoogleFonts.exo2(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // ─── Exo 2 — Label ───────────────────────────────────────────
  static final TextStyle labelMedium = GoogleFonts.exo2(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );

  static final TextStyle labelSmall = GoogleFonts.exo2(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      );

  // ─── Share Tech Mono — Monoespaçado ──────────────────────────
  static final TextStyle monoLarge = GoogleFonts.shareTechMono(
        fontSize: 20,
        color: AppColors.primary,
        letterSpacing: 2.5,
      );

  static final TextStyle monoMedium = GoogleFonts.shareTechMono(
        fontSize: 15,
        color: AppColors.primary,
        letterSpacing: 1.8,
      );

  static final TextStyle monoSmall = GoogleFonts.shareTechMono(
        fontSize: 12,
        color: AppColors.primaryDim,
        letterSpacing: 1.4,
      );

  static final TextStyle monoXSmall = GoogleFonts.shareTechMono(
        fontSize: 10,
        color: AppColors.primaryDim,
        letterSpacing: 1.2,
      );
}
