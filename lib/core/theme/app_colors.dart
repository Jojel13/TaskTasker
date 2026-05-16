import 'package:flutter/material.dart';

/// Paleta de cores — TaskTasker
/// Estética Peak-Cyberpunk: dark mode, azul elétrico como identidade principal.
class AppColors {
  AppColors._();

  // ─── Backgrounds ──────────────────────────────────────────────
  static const Color background     = Color(0xFF080808);
  static const Color surface        = Color(0xFF111111);
  static const Color surfaceVariant = Color(0xFF1A1A1A);
  static const Color card           = Color(0xFF0F0F0F);

  // ─── Primária — Azul Elétrico (cara do app) ───────────────────
  static const Color primary    = Color(0xFF4A9EFF); // Azul elétrico vivo
  static const Color primaryDim = Color(0xFF2D6FCC); // Azul escurecido

  // ─── Secundária — Roxo (accent, destaque) ─────────────────────
  static const Color secondary    = Color(0xFF9B6DFF); // Roxo suave
  static const Color secondaryDim = Color(0xFF6B40CC); // Roxo escurecido

  // ─── Accent — Verde Menta (streak, sucesso) ───────────────────
  static const Color accent    = Color(0xFF39D98A); // Verde menta
  static const Color accentDim = Color(0xFF1FAD63);

  // ─── Cores das Tasks ──────────────────────────────────────────
  static const Color taskStandard = Color(0xFFD0D0D0); // Branco suave
  static const Color taskBlue     = Color(0xFF4A9EFF); // Azul elétrico
  static const Color taskYellow   = Color(0xFFFFCC00); // Amarelo ouro
  static const Color taskRed      = Color(0xFFFF4D4D); // Vermelho coral
  static const Color taskGreen    = Color(0xFF39D98A); // Verde menta

  // ─── Fundos dos cards por cor de task ─────────────────────────
  static const Color cardStandard = Color(0xFF111111);
  static const Color cardBlue     = Color(0xFF081428); // Azul muito escuro
  static const Color cardYellow   = Color(0xFF1C1400); // Âmbar muito escuro
  static const Color cardRed      = Color(0xFF1C0505); // Vermelho muito escuro

  // ─── Glow (semi-transparente) ─────────────────────────────────
  static const Color glowBlue   = Color(0x664A9EFF);
  static const Color glowYellow = Color(0x66FFCC00);
  static const Color glowRed    = Color(0x66FF4D4D);
  static const Color glowGreen  = Color(0x6639D98A);
  static const Color glowPurple = Color(0x669B6DFF);

  // ─── Texto ────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F0F0); // Branco gelo (texto)
  static const Color textSecondary = Color(0xFF8A8A8A); // Cinza médio
  static const Color textMuted     = Color(0xFF3D3D3D); // Cinza escuro

  // ─── UI Elements ──────────────────────────────────────────────
  static const Color border  = Color(0xFF222222);
  static const Color divider = Color(0xFF181818);

  // ─── Helpers ──────────────────────────────────────────────────

  /// Cor de fundo do card baseada na cor da task
  static Color cardBgFromTaskColor(TaskColorType color) => switch (color) {
    TaskColorType.standard => cardStandard,
    TaskColorType.blue     => cardBlue,
    TaskColorType.yellow   => cardYellow,
    TaskColorType.red      => cardRed,
  };

  /// Cor do dot/badge da task
  static Color fromTaskColorType(TaskColorType color) => switch (color) {
    TaskColorType.standard => taskStandard,
    TaskColorType.blue     => taskBlue,
    TaskColorType.yellow   => taskYellow,
    TaskColorType.red      => taskRed,
  };

  /// Cor de borda do card baseada na cor da task
  static Color cardBorderFromTaskColor(TaskColorType color, {bool isDone = false}) {
    if (isDone) return const Color(0xFF1E1E1E);
    return switch (color) {
      TaskColorType.standard => const Color(0xFF2A2A2A),
      TaskColorType.blue     => const Color(0xFF4A9EFF),
      TaskColorType.yellow   => const Color(0xFFFFCC00),
      TaskColorType.red      => const Color(0xFFFF4D4D),
    }.withValues(alpha: 0.35);
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

  /// Glow duplo intenso (botões hero)
  static List<BoxShadow> glowShadowIntense(Color color) {
    return [
      BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 0),
      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4),
      BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 40, spreadRadius: 8),
    ];
  }
}

/// Enum auxiliar para acesso às cores de task sem depender do modelo ISAR
enum TaskColorType { standard, blue, yellow, red }
