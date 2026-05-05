import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Estilos de texto do tema Cyberpunk
/// Exo 2 — fonte principal
/// Share Tech Mono — fonte monoespaçada (dados, XP, counters)
class AppTextStyles {
  AppTextStyles._();

  // ─── Exo 2 — Display ─────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.exo2(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
      );

  static TextStyle get displayMedium => GoogleFonts.exo2(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      );

  // ─── Exo 2 — Títulos ─────────────────────────────────────────
  static TextStyle get titleLarge => GoogleFonts.exo2(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleSmall => GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  // ─── Exo 2 — Body ────────────────────────────────────────────
  static TextStyle get bodyLarge => GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.exo2(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.exo2(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // ─── Exo 2 — Label ───────────────────────────────────────────
  static TextStyle get labelMedium => GoogleFonts.exo2(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle get labelSmall => GoogleFonts.exo2(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      );

  // ─── Share Tech Mono — Monoespaçado ──────────────────────────
  static TextStyle get monoLarge => GoogleFonts.shareTechMono(
        fontSize: 20,
        color: AppColors.primary,
        letterSpacing: 2.5,
      );

  static TextStyle get monoMedium => GoogleFonts.shareTechMono(
        fontSize: 15,
        color: AppColors.primary,
        letterSpacing: 1.8,
      );

  static TextStyle get monoSmall => GoogleFonts.shareTechMono(
        fontSize: 12,
        color: AppColors.primaryDim,
        letterSpacing: 1.4,
      );

  static TextStyle get monoXSmall => GoogleFonts.shareTechMono(
        fontSize: 10,
        color: AppColors.primaryDim,
        letterSpacing: 1.2,
      );
}
