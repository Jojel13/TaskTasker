import 'package:flutter/foundation.dart' show debugPrint;
import 'package:isar/isar.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/task.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/enums.dart';
import '../utils/habit_id.dart';

/// Migrações de dados versionadas pelo campo [UserProfile.schemaVersion].
///
/// Todas as etapas são idempotentes: podem rodar novamente (ex.: após importar
/// um backup antigo) sem duplicar ou corromper dados.
class MigrationService {
  MigrationService._();

  static const int currentSchemaVersion = 2;

  static Future<void> run(Isar isar) async {
    final profile = await isar.userProfiles.get(1);
    if (profile == null) return;
    if (profile.schemaVersion >= currentSchemaVersion) return;

    try {
      if (profile.schemaVersion < 2) {
        await _migrateToV2(isar);
      }

      profile.schemaVersion = currentSchemaVersion;
      await isar.writeTxn(() => isar.userProfiles.put(profile));
    } catch (e) {
      // Não bloqueia a abertura do app; tenta novamente no próximo boot.
      debugPrint('MigrationService error: $e');
    }
  }

  /// v2: identidade de hábitos azuis (habitId/cadenceAnchor) e limpeza das
  /// cópias de tasks de fim de semana que se duplicavam a cada sábado.
  static Future<void> _migrateToV2(Isar isar) async {
    // ── 1. habitId para tasks azuis existentes ────────────────────
    final blues = await isar.tasks.filter().colorEqualTo(TaskColor.blue).findAll();
    final groups = <String, List<Task>>{};
    for (final t in blues) {
      groups.putIfAbsent(t.text.trim().toLowerCase(), () => []).add(t);
    }

    final toPut = <Task>[];
    for (final group in groups.values) {
      group.sort((a, b) => a.id.compareTo(b.id));
      final existingId = group
          .map((t) => t.habitId)
          .firstWhere((h) => h != null, orElse: () => null);
      final habitId = existingId ?? HabitIdGenerator.generate();
      final latest = group.last;
      final anchor = latest.cadenceAnchor ??
          DateTime(latest.createdAt.year, latest.createdAt.month, latest.createdAt.day);

      for (final t in group) {
        bool changed = false;
        if (t.habitId == null) {
          t.habitId = habitId;
          changed = true;
        }
        if (t.cadenceAnchor == null) {
          t.cadenceAnchor = anchor;
          changed = true;
        }
        if (changed) toPut.add(t);
      }
    }

    // ── 2. Cópias de fim de semana (vinculadas a uma rotina) ──────
    final linkedIds = <int>{};
    final allDays = await isar.routineDays.where().findAll();
    for (final d in allDays) {
      await d.tasks.load();
      linkedIds.addAll(d.tasks.map((t) => t.id));
    }

    final weekend = await isar.tasks
        .filter()
        .isWeekendTaskEqualTo(true)
        .weekendOriginIdIsNull()
        .findAll();
    final originals = weekend.where((t) => !linkedIds.contains(t.id)).toList();
    final originalByText = <String, Task>{
      for (final o in originals) o.text.trim().toLowerCase(): o,
    };

    for (final t in weekend) {
      if (!linkedIds.contains(t.id)) continue; // é original (vive solto)
      final origin = originalByText[t.text.trim().toLowerCase()];
      t.weekendOriginId = origin?.id ?? t.id;
      toPut.add(t);
    }

    if (toPut.isNotEmpty) {
      await isar.writeTxn(() => isar.tasks.putAll(toPut));
    }
    debugPrint('MigrationService v2: ${toPut.length} tasks atualizadas.');
  }
}
