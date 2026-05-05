import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../database/isar_service.dart';
import '../services/routine_service.dart';
import '../services/xp_service.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/user_profile.dart';

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
