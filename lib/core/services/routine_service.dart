import 'package:isar/isar.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/task.dart';
import '../../shared/models/subtask.dart';
import '../../shared/models/mini_task.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/enums.dart';
import 'xp_service.dart';
import 'image_service.dart';

class RoutineService {
  final Isar _isar;
  final XpService _xp;

  RoutineService(this._isar) : _xp = XpService(_isar);

  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _divisionName(DivisionType d, UserProfile p) => switch (d) {
    DivisionType.morning   => p.divisionMorningName,
    DivisionType.afternoon => p.divisionAfternoonName,
    DivisionType.night     => p.divisionNightName,
    DivisionType.tomorrow  => p.divisionTomorrowName,
  };

  // ── Queries ──────────────────────────────────────────────────
  Future<Routine?> findTodayRoutine() async {
    final today = _today();
    return _isar.routines
        .where()
        .filter()
        .dateBetween(today, today.add(const Duration(hours: 23, minutes: 59)))
        .findFirst();
  }

  Future<Routine?> _lastRoutine() async =>
      _isar.routines.where().sortByDateDesc().findFirst();

  Future<List<Routine>> allRoutines() =>
      _isar.routines.where().sortByDateDesc().findAll();

  Future<List<RoutineDay>> loadDays(Routine routine) async {
    await routine.days.load();
    final days = routine.days.toList()
      ..sort((a, b) => a.division.index.compareTo(b.division.index));
    for (final d in days) {
      await d.tasks.load();
    }
    return days;
  }

  // ── Criar rotina ─────────────────────────────────────────────
  Future<Routine> createRoutine() async {
    final existing = await findTodayRoutine();
    if (existing != null) return existing;

    final profile = await _isar.userProfiles.get(1) ?? UserProfile();
    final lastRoutine = await _lastRoutine();

    // Coletar dados fora da transaction (reads)
    Map<DivisionType, List<Task>> propagate = {};
    List<Task> tomorrowTasks = [];

    if (lastRoutine != null) {
      await lastRoutine.days.load();
      final today = _today();
      for (final day in lastRoutine.days) {
        await day.tasks.load();
        final tasks = day.tasks.toList();
        final eligible = <Task>[];
        for (final t in tasks) {
          if (t.color == TaskColor.red) {
            final sched = t.scheduledDate;
            if (sched == null || sched.isBefore(today)) continue; // expired → skip
            eligible.add(t);
          } else if (t.color == TaskColor.blue) {
            if (_blueEligible(t, today)) eligible.add(t);
          } else if (t.color == TaskColor.yellow) {
            if (t.completedOnDate == null) eligible.add(t);
          }
          // standard: never propagates
        }
        if (day.division == DivisionType.tomorrow) {
          tomorrowTasks = eligible;
        } else {
          propagate[day.division] = eligible;
        }
      }
    }

    final today = _today();

    return await _isar.writeTxn(() async {
      final routine = Routine()
        ..name = profile.routineName
        ..date = today
        ..createdAt = DateTime.now();
      await _isar.routines.put(routine);

      for (final division in DivisionType.values) {
        final day = RoutineDay()
          ..division = division
          ..customName = _divisionName(division, profile);
        await _isar.routineDays.put(day);

        final tasks = division == DivisionType.morning
            ? [...(propagate[division] ?? []), ...tomorrowTasks]
            : (propagate[division] ?? []);

        for (final src in tasks) {
          final copy = _copyTask(src, division == DivisionType.morning && tomorrowTasks.contains(src)
              ? TaskColor.values[src.color.index] : src.color);
          await _isar.tasks.put(copy);
          day.tasks.add(copy);
        }
        await day.tasks.save();
        routine.days.add(day);
      }
      await routine.days.save();

      // Streak
      final updatedProfile = await _isar.userProfiles.get(1) ?? UserProfile();
      final last = updatedProfile.lastRoutineDate;
      final yesterday = today.subtract(const Duration(days: 1));
      if (last != null && DateTime(last.year, last.month, last.day) == yesterday) {
        updatedProfile.streakDays += 1;
      } else {
        updatedProfile.streakDays = 1;
      }
      if (updatedProfile.streakDays > updatedProfile.streakRecord) {
        updatedProfile.streakRecord = updatedProfile.streakDays;
      }
      updatedProfile.lastRoutineDate = today;
      await _isar.userProfiles.put(updatedProfile);

      await _xp.checkStreakBonus(updatedProfile);
      return routine;
    });
  }

  // ── Task CRUD ────────────────────────────────────────────────
  Future<Task> addTask(Id dayId, String text) async {
    return await _isar.writeTxn(() async {
      final day = await _isar.routineDays.get(dayId);
      if (day == null) throw Exception('Day not found');
      final task = Task()
        ..text = text
        ..createdAt = DateTime.now()
        ..color = TaskColor.standard
        ..status = TaskStatus.active;
      await _isar.tasks.put(task);
      await day.tasks.load();
      day.tasks.add(task);
      await day.tasks.save();
      return task;
    });
  }

