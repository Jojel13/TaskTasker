import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/models/enums.dart';
import 'app_colors.dart';

enum ParticleShape {
  circle,
  star,
  binary,
  organic,
  cross,
  ember,
  sakura,
  bubble,
  leaf,
}

class AppThemeData {
  final AppThemeType type;
  final String name;

  // ─── Background & Surface Colors ─────────────────────────────
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color border;
  final Color divider;

  // ─── Text Colors ──────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // ─── Brand/UI Accent Colors ───────────────────────────────────
  final Color primary;
  final Color primaryDim;
  final Color secondary;
  final Color secondaryDim;
  final Color accent;
  final Color accentDim;

  // ─── Task Card Colors ─────────────────────────────────────────
  final Color taskStandard;
  final Color taskBlue;
  final Color taskYellow;
  final Color taskRed;

  final Color cardStandard;
  final Color cardBlue;
  final Color cardYellow;
  final Color cardRed;

  final Color glowBlue;
  final Color glowYellow;
  final Color glowRed;

  // ─── Card Border Styling ──────────────────────────────────────
  final double borderRadius;
  final double borderWidth;
  final bool useGlowBorder;
  final List<BoxShadow> Function(Color color, {double intensity}) glowShadow;

  // ─── Typography (Dynamic Fonts) ────────────────────────────────
  final TextStyle Function(TextStyle base) fontStyleBase;
  final TextStyle Function(TextStyle base) fontStyleMono;

  // ─── Dynamic Particle Configuration ───────────────────────────
  final ParticleShape particleShape;
  final int particleCount;
  final double particleSpeed;
  final double particleOpacity;
  final List<Color> particleColors;
  final bool connectLines;

  AppThemeData({
    required this.type,
    required this.name,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryDim,
    required this.secondary,
    required this.secondaryDim,
    required this.accent,
    required this.accentDim,
    required this.taskStandard,
    required this.taskBlue,
    required this.taskYellow,
    required this.taskRed,
    required this.cardStandard,
    required this.cardBlue,
    required this.cardYellow,
    required this.cardRed,
    required this.glowBlue,
    required this.glowYellow,
    required this.glowRed,
    required this.borderRadius,
    required this.borderWidth,
    required this.useGlowBorder,
    required this.glowShadow,
    required this.fontStyleBase,
    required this.fontStyleMono,
    required this.particleShape,
    required this.particleCount,
    required this.particleSpeed,
    required this.particleOpacity,
    required this.particleColors,
    required this.connectLines,
  });

