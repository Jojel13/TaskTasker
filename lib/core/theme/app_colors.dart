import 'package:flutter/material.dart';

/// Paleta de cores do tema Cyberpunk Dark
class AppColors {
  AppColors._();

  // ─── Backgrounds ──────────────────────────────────────────────
  static const Color background     = Color(0xFF070B14);
  static const Color surface        = Color(0xFF0D1220);
  static const Color surfaceVariant = Color(0xFF131929);
  static const Color card           = Color(0xFF111827);

  // ─── Neon Primary — Ciano ─────────────────────────────────────
  static const Color primary    = Color(0xFF00F5FF);
  static const Color primaryDim = Color(0xFF00BFCC);

  // ─── Neon Secondary — Roxo ────────────────────────────────────
  static const Color secondary    = Color(0xFFB44FFF);
  static const Color secondaryDim = Color(0xFF8B2FCC);

  // ─── Neon Accent — Rosa ───────────────────────────────────────
  static const Color accent = Color(0xFFFF2D9B);

  // ─── Cores das Tasks ──────────────────────────────────────────
  static const Color taskStandard = Color(0xFFBBC4D4);
  static const Color taskBlue     = Color(0xFF3D9EFF);
  static const Color taskYellow   = Color(0xFFFFD60A);
  static const Color taskRed      = Color(0xFFFF3B4E);

  // ─── Glow (semi-transparente para BoxShadow) ──────────────────
  static const Color glowCyan   = Color(0x6600F5FF);
  static const Color glowPurple = Color(0x66B44FFF);
  static const Color glowBlue   = Color(0x663D9EFF);
  static const Color glowYellow = Color(0x66FFD60A);
  static const Color glowRed    = Color(0x66FF3B4E);
  static const Color glowPink   = Color(0x66FF2D9B);

  // ─── Texto ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFE8EEFF);
  static const Color textSecondary = Color(0xFF8899BB);
  static const Color textMuted     = Color(0xFF445577);

  // ─── UI Elements ──────────────────────────────────────────────
  static const Color border  = Color(0xFF1E2D4A);
  static const Color divider = Color(0xFF0F1A2E);

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

  /// Retorna o glow correspondente à cor da task
  static Color glowFromTaskColor(String colorName) {
    switch (colorName) {
      case 'TaskColor.blue':   return glowBlue;
      case 'TaskColor.yellow': return glowYellow;
      case 'TaskColor.red':    return glowRed;
      default:                 return glowCyan;
    }
  }

  /// Gera BoxShadow com efeito neon/glow
  static List<BoxShadow> glowShadow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.55 * intensity),
        blurRadius: 12 * intensity,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.25 * intensity),
        blurRadius: 28 * intensity,
        spreadRadius: 0,
      ),
    ];
  }
}