  Future<void> deleteTask(Id dayId, Id taskId) async {
    await _isar.writeTxn(() async {
      final day = await _isar.routineDays.get(dayId);
      if (day != null) {
        await day.tasks.load();
        day.tasks.removeWhere((t) => t.id == taskId);
        await day.tasks.save();
      }
      final task = await _isar.tasks.get(taskId);
      if (task != null && task.imageFileName != null) {
         await ImageService.deleteImage(task.imageFileName!);
      }
      await _isar.tasks.delete(taskId);
    });
  }

  Future<void> moveTaskToDay(Id taskId, Id newDayId) async {
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task == null) return;
      
      final oldDay = await _isar.routineDays.filter().tasks((q) => q.idEqualTo(taskId)).findFirst();
      if (oldDay != null) {
        if (oldDay.id == newDayId) return; // Same day, no move
        await oldDay.tasks.load();
        oldDay.tasks.remove(task);
        await oldDay.tasks.save();
      }
      
      final newDay = await _isar.routineDays.get(newDayId);
      if (newDay != null) {
        await newDay.tasks.load();
        newDay.tasks.add(task);
        await newDay.tasks.save();
      }
    });
  }

  Future<void> toggleTask(Task task) async {
    final nowCompleted = task.status != TaskStatus.completed;
    task.status = nowCompleted ? TaskStatus.completed : TaskStatus.active;
    task.completedOnDate = nowCompleted ? DateTime.now() : null;
    await _isar.writeTxn(() => _isar.tasks.put(task));
    final desc = '${nowCompleted ? "Task" : "Desmarco task"} (${task.color.name})';
    final xp = XpService.xpForAction(task.color);
    if (nowCompleted) {
      await _xp.addXp(xp, desc);
    } else {
      await _xp.deductXp(xp, desc);
    }
  }

  Future<void> cycleColor(Task task) async {
    final next = switch (task.color) {
      TaskColor.standard => TaskColor.blue,
      TaskColor.blue     => TaskColor.yellow,
      TaskColor.yellow   => task.scheduledDate != null ? TaskColor.red : TaskColor.standard,
      TaskColor.red      => TaskColor.standard,
    };
    if (next == TaskColor.standard) {
        task.scheduledDate = null;
    }
    task.color = next;
    await _isar.writeTxn(() => _isar.tasks.put(task));
  }

  Future<void> deleteRoutine(Id routineId) async {
    final routine = await _isar.routines.get(routineId);
    if (routine == null) return;
    await routine.days.load();
    final dayIds = routine.days.map((d) => d.id).toList();
    final taskIds = <Id>[];
    for (final day in routine.days) {
      await day.tasks.load();
      for (final t in day.tasks) {
         if (t.imageFileName != null) {
             await ImageService.deleteImage(t.imageFileName!);
         }
      }
      taskIds.addAll(day.tasks.map((t) => t.id));
    }
    await _isar.writeTxn(() async {
      await _isar.tasks.deleteAll(taskIds);
      await _isar.routineDays.deleteAll(dayIds);
      await _isar.routines.delete(routineId);
    });
  }

  // ── Helpers ──────────────────────────────────────────────────
  bool _blueEligible(Task t, DateTime today) {
    switch (t.frequency) {
      case FrequencyType.daily: return true;
      case FrequencyType.everyOtherDay:
        final diff = today.difference(DateTime(t.createdAt.year, t.createdAt.month, t.createdAt.day)).inDays;
        return diff % 2 == 0;
      case FrequencyType.custom:
        return t.frequencyDays.contains(today.weekday);
    }
  }

  Task _copyTask(Task src, TaskColor color) {
    final copy = Task()
      ..text = src.text
      ..createdAt = src.createdAt
      ..sortOrder = src.sortOrder
      ..color = color
      ..status = TaskStatus.active
      ..scheduledDate = src.scheduledDate
      ..completedOnDate = null
      ..imageFileName = src.imageFileName
      ..frequency = src.frequency
      ..frequencyDays = List<int>.from(src.frequencyDays)
      ..lastAppearedDate = src.lastAppearedDate
      ..hasImage = src.hasImage
      ..hasSubtasks = src.hasSubtasks
      ..subtasks = _copySubtasks(src, color);
    return copy;
  }

  List<Subtask> _copySubtasks(Task src, TaskColor color) {
    return src.subtasks.map((s) {
      final sub = Subtask()
        ..text = s.text
        ..createdAt = s.createdAt
        ..sortOrder = s.sortOrder
        ..isCompleted = color == TaskColor.yellow ? s.isCompleted : false
        ..completedAt = color == TaskColor.yellow ? s.completedAt : null
        ..miniTasks = s.miniTasks.map((m) {
          return MiniTask()
            ..text = m.text
            ..sortOrder = m.sortOrder
            ..isCompleted = color == TaskColor.yellow ? m.isCompleted : false
            ..completedAt = color == TaskColor.yellow ? m.completedAt : null;
        }).toList();
      return sub;
    }).toList();
  }
}
