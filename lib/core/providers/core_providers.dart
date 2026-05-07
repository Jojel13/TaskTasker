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

final todayRoutineProvider = FutureProvider<Routine?>((ref) {
  return ref.watch(routineServiceProvider).findTodayRoutine();
});

// ── Routine Days ──────────────────────────────────────────────────────────────
final routineDaysProvider =
    FutureProvider.family<List<RoutineDay>, Id>((ref, routineId) async {
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
final radarProvider = StreamProvider<List<Task>>((ref) {
  final isar = ref.watch(isarProvider);
  return isar.tasks
      .filter()
      .statusEqualTo(TaskStatus.active)
      .and()
      .group((q) => q.colorEqualTo(TaskColor.red).or().colorEqualTo(TaskColor.yellow))
      .watch(fireImmediately: true);
});

// ── Dashboard Heatmap ────────────────────────────────────────────────────────
final heatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final isar = ref.watch(isarProvider);
  final routines = await isar.routines.where().findAll();
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
      if (percentage >= 1.0) weight = 4;
      else if (percentage >= 0.75) weight = 3;
      else if (percentage >= 0.5) weight = 2;
      dataset[DateTime(r.date.year, r.date.month, r.date.day)] = weight;
    }
  }
  return dataset;
});