  factory AppThemeData.fromType(AppThemeType type) {
    switch (type) {
      // 1. Cyberpunk Dark (Original)
      case AppThemeType.cyberpunkDark:
        return AppThemeData(
          type: type,
          name: 'Cyberpunk Dark',
          background: const Color(0xFF070B14),
          surface: const Color(0xFF11111E),
          surfaceVariant: const Color(0xFF1A1A2A),
          card: const Color(0xFF0F0F1A),
          border: const Color(0xFF222222),
          divider: const Color(0xFF181818),
          textPrimary: const Color(0xFFF0F0F0),
          textSecondary: const Color(0xFF8A8A8A),
          textMuted: const Color(0xFF3D3D3D),
          primary: const Color(0xFF208AF0),
          primaryDim: const Color(0xFF165FA6),
          secondary: const Color(0xFFFE802B),
          secondaryDim: const Color(0xFFB2591B),
          accent: const Color(0xFF23C9B1),
          accentDim: const Color(0xFF188B7B),
          taskStandard: const Color(0xFFD0D0D0),
          taskBlue: const Color(0xFF208AF0),
          taskYellow: const Color(0xFFFFCC00),
          taskRed: const Color(0xFFFF4D4D),
          cardStandard: const Color(0xFF11111E),
          cardBlue: const Color(0xFF081428),
          cardYellow: const Color(0xFF1E1A05),
          cardRed: const Color(0xFF1C0505),
          glowBlue: const Color(0x66208AF0),
          glowYellow: const Color(0x66FFCC00),
          glowRed: const Color(0x66FF4D4D),
          borderRadius: 12.0,
          borderWidth: 1.0,
          useGlowBorder: true,
          glowShadow: (color, {intensity = 1.0}) => AppColors.glowShadow(color, intensity: intensity),
          fontStyleBase: (base) => GoogleFonts.exo2(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.shareTechMono(textStyle: base),
          particleShape: ParticleShape.circle,
          particleCount: 15,
          particleSpeed: 0.8,
          particleOpacity: 0.35,
          particleColors: const [Color(0xFF208AF0), Color(0xFFFE802B), Color(0xFF23C9B1)],
          connectLines: true,
        );

      // 2. Neon Synthwave
      case AppThemeType.synthwave:
        const primaryColor = Color(0xFFFE00F6);
        const secondaryColor = Color(0xFF00F0FF);
        return AppThemeData(
          type: type,
          name: 'Neon Synthwave',
          background: const Color(0xFF120324),
          surface: const Color(0xFF24063c),
          surfaceVariant: const Color(0xFF340c54),
          card: const Color(0xFF1b0530),
          border: const Color(0xFFFE00F6).withValues(alpha: 0.3),
          divider: const Color(0xFFFE00F6).withValues(alpha: 0.15),
          textPrimary: const Color(0xFFFFFFFF),
          textSecondary: const Color(0xFFFF7DFB),
          textMuted: const Color(0xFF70327A),
          primary: primaryColor,
          primaryDim: const Color(0xFFB000AB),
          secondary: secondaryColor,
          secondaryDim: const Color(0xFF00A2AD),
          accent: const Color(0xFFFFB000),
          accentDim: const Color(0xFFB87F00),
          taskStandard: const Color(0xFFF3E3F4),
          taskBlue: const Color(0xFF00F0FF),
          taskYellow: const Color(0xFFFFE600),
          taskRed: const Color(0xFFFE00F6),
          cardStandard: const Color(0xFF200636),
          cardBlue: const Color(0xFF021A30),
          cardYellow: const Color(0xFF261D02),
          cardRed: const Color(0xFF2F042C),
          glowBlue: const Color(0x6600F0FF),
          glowYellow: const Color(0x66FFE600),
          glowRed: const Color(0x66FE00F6),
          borderRadius: 8.0,
          borderWidth: 1.5,
          useGlowBorder: true,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: color.withValues(alpha: 0.6 * intensity),
              blurRadius: 12 * intensity,
              spreadRadius: 1,
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.orbitron(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.shareTechMono(textStyle: base),
          particleShape: ParticleShape.star,
          particleCount: 22,
          particleSpeed: 0.9,
          particleOpacity: 0.45,
          particleColors: const [Color(0xFFFE00F6), Color(0xFF00F0FF), Color(0xFFFFB000)],
          connectLines: false,
        );

      // 3. Matrix Terminal
      case AppThemeType.matrix:
        const greenColor = Color(0xFF00FF00);
        return AppThemeData(
          type: type,
          name: 'Matrix Terminal',
          background: const Color(0xFF000000),
          surface: const Color(0xFF081008),
          surfaceVariant: const Color(0xFF102010),
          card: const Color(0xFF040804),
          border: const Color(0xFF005500),
          divider: const Color(0xFF003300),
          textPrimary: const Color(0xFF00FF00),
          textSecondary: const Color(0xFF00AA00),
          textMuted: const Color(0xFF004400),
          primary: greenColor,
          primaryDim: const Color(0xFF008800),
          secondary: const Color(0xFF00DD00),
          secondaryDim: const Color(0xFF007700),
          accent: const Color(0xFF00FF00),
          accentDim: const Color(0xFF008800),
          taskStandard: const Color(0xFF88FF88),
          taskBlue: const Color(0xFF008800),
          taskYellow: const Color(0xFFCCFF00),
          taskRed: const Color(0xFFFF0000),
          cardStandard: const Color(0xFF060D06),
          cardBlue: const Color(0xFF001100),
          cardYellow: const Color(0xFF111100),
          cardRed: const Color(0xFF1A0000),
          glowBlue: const Color(0x66008800),
          glowYellow: const Color(0x66CCFF00),
          glowRed: const Color(0x66FF0000),
          borderRadius: 2.0,
          borderWidth: 1.5,
          useGlowBorder: false,
          glowShadow: (color, {intensity = 1.0}) => [],
          fontStyleBase: (base) => GoogleFonts.shareTechMono(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.shareTechMono(textStyle: base),
          particleShape: ParticleShape.binary,
          particleCount: 30,
          particleSpeed: 1.8,
          particleOpacity: 0.35,
          particleColors: const [Color(0xFF00FF00), Color(0xFF008800)],
          connectLines: false,
        );

      // 4. Minimalist Light
      case AppThemeType.minimalLight:
        return AppThemeData(
          type: type,
          name: 'Minimal Light',
          background: const Color(0xFFF6F6F9),
          surface: const Color(0xFFFFFFFF),
          surfaceVariant: const Color(0xFFEEEEF3),
          card: const Color(0xFFFFFFFF),
          border: const Color(0xFFE2E2E9),
          divider: const Color(0xFFEBEBEF),
          textPrimary: const Color(0xFF1E2022),
          textSecondary: const Color(0xFF525860),
          textMuted: const Color(0xFF78818C),
          primary: const Color(0xFF0066CC),
          primaryDim: const Color(0xFF0044AA),
          secondary: const Color(0xFFEE6C4D),
          secondaryDim: const Color(0xFFC04E32),
          accent: const Color(0xFF0077CC),
          accentDim: const Color(0xFF005599),
          taskStandard: const Color(0xFF2B2E3A),
          taskBlue: const Color(0xFF0066CC),
          taskYellow: const Color(0xFFD97706),
          taskRed: const Color(0xFFDC2626),
          cardStandard: const Color(0xFFFFFFFF),
          cardBlue: const Color(0xFFF0F6FE),
          cardYellow: const Color(0xFFFFFBEB),
          cardRed: const Color(0xFFFEF2F2),
          glowBlue: const Color(0x1A0066CC),
          glowYellow: const Color(0x1AD97706),
          glowRed: const Color(0x1ADC2626),
          borderRadius: 24.0,
          borderWidth: 0.0,
          useGlowBorder: false,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04 * intensity),
              blurRadius: 10 * intensity,
              offset: const Offset(0, 4),
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.inter(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.inter(textStyle: base),
          particleShape: ParticleShape.organic,
          particleCount: 10,
          particleSpeed: 0.3,
          particleOpacity: 0.10,
          particleColors: const [Color(0xFF676E75), Color(0xFF0066CC), Color(0xFFA5ADB7)],
          connectLines: false,
        );

      // 5. Retro Solarized
      case AppThemeType.solarizedOchre:
        return AppThemeData(
          type: type,
          name: 'Solarized Ochre',
          background: const Color(0xFFFDF6E3),
          surface: const Color(0xFFEEE8D5),
          surfaceVariant: const Color(0xFFE4DCB9),
          card: const Color(0xFFF5EEDC),
          border: const Color(0xFFD3C6A2),
          divider: const Color(0xFFDFD5B6),
          textPrimary: const Color(0xFF586E75),
          textSecondary: const Color(0xFF657B83),
          textMuted: const Color(0xFF93A1A1),
          primary: const Color(0xFFB58900),
          primaryDim: const Color(0xFF8A6B00),
          secondary: const Color(0xFFD33682),
          secondaryDim: const Color(0xFF9B275E),
          accent: const Color(0xFF2AA198),
          accentDim: const Color(0xFF1D736C),
          taskStandard: const Color(0xFF839496),
          taskBlue: const Color(0xFF268BD2),
          taskYellow: const Color(0xFFB58900),
          taskRed: const Color(0xFFDC322F),
          cardStandard: const Color(0xFFEFE8D3),
          cardBlue: const Color(0xFFE1ECF4),
          cardYellow: const Color(0xFFF7EED3),
          cardRed: const Color(0xFFFCEAE9),
          glowBlue: const Color(0x26268BD2),
          glowYellow: const Color(0x26B58900),
          glowRed: const Color(0x26DC322F),
          borderRadius: 16.0,
          borderWidth: 1.0,
          useGlowBorder: false,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: const Color(0xFF586E75).withValues(alpha: 0.08 * intensity),
              blurRadius: 8 * intensity,
              offset: const Offset(0, 2),
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.lato(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.specialElite(textStyle: base),
          particleShape: ParticleShape.organic,
          particleCount: 15,
          particleSpeed: 0.4,
          particleOpacity: 0.25,
          particleColors: const [Color(0xFFB58900), Color(0xFF2AA198), Color(0xFF859900)],
          connectLines: false,
        );

      // 6. Aero Glassmorphic
      case AppThemeType.glassmorphism:
        return AppThemeData(
          type: type,
          name: 'Aero Glassmorphic',
          background: const Color(0xFF030D2E), // Fundo profundo que transparecerá no Scaffold
          surface: const Color(0x1AFFFFFF), // Semi-transparente
          surfaceVariant: const Color(0x26FFFFFF),
          card: const Color(0x1FBDC2D6), // Efeito vidro fosco
          border: const Color(0x33FFFFFF), // Borda fina branca
          divider: const Color(0x1AFFFFFF),
          textPrimary: const Color(0xFFFFFFFF),
          textSecondary: const Color(0xFFB5C1D6),
          textMuted: const Color(0xFF6B7F9B),
          primary: const Color(0xFF00FFCC),
          primaryDim: const Color(0xFF00BFA9),
          secondary: const Color(0xFFFF007F),
          secondaryDim: const Color(0xFFB20059),
          accent: const Color(0xFF8A2BE2),
          accentDim: const Color(0xFF6A1B9A),
          taskStandard: const Color(0xFFD4E2F0),
          taskBlue: const Color(0xFF00FFCC),
          taskYellow: const Color(0xFFFFEB3B),
          taskRed: const Color(0xFFFF007F),
          cardStandard: const Color(0x1AFFFFFF),
          cardBlue: const Color(0x1500FFCC),
          cardYellow: const Color(0x15FFEB3B),
          cardRed: const Color(0x15FF007F),
          glowBlue: const Color(0x3300FFCC),
          glowYellow: const Color(0x33FFEB3B),
          glowRed: const Color(0x33FF007F),
          borderRadius: 16.0,
          borderWidth: 1.0,
          useGlowBorder: true,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: color.withValues(alpha: 0.3 * intensity),
              blurRadius: 10 * intensity,
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.outfit(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.shareTechMono(textStyle: base),
          particleShape: ParticleShape.bubble,
          particleCount: 18,
          particleSpeed: 0.6,
          particleOpacity: 0.28,
          particleColors: const [Color(0xFF00FFCC), Color(0xFFFF007F), Colors.white],
          connectLines: true,
        );

      // 7. Dracula Classic
      case AppThemeType.dracula:
        return AppThemeData(
          type: type,
          name: 'Dracula Classic',
          background: const Color(0xFF282A36),
          surface: const Color(0xFF1E1F29),
          surfaceVariant: const Color(0xFF343746),
          card: const Color(0xFF1E1F29),
          border: const Color(0xFFBD93F9).withValues(alpha: 0.3),
          divider: const Color(0xFF44475A),
          textPrimary: const Color(0xFFF8F8F2),
          textSecondary: const Color(0xFF6272A4),
          textMuted: const Color(0xFF44475A),
          primary: const Color(0xFFBD93F9),
          primaryDim: const Color(0xFF8C5DCA),
          secondary: const Color(0xFFFF79C6),
          secondaryDim: const Color(0xFFC74395),
          accent: const Color(0xFF50FA7B),
          accentDim: const Color(0xFF2BD859),
          taskStandard: const Color(0xFFF8F8F2),
          taskBlue: const Color(0xFF8BE9FD),
          taskYellow: const Color(0xFFF1FA8C),
          taskRed: const Color(0xFFFF5555),
          cardStandard: const Color(0xFF222430),
          cardBlue: const Color(0xFF182935),
          cardYellow: const Color(0xFF2F3222),
          cardRed: const Color(0xFF321A1A),
          glowBlue: const Color(0x408BE9FD),
          glowYellow: const Color(0x40F1FA8C),
          glowRed: const Color(0x40FF5555),
          borderRadius: 12.0,
          borderWidth: 1.0,
          useGlowBorder: true,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: color.withValues(alpha: 0.35 * intensity),
              blurRadius: 8 * intensity,
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.firaCode(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.firaCode(textStyle: base),
          particleShape: ParticleShape.cross,
          particleCount: 16,
          particleSpeed: 0.5,
          particleOpacity: 0.35,
          particleColors: const [Color(0xFFBD93F9), Color(0xFFFF79C6), Color(0xFF50FA7B)],
          connectLines: false,
        );

      // 8. Slate Monochrome
      case AppThemeType.monochrome:
        return AppThemeData(
          type: type,
          name: 'Slate Monochrome',
          background: const Color(0xFF000000),
          surface: const Color(0xFF121212),
          surfaceVariant: const Color(0xFF1E1E1E),
          card: const Color(0xFF121212),
          border: const Color(0xFFFFFFFF),
          divider: const Color(0xFF333333),
          textPrimary: const Color(0xFFFFFFFF),
          textSecondary: const Color(0xFF888888),
          textMuted: const Color(0xFF444444),
          primary: const Color(0xFFFFFFFF),
          primaryDim: const Color(0xFFCCCCCC),
          secondary: const Color(0xFF888888),
          secondaryDim: const Color(0xFF555555),
          accent: const Color(0xFFFFFFFF),
          accentDim: const Color(0xFFCCCCCC),
          taskStandard: const Color(0xFFEEEEEE),
          taskBlue: const Color(0xFFAAAAAA),
          taskYellow: const Color(0xFF888888),
          taskRed: const Color(0xFF555555),
          cardStandard: const Color(0xFF121212),
          cardBlue: const Color(0xFF171717),
          cardYellow: const Color(0xFF1B1B1B),
          cardRed: const Color(0xFF0E0E0E),
          glowBlue: const Color(0x33FFFFFF),
          glowYellow: const Color(0x33888888),
          glowRed: const Color(0x33444444),
          borderRadius: 0.0,
          borderWidth: 1.5,
          useGlowBorder: false,
          glowShadow: (color, {intensity = 1.0}) => [],
          fontStyleBase: (base) => GoogleFonts.robotoMono(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.robotoMono(textStyle: base),
          particleShape: ParticleShape.cross,
          particleCount: 15,
          particleSpeed: 0.7,
          particleOpacity: 0.25,
          particleColors: const [Color(0xFFFFFFFF), Color(0xFF888888)],
          connectLines: false,
        );

      // 9. Steampunk Brass
      case AppThemeType.steampunk:
        return AppThemeData(
          type: type,
          name: 'Steampunk Brass',
          background: const Color(0xFF110D0A),
          surface: const Color(0xFF1F1813),
          surfaceVariant: const Color(0xFF2C221A),
          card: const Color(0xFF1F1813),
          border: const Color(0xFF84623F),
          divider: const Color(0xFF382A1D),
          textPrimary: const Color(0xFFECCEB2),
          textSecondary: const Color(0xFFA58564),
          textMuted: const Color(0xFF6E533A),
          primary: const Color(0xFFD4AF37),
          primaryDim: const Color(0xFF9E7E1D),
          secondary: const Color(0xFFCD7F32),
          secondaryDim: const Color(0xFF92571B),
          accent: const Color(0xFF6B8E23),
          accentDim: const Color(0xFF466212),
          taskStandard: const Color(0xFFEAD1B6),
          taskBlue: const Color(0xFF4A90E2),
          taskYellow: const Color(0xFFD4AF37),
          taskRed: const Color(0xFFCD5C5C),
          cardStandard: const Color(0xFF221A14),
          cardBlue: const Color(0xFF122130),
          cardYellow: const Color(0xFF2B2211),
          cardRed: const Color(0xFF2A1515),
          glowBlue: const Color(0x404A90E2),
          glowYellow: const Color(0x40D4AF37),
          glowRed: const Color(0x40CD5C5C),
          borderRadius: 6.0,
          borderWidth: 1.0,
          useGlowBorder: true,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: color.withValues(alpha: 0.4 * intensity),
              blurRadius: 6 * intensity,
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.cinzel(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.shareTechMono(textStyle: base),
          particleShape: ParticleShape.ember,
          particleCount: 20,
          particleSpeed: 1.2,
          particleOpacity: 0.45,
          particleColors: const [Color(0xFFFE802B), Color(0xFFD4AF37), Color(0xFFFF3300)],
          connectLines: false,
        );

      // 10. Sakura Dream
      case AppThemeType.sakura:
        return AppThemeData(
          type: type,
          name: 'Sakura Dream',
          background: const Color(0xFF171324),
          surface: const Color(0xFF231B36),
          surfaceVariant: const Color(0xFF342850),
          card: const Color(0xFF231B36),
          border: const Color(0xFFFFB7C5).withValues(alpha: 0.4),
          divider: const Color(0xFF463567),
          textPrimary: const Color(0xFFFFF2F5),
          textSecondary: const Color(0xFFFFB7C5),
          textMuted: const Color(0xFF755E96),
          primary: const Color(0xFFFFB7C5),
          primaryDim: const Color(0xFFCF8BA0),
          secondary: const Color(0xFFD8B4F8),
          secondaryDim: const Color(0xFFA282BD),
          accent: const Color(0xFFA9F3FF),
          accentDim: const Color(0xFF76BDC7),
          taskStandard: const Color(0xFFEBD3FF),
          taskBlue: const Color(0xFF81D4FA),
          taskYellow: const Color(0xFFFFF59D),
          taskRed: const Color(0xFFFF8A80),
          cardStandard: const Color(0xFF2A2140),
          cardBlue: const Color(0xFF132A3B),
          cardYellow: const Color(0xFF332F23),
          cardRed: const Color(0xFF361E23),
          glowBlue: const Color(0x4081D4FA),
          glowYellow: const Color(0x40FFF59D),
          glowRed: const Color(0x40FF8A80),
          borderRadius: 20.0,
          borderWidth: 1.0,
          useGlowBorder: true,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: color.withValues(alpha: 0.3 * intensity),
              blurRadius: 10 * intensity,
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.quicksand(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.quicksand(textStyle: base),
          particleShape: ParticleShape.sakura,
          particleCount: 14,
          particleSpeed: 0.4,
          particleOpacity: 0.40,
          particleColors: const [Color(0xFFFFB7C5), Color(0xFFFFD1DC), Color(0xFFD8B4F8)],
          connectLines: false,
        );

      // 11. Ocean Breeze
      case AppThemeType.ocean:
        return AppThemeData(
          type: type,
          name: 'Ocean Breeze',
          background: const Color(0xFF051923),
          surface: const Color(0xFF0A3042),
          surfaceVariant: const Color(0xFF0F4863),
          card: const Color(0xFF0A3042),
          border: const Color(0xFF00A8E8).withValues(alpha: 0.5),
          divider: const Color(0xFF145677),
          textPrimary: const Color(0xFFE0F2FE),
          textSecondary: const Color(0xFF90E0EF),
          textMuted: const Color(0xFF38BDF8).withValues(alpha: 0.7),
          primary: const Color(0xFF00A8E8),
          primaryDim: const Color(0xFF007EA7),
          secondary: const Color(0xFF00F5D4),
          secondaryDim: const Color(0xFF00BFA5),
          accent: const Color(0xFF00F5D4),
          accentDim: const Color(0xFF00BFA5),
          taskStandard: const Color(0xFFE0F2FE),
          taskBlue: const Color(0xFF0284C7),
          taskYellow: const Color(0xFFFFCC00),
          taskRed: const Color(0xFFFF5C5C),
          cardStandard: const Color(0xFF0B364A),
          cardBlue: const Color(0xFF032238),
          cardYellow: const Color(0xFF282506),
          cardRed: const Color(0xFF2A1010),
          glowBlue: const Color(0x400284C7),
          glowYellow: const Color(0x40FFCC00),
          glowRed: const Color(0x40FF5C5C),
          borderRadius: 18.0,
          borderWidth: 1.0,
          useGlowBorder: true,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: color.withValues(alpha: 0.35 * intensity),
              blurRadius: 9 * intensity,
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.outfit(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.shareTechMono(textStyle: base),
          particleShape: ParticleShape.bubble,
          particleCount: 16,
          particleSpeed: 0.5,
          particleOpacity: 0.30,
          particleColors: const [Color(0xFF00A8E8), Color(0xFF00F5D4), Color(0xFFE0F2FE)],
          connectLines: false,
        );

      // 12. Garden Zen
      case AppThemeType.garden:
        return AppThemeData(
          type: type,
          name: 'Garden Zen',
          background: const Color(0xFF0B1B10),
          surface: const Color(0xFF163220),
          surfaceVariant: const Color(0xFF234C32),
          card: const Color(0xFF163220),
          border: const Color(0xFF4E9F3D).withValues(alpha: 0.4),
          divider: const Color(0xFF265737),
          textPrimary: const Color(0xFFF1F8F4),
          textSecondary: const Color(0xFF8ECA9F),
          textMuted: const Color(0xFF386B49),
          primary: const Color(0xFF4E9F3D),
          primaryDim: const Color(0xFF3E8230),
          secondary: const Color(0xFFE9C46A),
          secondaryDim: const Color(0xFFCCA74F),
          accent: const Color(0xFF1E88E5),
          accentDim: const Color(0xFF1565C0),
          taskStandard: const Color(0xFFE8F5E9),
          taskBlue: const Color(0xFF2E7D32),
          taskYellow: const Color(0xFFFBC02D),
          taskRed: const Color(0xFFD32F2F),
          cardStandard: const Color(0xFF183B25),
          cardBlue: const Color(0xFF09291D),
          cardYellow: const Color(0xFF2C2907),
          cardRed: const Color(0xFF2C0F10),
          glowBlue: const Color(0x402E7D32),
          glowYellow: const Color(0x40FBC02D),
          glowRed: const Color(0x40D32F2F),
          borderRadius: 14.0,
          borderWidth: 1.0,
          useGlowBorder: true,
          glowShadow: (color, {intensity = 1.0}) => [
            BoxShadow(
              color: color.withValues(alpha: 0.3 * intensity),
              blurRadius: 8 * intensity,
            ),
          ],
          fontStyleBase: (base) => GoogleFonts.nunito(textStyle: base),
          fontStyleMono: (base) => GoogleFonts.shareTechMono(textStyle: base),
          particleShape: ParticleShape.leaf,
          particleCount: 14,
          particleSpeed: 0.4,
          particleOpacity: 0.30,
          particleColors: const [Color(0xFF4E9F3D), Color(0xFF8ECA9F), Color(0xFFE9C46A), Color(0xFFB5E7A0)],
          connectLines: false,
        );
    }
  }

  bool get isDark => background.computeLuminance() < 0.5;

  AppThemeData toLight() {
    if (!isDark) return this;

    final hslBg = HSLColor.fromColor(background);
    final lightBg = hslBg.withLightness(0.95).toColor().withValues(alpha: background.a);
    final lightSurface = HSLColor.fromColor(surface).withLightness(0.98).toColor().withValues(alpha: surface.a);
    final lightSurfaceVariant = HSLColor.fromColor(surfaceVariant).withLightness(0.92).toColor().withValues(alpha: surfaceVariant.a);
    final lightCard = HSLColor.fromColor(card).withLightness(0.98).toColor().withValues(alpha: card.a);
    final lightBorder = HSLColor.fromColor(border.withValues(alpha: 1.0)).withLightness(0.85).toColor().withValues(alpha: border.a);
    final lightDivider = HSLColor.fromColor(divider.withValues(alpha: 1.0)).withLightness(0.90).toColor().withValues(alpha: divider.a);

    final lightTextPrimary = HSLColor.fromColor(textPrimary).withLightness(0.12).toColor();
    final lightTextSecondary = HSLColor.fromColor(textSecondary).withLightness(0.35).toColor();
    final lightTextMuted = HSLColor.fromColor(textMuted).withLightness(0.55).toColor();

    final lightTaskBlue = HSLColor.fromColor(taskBlue).withLightness(0.40).toColor();
    final lightTaskYellow = HSLColor.fromColor(taskYellow).withLightness(0.40).toColor();
    final lightTaskRed = HSLColor.fromColor(taskRed).withLightness(0.40).toColor();

    return copyWith(
      background: lightBg,
      surface: lightSurface,
      surfaceVariant: lightSurfaceVariant,
      card: lightCard,
      border: lightBorder,
      divider: lightDivider,
      textPrimary: lightTextPrimary,
      textSecondary: lightTextSecondary,
      textMuted: lightTextMuted,
      taskStandard: lightTextPrimary,
      taskBlue: lightTaskBlue,
      taskYellow: lightTaskYellow,
      taskRed: lightTaskRed,
      cardStandard: lightCard,
      cardBlue: lightTaskBlue.withValues(alpha: 0.08),
      cardYellow: lightTaskYellow.withValues(alpha: 0.08),
      cardRed: lightTaskRed.withValues(alpha: 0.08),
      glowBlue: lightTaskBlue.withValues(alpha: 0.15),
      glowYellow: lightTaskYellow.withValues(alpha: 0.15),
      glowRed: lightTaskRed.withValues(alpha: 0.15),
      particleOpacity: (particleOpacity * 0.4).clamp(0.05, 0.15),
      useGlowBorder: false,
    );
  }

  AppThemeData toDark() {
    if (isDark) return this;

    final hslBg = HSLColor.fromColor(background);
    final darkBg = hslBg.withLightness(0.06).toColor().withValues(alpha: background.a);
    final darkSurface = HSLColor.fromColor(surface).withLightness(0.12).toColor().withValues(alpha: surface.a);
    final darkSurfaceVariant = HSLColor.fromColor(surfaceVariant).withLightness(0.18).toColor().withValues(alpha: surfaceVariant.a);
    final darkCard = HSLColor.fromColor(card).withLightness(0.10).toColor().withValues(alpha: card.a);
    final darkBorder = HSLColor.fromColor(border.withValues(alpha: 1.0)).withLightness(0.25).toColor().withValues(alpha: border.a);
    final darkDivider = HSLColor.fromColor(divider.withValues(alpha: 1.0)).withLightness(0.20).toColor().withValues(alpha: divider.a);

    final darkTextPrimary = HSLColor.fromColor(textPrimary).withLightness(0.92).toColor();
    final darkTextSecondary = HSLColor.fromColor(textSecondary).withLightness(0.65).toColor();
    final darkTextMuted = HSLColor.fromColor(textMuted).withLightness(0.40).toColor();

    final darkTaskBlue = HSLColor.fromColor(taskBlue).withLightness(0.60).toColor();
    final darkTaskYellow = HSLColor.fromColor(taskYellow).withLightness(0.60).toColor();
    final darkTaskRed = HSLColor.fromColor(taskRed).withLightness(0.60).toColor();

    return copyWith(
      background: darkBg,
      surface: darkSurface,
      surfaceVariant: darkSurfaceVariant,
      card: darkCard,
      border: darkBorder,
      divider: darkDivider,
      textPrimary: darkTextPrimary,
      textSecondary: darkTextSecondary,
      textMuted: darkTextMuted,
      taskStandard: darkTextPrimary,
      taskBlue: darkTaskBlue,
      taskYellow: darkTaskYellow,
      taskRed: darkTaskRed,
      cardStandard: darkCard,
      cardBlue: darkTaskBlue.withValues(alpha: 0.08),
      cardYellow: darkTaskYellow.withValues(alpha: 0.08),
      cardRed: darkTaskRed.withValues(alpha: 0.08),
      glowBlue: darkTaskBlue.withValues(alpha: 0.35),
      glowYellow: darkTaskYellow.withValues(alpha: 0.35),
      glowRed: darkTaskRed.withValues(alpha: 0.35),
      particleOpacity: (particleOpacity * 2.5).clamp(0.15, 0.45),
      useGlowBorder: true,
    );
  }

  AppThemeData copyWith({
    AppThemeType? type,
    String? name,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? card,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? primaryDim,
    Color? secondary,
    Color? secondaryDim,
    Color? accent,
    Color? accentDim,
    Color? taskStandard,
    Color? taskBlue,
    Color? taskYellow,
    Color? taskRed,
    Color? cardStandard,
    Color? cardBlue,
    Color? cardYellow,
    Color? cardRed,
    Color? glowBlue,
    Color? glowYellow,
    Color? glowRed,
    double? borderRadius,
    double? borderWidth,
    bool? useGlowBorder,
    List<BoxShadow> Function(Color color, {double intensity})? glowShadow,
    TextStyle Function(TextStyle base)? fontStyleBase,
    TextStyle Function(TextStyle base)? fontStyleMono,
    ParticleShape? particleShape,
    int? particleCount,
    double? particleSpeed,
    double? particleOpacity,
    List<Color>? particleColors,
    bool? connectLines,
  }) {
    return AppThemeData(
      type: type ?? this.type,
      name: name ?? this.name,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      card: card ?? this.card,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryDim: primaryDim ?? this.primaryDim,
      secondary: secondary ?? this.secondary,
      secondaryDim: secondaryDim ?? this.secondaryDim,
      accent: accent ?? this.accent,
      accentDim: accentDim ?? this.accentDim,
      taskStandard: taskStandard ?? this.taskStandard,
      taskBlue: taskBlue ?? this.taskBlue,
      taskYellow: taskYellow ?? this.taskYellow,
      taskRed: taskRed ?? this.taskRed,
      cardStandard: cardStandard ?? this.cardStandard,
      cardBlue: cardBlue ?? this.cardBlue,
      cardYellow: cardYellow ?? this.cardYellow,
      cardRed: cardRed ?? this.cardRed,
      glowBlue: glowBlue ?? this.glowBlue,
      glowYellow: glowYellow ?? this.glowYellow,
      glowRed: glowRed ?? this.glowRed,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      useGlowBorder: useGlowBorder ?? this.useGlowBorder,
      glowShadow: glowShadow ?? this.glowShadow,
      fontStyleBase: fontStyleBase ?? this.fontStyleBase,
      fontStyleMono: fontStyleMono ?? this.fontStyleMono,
      particleShape: particleShape ?? this.particleShape,
      particleCount: particleCount ?? this.particleCount,
      particleSpeed: particleSpeed ?? this.particleSpeed,
      particleOpacity: particleOpacity ?? this.particleOpacity,
      particleColors: particleColors ?? this.particleColors,
      connectLines: connectLines ?? this.connectLines,
    );
  }
}
