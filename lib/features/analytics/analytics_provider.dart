import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../core/providers/core_providers.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/enums.dart';

class DailyStats {
  final DateTime date;
  final int completed;
  final int failed;

  DailyStats({required this.date, required this.completed, required this.failed});
}

class AnalyticsData {
  final int totalTasksCompleted;
  final int totalTasksFailed;
  final Map<TaskColor, int> tasksByColor;
  final int streakDays;
  final List<DailyStats> dailyStats;

  AnalyticsData({
    required this.totalTasksCompleted,
    required this.totalTasksFailed,
    required this.tasksByColor,
    required this.streakDays,
    required this.dailyStats,
  });
}

final analyticsProvider = FutureProvider.autoDispose<AnalyticsData>((ref) async {
  final isar = ref.watch(isarProvider);
  
  // Obter perfil para o Streak
  final profile = await isar.userProfiles.get(1);
  final streak = profile?.streakDays ?? 0;

  // Buscar todas as rotinas para os últimos 7 dias
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  
  final recentRoutines = await isar.routines.filter()
      .dateGreaterThan(sevenDaysAgo)
      .sortByDateDesc()
      .findAll();

  int totalCompleted = 0;
  int totalFailed = 0;
  Map<TaskColor, int> byColor = {
    TaskColor.red: 0,
    TaskColor.yellow: 0,
    TaskColor.blue: 0,
    TaskColor.standard: 0,
  };
  
  List<DailyStats> dailyStats = [];

  for (final routine in recentRoutines) {
    await routine.days.load();
    int dayCompleted = 0;
    int dayFailed = 0;

    for (final day in routine.days) {
      await day.tasks.load();
      for (final t in day.tasks) {
        if (t.status == TaskStatus.completed) {
          dayCompleted++;
          totalCompleted++;
          byColor[t.color] = (byColor[t.color] ?? 0) + 1;
        } else if (t.status == TaskStatus.active || t.status == TaskStatus.scheduled) {
          // Se a data já passou e não foi completada, consideramos como falha ou não-feita
          if (routine.date.isBefore(DateTime(now.year, now.month, now.day))) {
            dayFailed++;
            totalFailed++;
          }
        }
      }
    }
    
    dailyStats.add(DailyStats(
      date: routine.date,
      completed: dayCompleted,
      failed: dayFailed,
    ));
  }

  return AnalyticsData(
    totalTasksCompleted: totalCompleted,
    totalTasksFailed: totalFailed,
    tasksByColor: byColor,
    streakDays: streak,
    dailyStats: dailyStats,
  );
});
