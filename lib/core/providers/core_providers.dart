import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../database/isar_service.dart';
import '../services/routine_service.dart';
import '../services/xp_service.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/task.dart';
import '../../shared/models/enums.dart';

// ── Core ─────────────────────────────────────────────────────────────────────
final isarProvider = Provider<Isar>((ref) => IsarService.instance);

final routineServiceProvider = Provider<RoutineService>(
  (ref) => RoutineService(ref.watch(isarProvider)),
);

final xpServiceProvider = Provider<XpService>(
  (ref) => XpService(ref.watch(isarProvider)),
);

// ── Routines ─────────────────────────────────────────────────────────────────
final allRoutinesProvider = StreamProvider<List<Routine>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.routines.where().sortByDateDesc().watch(fireImmediately: true);
});

final todayRoutineProvider = StreamProvider<Routine?>((ref) async* {
  final isar = ref.watch(isarProvider);
  final n = DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  
  await for (final _ in isar.routines.watchLazy(fireImmediately: true)) {
    final routine = await isar.routines
        .filter()
        .dateBetween(today, today.add(const Duration(hours: 23, minutes: 59)))
        .findFirst();
    yield routine;
  }
});

// ── Routine Days ──────────────────────────────────────────────────────────────
final routineDaysProvider = FutureProvider.family<List<RoutineDay>, Id>((
  ref,
  routineId,
) async {
  final isar = ref.watch(isarProvider);
  final routine = await isar.routines.get(routineId);
  if (routine == null) return [];
  return ref.watch(routineServiceProvider).loadDays(routine);
});

// ── User Profile ──────────────────────────────────────────────────────────────
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.userProfiles.watchObject(1, fireImmediately: true);
});

// ── Radar ────────────────────────────────────────────────────────────────────
final radarProvider = StreamProvider<List<Task>>((ref) async* {
  final isar = ref.watch(isarProvider);

  await for (final _ in isar.tasks.watchLazy(fireImmediately: true)) {
    final allActive = await isar.tasks
        .filter()
        .statusEqualTo(TaskStatus.active)
        .and()
        .group((q) => q.colorEqualTo(TaskColor.red).or().colorEqualTo(TaskColor.yellow))
        .sortByCreatedAtDesc()
        .findAll();

    final latestRoutine = await isar.routines.where().sortByDateDesc().findFirst();
    final todayTaskIds = <int>{};

    if (latestRoutine != null) {
      final now = DateTime.now();
      final isToday = latestRoutine.date.year == now.year &&
          latestRoutine.date.month == now.month &&
          latestRoutine.date.day == now.day;

      if (isToday) {
        await latestRoutine.days.load();
        for (final day in latestRoutine.days) {
          // Removemos do radar as tasks que já estão nas divisões de hoje (exceto Para Amanhã)
          if (day.division != DivisionType.tomorrow) {
            await day.tasks.load();
            todayTaskIds.addAll(day.tasks.map((t) => t.id));
          }
        }
      }
    }

    final filtered = allActive.where((t) => !todayTaskIds.contains(t.id)).toList();

    final uniqueTasks = <int, Task>{};
    for (final t in filtered) {
      if (!uniqueTasks.containsKey(t.id)) {
        uniqueTasks[t.id] = t;
      }
    }

    yield uniqueTasks.values.toList();
  }
});

// ── Dashboard Heatmap ────────────────────────────────────────────────────────
final heatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final isar = ref.watch(isarProvider);
  
  // Limitar histórico para os últimos 180 dias para performance
  final now = DateTime.now();
  final limitDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 180));
  
  final routines = await isar.routines.filter().dateGreaterThan(limitDate).findAll();
  Map<DateTime, int> dataset = {};

  for (final r in routines) {
    await r.days.load();
    int completed = 0;
    int total = 0;
    for (final day in r.days) {
      await day.tasks.load();
      for (final t in day.tasks) {
        total++;
        if (t.status == TaskStatus.completed) completed++;
      }
    }

    if (total > 0) {
      final percentage = completed / total;
      int weight = 1;
      if (percentage >= 1.0) {
        weight = 4;
      } else if (percentage >= 0.75) {
        weight = 3;
      } else if (percentage >= 0.5) {
        weight = 2;
      }
      
      final date = DateTime(r.date.year, r.date.month, r.date.day);
      // Se já houver rotina neste dia, mantém a que teve mais tasks (ou funde)
      // Aqui vamos manter o maior peso
      if (!dataset.containsKey(date) || weight > dataset[date]!) {
        dataset[date] = weight;
      }
    }
  }
  return dataset;
});
