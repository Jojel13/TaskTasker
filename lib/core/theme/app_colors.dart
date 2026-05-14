import 'package:flutter/material.dart';

/// Paleta de cores — TaskTasker
/// Estética Peak: dark mode puro, cores vivas e suaves, glow + alto contraste.
class AppColors {
  AppColors._();

  // ─── Backgrounds ──────────────────────────────────────────────
  static const Color background     = Color(0xFF080808); // Preto puro (Peak)
  static const Color surface        = Color(0xFF111111); // Superfície elevada
  static const Color surfaceVariant = Color(0xFF1A1A1A); // Cards secundários
  static const Color card           = Color(0xFF0F0F0F); // Card base

  // ─── Primária — Branco/Gelo (UI principal) ────────────────────
  static const Color primary    = Color(0xFFF0F0F0);
  static const Color primaryDim = Color(0xFF8A8A8A);

  // ─── Secundária — Azul Elétrico (divisões, links) ─────────────
  static const Color secondary    = Color(0xFF4A9EFF);
  static const Color secondaryDim = Color(0xFF2D6FCC);

  // ─── Accent — Verde Menta (streak, confirmações) ──────────────
  static const Color accent    = Color(0xFF39D98A);
  static const Color accentDim = Color(0xFF1FAD63);

  // ─── Cores das Tasks ──────────────────────────────────────────
  static const Color taskStandard = Color(0xFFD0D0D0); // Branco suave
  static const Color taskBlue     = Color(0xFF4A9EFF); // Azul elétrico
  static const Color taskYellow   = Color(0xFFFFCC00); // Amarelo ouro
  static const Color taskRed      = Color(0xFFFF4D4D); // Vermelho coral
  static const Color taskGreen    = Color(0xFF39D98A); // Verde menta

  // ─── Glow (semi-transparente para BoxShadow) ──────────────────
  static const Color glowWhite  = Color(0x40F0F0F0);
  static const Color glowBlue   = Color(0x664A9EFF);
  static const Color glowYellow = Color(0x66FFCC00);
  static const Color glowRed    = Color(0x66FF4D4D);
  static const Color glowGreen  = Color(0x6639D98A);

  // ─── Texto ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted     = Color(0xFF3D3D3D);

  // ─── UI Elements ──────────────────────────────────────────────
  static const Color border  = Color(0xFF222222);
  static const Color divider = Color(0xFF181818);

  // ─── Helpers ──────────────────────────────────────────────────

  /// Retorna a cor Flutter correspondente à cor da task
  static Color fromTaskColor(String colorName) {
    switch (colorName) {
      case 'TaskColor.blue':   return taskBlue;
      case 'TaskColor.yellow': return taskYellow;
      case 'TaskColor.red':    return taskRed;
      default:                 return taskStandard;
    }
  }

  /// Gera BoxShadow com efeito neon/glow suave
  static List<BoxShadow> glowShadow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.45 * intensity),
        blurRadius: 10 * intensity,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.18 * intensity),
        blurRadius: 24 * intensity,
        spreadRadius: 2,
      ),
    ];
  }

  /// Glow duplo intenso (botões hero, elementos de destaque)
  static List<BoxShadow> glowShadowIntense(Color color) {
    return [
      BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 0),
      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4),
      BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 40, spreadRadius: 8),
    ];
  }
}
