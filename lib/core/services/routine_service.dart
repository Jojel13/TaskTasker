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
import 'alarm_service.dart';

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

    // ── Ler profile ANTES da transação (nunca criar vazio) ──────
    final profile = await _isar.userProfiles.get(1);
    if (profile == null) {
      throw Exception('UserProfile não inicializado. Execute o setup do app.');
    }

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
            if (sched == null || sched.isBefore(today)) continue; // expirada → skip
            eligible.add(t);
          } else if (t.color == TaskColor.blue) {
            if (_blueEligible(t, today)) eligible.add(t);
          } else if (t.color == TaskColor.yellow) {
            if (t.completedOnDate == null) eligible.add(t);
          }
          // standard: nunca propaga
        }
        if (day.division == DivisionType.tomorrow) {
          tomorrowTasks = eligible;
        } else {
          propagate[day.division] = eligible;
        }
      }
    }

    final today = _today();

    final routine = await _isar.writeTxn(() async {
      final r = Routine()
        ..name = profile.routineName
        ..date = today
        ..createdAt = DateTime.now();
      await _isar.routines.put(r);

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
        r.days.add(day);
      }
      await r.days.save();
      return r;
    });

    // ── Streak: verificar se o dia anterior teve tasks concluídas ─
    // Lemos o profile novamente (fora da txn anterior) para evitar
    // sobrescrever dados com objeto stale.
    await _checkAndFinalizeStreak(profile, today);

    return routine;
  }

  /// Verifica e atualiza o streak com base em tasks concluídas.
  /// Critério: pelo menos 1 task concluída na rotina do dia anterior.
  Future<void> _checkAndFinalizeStreak(UserProfile profile, DateTime today) async {
    final updatedProfile = await _isar.userProfiles.get(1);
    if (updatedProfile == null) return;

    final yesterday = today.subtract(const Duration(days: 1));
    final lastDate = updatedProfile.lastRoutineDate;

    // Só atualiza se ainda não foi processado para hoje
    final lastDateNormalized = lastDate != null
        ? DateTime(lastDate.year, lastDate.month, lastDate.day)
        : null;
    if (lastDateNormalized == today) return; // já processado

    final yesterdayNormalized = DateTime(yesterday.year, yesterday.month, yesterday.day);

    // Verificar se houve tasks concluídas ontem
    bool yesterdayHadCompletedTasks = false;
    if (lastDateNormalized == yesterdayNormalized) {
      // Buscar rotina de ontem
      final yesterdayRoutine = await _isar.routines
          .filter()
          .dateBetween(yesterday, yesterday.add(const Duration(hours: 23, minutes: 59)))
          .findFirst();

      if (yesterdayRoutine != null) {
        await yesterdayRoutine.days.load();
        for (final day in yesterdayRoutine.days) {
          await day.tasks.load();
          if (day.tasks.any((t) => t.status == TaskStatus.completed)) {
            yesterdayHadCompletedTasks = true;
            break;
          }
        }
      }
    }

    if (lastDateNormalized == yesterdayNormalized && yesterdayHadCompletedTasks) {
      updatedProfile.streakDays += 1;
    } else {
      updatedProfile.streakDays = 0; // Quebrou o streak
    }

    if (updatedProfile.streakDays > updatedProfile.streakRecord) {
      updatedProfile.streakRecord = updatedProfile.streakDays;
    }
    updatedProfile.lastRoutineDate = today;

    await _isar.writeTxn(() async {
      await _isar.userProfiles.put(updatedProfile);
    });

    await _xp.checkStreakBonus(updatedProfile);
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

  /// Deleta task e estorna XP se estava concluída.
  /// Exceção: tasks azuis que já apareceram (propagadas) não estornam streak.
  Future<void> deleteTask(Id dayId, Id taskId) async {
    // Ler task ANTES da transação para decisão de XP
    final task = await _isar.tasks.get(taskId);

    await _isar.writeTxn(() async {
      final day = await _isar.routineDays.get(dayId);
      if (day != null) {
        await day.tasks.load();
        day.tasks.removeWhere((t) => t.id == taskId);
        await day.tasks.save();
      }
      if (task != null && task.imageFileName != null) {
        await ImageService.deleteImage(task.imageFileName!);
      }
      await _isar.tasks.delete(taskId);
    });

    // Cancelar alarme se existia
    if (task != null && task.hasAlarm) {
      await AlarmService.cancelAlarm(taskId);
    }

    // Estornar XP se a task estava concluída
    if (task != null && task.status == TaskStatus.completed) {
      final xpAmount = XpService.xpForAction(task.color);
      await _xp.deductXp(xpAmount, 'Task concluída deletada (${task.color.name})');
    }

    // Verificar validade do streak para o dia de hoje após deleção
    await _revalidateStreakForToday();
  }

  /// Após deletar uma task concluída, verifica se ainda existem tasks
  /// concluídas hoje. Se não houver nenhuma, reseta o streakDays para 0
  /// apenas se o streakDays foi incrementado hoje.
  Future<void> _revalidateStreakForToday() async {
    final today = _today();
    final todayRoutine = await findTodayRoutine();
    if (todayRoutine == null) return;

    await todayRoutine.days.load();
    bool hasAnyCompleted = false;
    for (final day in todayRoutine.days) {
      await day.tasks.load();
      if (day.tasks.any((t) => t.status == TaskStatus.completed)) {
        hasAnyCompleted = true;
        break;
      }
    }

    if (!hasAnyCompleted) {
      // Sem tasks concluídas hoje — o streak do dia atual não deve contar
      // Não tocamos no streakRecord, apenas zera o streakDays do dia
      final profile = await _isar.userProfiles.get(1);
      if (profile == null) return;
      final lastDate = profile.lastRoutineDate;
      if (lastDate != null) {
        final lastNorm = DateTime(lastDate.year, lastDate.month, lastDate.day);
        if (lastNorm == today && profile.streakDays > 0) {
          profile.streakDays = 0;
          await _isar.writeTxn(() async => _isar.userProfiles.put(profile));
        }
      }
    }
  }

  Future<void> moveTaskToDay(Id taskId, Id newDayId) async {
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task == null) return;

      final oldDay = await _isar.routineDays.filter().tasks((q) => q.idEqualTo(taskId)).findFirst();
      if (oldDay != null) {
        if (oldDay.id == newDayId) return;
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

  /// Loop de cores: branco → azul → amarelo → branco.
  /// Vermelho NÃO faz parte do loop — é uma mecânica separada via calendário.
  Future<void> cycleColor(Task task) async {
    final next = switch (task.color) {
      TaskColor.standard => TaskColor.blue,
      TaskColor.blue     => TaskColor.yellow,
      TaskColor.yellow   => TaskColor.standard,
      TaskColor.red      => TaskColor.standard, // red → reset (nunca deve ocorrer via loop)
    };
    // Ao voltar para branco, limpar data agendada e frequência
    if (next == TaskColor.standard) {
      task.scheduledDate = null;
    }
    // Ao sair do azul, limpar frequência
    if (task.color == TaskColor.blue && next != TaskColor.blue) {
      task.frequency = FrequencyType.daily;
      task.frequencyDays = [];
    }
    task.color = next;
    await _isar.writeTxn(() => _isar.tasks.put(task));
  }

  /// Define a task como vermelha com data agendada.
  /// Mecânica separada do loop de cores.
  Future<void> setTaskRed(Task task, DateTime scheduledDate) async {
    task.color = TaskColor.red;
    task.scheduledDate = scheduledDate;
    await _isar.writeTxn(() => _isar.tasks.put(task));
  }

  /// Remove o status vermelho, voltando para branco.
  Future<void> clearTaskRed(Task task) async {
    task.color = TaskColor.standard;
    task.scheduledDate = null;
    await _isar.writeTxn(() => _isar.tasks.put(task));
  }

  // ─── Alarme Individual (Fase 3) ──────────────────────────────────

  /// Define (ou atualiza) o alarme de uma task.
  /// [time] deve ser um DateTime com a data e hora exatas do alarme.
  /// [repeat] = true para repetir 3x a cada 5 min.
  Future<void> setAlarm(Task task, DateTime time, {bool repeat = false}) async {
    task.alarmTime = time;
    task.alarmRepeat = repeat;
    await _isar.writeTxn(() => _isar.tasks.put(task));
    await AlarmService.scheduleAlarm(task);
  }

  /// Remove o alarme de uma task.
  Future<void> clearAlarm(Task task) async {
    await AlarmService.cancelAlarm(task.id);
    task.alarmTime = null;
    task.alarmRepeat = false;
    await _isar.writeTxn(() => _isar.tasks.put(task));
  }

  Future<void> updateTaskSortOrder(List<Task> tasks) async {
    await _isar.writeTxn(() async {
      for (int i = 0; i < tasks.length; i++) {
        tasks[i].sortOrder = i;
        await _isar.tasks.put(tasks[i]);
      }
    });
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

  Future<void> deleteAllPastRoutines() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pastRoutines = await _isar.routines.filter().dateLessThan(today).findAll();
    for (final r in pastRoutines) {
      await deleteRoutine(r.id);
    }
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
