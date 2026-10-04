import 'dart:math';

/// Gera identificadores únicos para hábitos azuis (sem dependência externa).
/// Formato: `<microsegundos base36>-<aleatório base36>`.
class HabitIdGenerator {
  HabitIdGenerator._();

  static final Random _rng = Random.secure();

  static String generate() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rnd = _rng.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$ts-$rnd';
  }
}
