import 'package:flutter/foundation.dart' show debugPrint;
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
import 'notification_service.dart';

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

    final pastRoutines = await _isar.routines.where().sortByDateDesc().findAll();
    final lastRoutine = pastRoutines.isNotEmpty ? pastRoutines.first : null;

    // Coletar dados fora da transaction (reads)
    Map<DivisionType, List<Task>> propagate = {
      DivisionType.morning: [],
      DivisionType.afternoon: [],
      DivisionType.night: [],
    };
    List<Task> tomorrowTasks = [];

    final today = _today();

    if (lastRoutine != null) {
      await lastRoutine.days.load();
      for (final day in lastRoutine.days) {
        await day.tasks.load();
        final tasks = day.tasks.toList();
        
        if (day.division == DivisionType.tomorrow) {
          // Divisão "Para Amanhã" propaga independente da cor (se não concluída)
          for (final t in tasks) {
            if (t.status != TaskStatus.completed) {
              tomorrowTasks.add(t);
            }
          }
        } else {
          // Outras divisões propagam apenas amarelas não concluídas e vermelhas futuras
          final eligible = <Task>[];
          for (final t in tasks) {
            if (t.color == TaskColor.red) {
              final sched = t.scheduledDate;
              if (sched == null || sched.isBefore(today)) continue; // expirada → skip
              eligible.add(t);
            } else if (t.color == TaskColor.yellow) {
              if (t.completedOnDate == null) eligible.add(t);
            }
            // blue: tratado separadamente no _getEligibleBlueTasks
            // standard: nunca propaga
          }
          propagate[day.division] = eligible;
        }
      }
    }

    // Coletar tasks azuis propagadas
    final tomorrowTexts = tomorrowTasks.map((t) => t.text.trim()).toSet();
    final blueTasksMap = await _getEligibleBlueTasks(today, pastRoutines, tomorrowTexts);

    // ── Copiar imagens fora da transação (Evitar I/O pesado no writeTxn)
    final Map<int, String?> copiedImages = {};
    for (final division in DivisionType.values) {
      final tasksToCopy = division == DivisionType.morning
          ? [
              ...(propagate[division] ?? []),
              ...(blueTasksMap[division] ?? []),
              ...tomorrowTasks,
            ]
          : [
              ...(propagate[division] ?? []),
              ...(blueTasksMap[division] ?? []),
            ];
      for (final t in tasksToCopy) {
        if (t.imageFileName != null && !copiedImages.containsKey(t.id)) {
          copiedImages[t.id] = await ImageService.copyImage(t.imageFileName!);
        }
      }
    }

    final List<Task> tasksWithAlarms = [];

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
            ? [
                ...(propagate[division] ?? []),
                ...(blueTasksMap[division] ?? []),
                ...tomorrowTasks,
              ]
            : [
                ...(propagate[division] ?? []),
                ...(blueTasksMap[division] ?? []),
              ];

        for (final src in tasks) {
          final copy = _copyTask(src, src.color, today);
          if (copiedImages.containsKey(src.id)) {
            copy.imageFileName = copiedImages[src.id];
          } else {
            copy.imageFileName = null;
          }
          await _isar.tasks.put(copy);
          day.tasks.add(copy);

          if (copy.hasAlarm) {
            tasksWithAlarms.add(copy);
          }
        }
        await day.tasks.save();
        r.days.add(day);
      }
      await r.days.save();
      return r;
    });

    // Agendar alarmes (respeitando preferência de som do usuário)
    final soundEnabled = profile.alarmSoundEnabled;
    for (final task in tasksWithAlarms) {
      await AlarmService.scheduleAlarm(task, soundEnabled: soundEnabled);
    }

    // P5: Notificar tasks amarelas propagadas do dia anterior
    await _notifyPendingYellowTasks(routine, notifEnabled: profile.notifEnabled);

    // ── Streak: verificar se o dia anterior teve tasks concluídas ─
    // Lemos o profile novamente (fora da txn anterior) para evitar
    // sobrescrever dados com objeto stale.
    await _checkAndFinalizeStreak(profile, today);

    return routine;
  }

  /// P5: Conta tasks amarelas propagadas e dispara notificação discreta se houver pendências.
  /// [notifEnabled] vem do UserProfile para respeitar preferência global de notificações.
  Future<void> _notifyPendingYellowTasks(Routine routine, {required bool notifEnabled}) async {
    try {
      // Recarregar a rotina recém-criada do banco para contar tasks amarelas
      final routineFromDb = await _isar.routines.get(routine.id);
      if (routineFromDb == null) return;
      await routineFromDb.days.load();
      int yellowCount = 0;
      for (final day in routineFromDb.days) {
        await day.tasks.load();
        for (final t in day.tasks) {
          if (t.color == TaskColor.yellow && t.status != TaskStatus.completed) {
            yellowCount++;
          }
        }
      }
      if (yellowCount > 0 && notifEnabled) {
        await NotificationService.instance.showTestNotification(
          id: 998,
          title: '📋 $yellowCount ${yellowCount == 1 ? 'tarefa pendente' : 'tarefas pendentes'} de ontem',
          body: yellowCount == 1
              ? 'Você tem 1 tarefa frequente pendente do dia anterior.'
              : 'Você tem $yellowCount tarefas frequentes pendentes do dia anterior.',
        );
      }
    } catch (e) {
      // Não deixar erro aqui quebrar o fluxo principal
      debugPrint('P5 _notifyPendingYellowTasks error: $e');
    }
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
    final String? imageToDelete = task?.imageFileName;

    await _isar.writeTxn(() async {
      final day = await _isar.routineDays.get(dayId);
      if (day != null) {
        await day.tasks.load();
        day.tasks.removeWhere((t) => t.id == taskId);
        await day.tasks.save();
      }
      await _isar.tasks.delete(taskId);
    });

    if (imageToDelete != null) {
      await ImageService.deleteImage(imageToDelete);
    }

    if (task != null) {
      if (task.hasAlarm) {
        await AlarmService.cancelAlarm(taskId);
      }
      if (task.color == TaskColor.red) {
        await AlarmService.cancelRedTaskNotification(taskId);
      }
    }

    // Estornar XP se a task estava concluída
    if (task != null && task.status == TaskStatus.completed) {
      final xpAmount = XpService.xpForAction(task.color);
      await _xp.deductXp(xpAmount, 'Task concluída deletada (${task.color.name})');
    }
  }



  Future<void> moveTaskToDay(Id taskId, Id newDayId) async {
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task == null) return;

      // M6: Resetar cadência de tasks azuis se movidas
      if (task.color == TaskColor.blue) {
        task.createdAt = DateTime.now();
        await _isar.tasks.put(task);
      }

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

  Future<void> reorderTasks(Id dayId, int oldIndex, int newIndex) async {
    await _isar.writeTxn(() async {
      final day = await _isar.routineDays.get(dayId);
      if (day == null) return;
      await day.tasks.load();

      final tasks = day.tasks.toList()
        ..sort((a, b) => a.sortOrder != b.sortOrder
            ? a.sortOrder.compareTo(b.sortOrder)
            : a.createdAt.compareTo(b.createdAt));

      if (oldIndex < newIndex) newIndex -= 1;
      final task = tasks.removeAt(oldIndex);
      tasks.insert(newIndex, task);

      // A14: usar putAll para gravar N tasks em uma única operação
      for (int i = 0; i < tasks.length; i++) {
        tasks[i].sortOrder = i;
      }
      await _isar.tasks.putAll(tasks);
    });
  }

  Future<void> toggleTask(Task task) async {
    final nowCompleted = task.status != TaskStatus.completed;
    // A8: todas as mutasão de estado feitas dentro do writeTxn para
    // garantir consistência módel<->banco em caso de falha
    await _isar.writeTxn(() async {
      task.status = nowCompleted ? TaskStatus.completed : TaskStatus.active;
      task.completedOnDate = nowCompleted ? DateTime.now() : null;
      await _isar.tasks.put(task);
    });
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
      if (task.hasAlarm) {
        await AlarmService.cancelAlarm(task.id);
        task.alarmTime = null;
        task.alarmRepeat = false;
      }
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
    if (task.hasAlarm) {
      // Ajustar data do alarme para a nova data agendada, mantendo o horário original
      final t = task.alarmTime!;
      task.alarmTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        t.hour,
        t.minute,
      );
      // Re-agendar alarme individual para a nova data
      final profile = await _isar.userProfiles.get(1);
      await AlarmService.scheduleAlarm(task, soundEnabled: profile?.alarmSoundEnabled ?? true);
    }
    await _isar.writeTxn(() => _isar.tasks.put(task));
    // Ler preferência de som do usuário antes de agendar
    final profile = await _isar.userProfiles.get(1);
    await AlarmService.scheduleRedTaskNotification(
      task,
      soundEnabled: profile?.alarmSoundEnabled ?? true,
    );
  }

  /// Remove o status vermelho, voltando para branco.
  Future<void> clearTaskRed(Task task) async {
    task.color = TaskColor.standard;
    task.scheduledDate = null;
    await _isar.writeTxn(() => _isar.tasks.put(task));
    await AlarmService.cancelRedTaskNotification(task.id);
  }

  // ─── Alarme Individual (Fase 3) ──────────────────────────────────

  /// Define (ou atualiza) o alarme de uma task.
  /// [time] deve ser um DateTime com a data e hora exatas do alarme.
  /// [repeat] = true para repetir 3x a cada 5 min.
  /// [fullScreen] = true para habilitar modo alarme completo (tela cheia).
  Future<void> setAlarm(Task task, DateTime time, {bool repeat = false, bool fullScreen = false}) async {
    task.alarmTime = time;
    task.alarmRepeat = repeat;
    task.alarmFullScreen = fullScreen;
    await _isar.writeTxn(() => _isar.tasks.put(task));

    // Se for uma task vermelha, precisamos recancelar a notificação padrão das 8h (slot 9)
    if (task.color == TaskColor.red) {
      await AlarmService.cancelRedTaskNotification(task.id);
    }

    // Ler preferência de som do usuário antes de agendar
    final profile = await _isar.userProfiles.get(1);
    await AlarmService.scheduleAlarm(task, soundEnabled: profile?.alarmSoundEnabled ?? true);
  }

  /// Remove o alarme de uma task.
  Future<void> clearAlarm(Task task) async {
    await AlarmService.cancelAlarm(task.id);
    task.alarmTime = null;
    task.alarmRepeat = false;
    task.alarmFullScreen = false;
    await _isar.writeTxn(() => _isar.tasks.put(task));

    // Se for vermelha, ao limpar o alarme individual devemos re-agendar a notificação padrão das 8h (slot 9)
    if (task.color == TaskColor.red) {
      final profile = await _isar.userProfiles.get(1);
      await AlarmService.scheduleRedTaskNotification(task, soundEnabled: profile?.alarmSoundEnabled ?? true);
    }
  }

  Future<void> updateTaskSortOrder(List<Task> tasks) async {
    // A14: putAll é O(1) transação vs N puts individuais
    await _isar.writeTxn(() async {
      for (int i = 0; i < tasks.length; i++) {
        tasks[i].sortOrder = i;
      }
      await _isar.tasks.putAll(tasks);
    });
  }

  Future<void> deleteRoutine(Id routineId) async {
    final routine = await _isar.routines.get(routineId);
    if (routine == null) return;
    await routine.days.load();
    final dayIds = routine.days.map((d) => d.id).toList();
    final taskIds = <Id>[];
    final imagesToDelete = <String>[];
    final alarmsToCancel = <int>[];
    for (final day in routine.days) {
      await day.tasks.load();
      for (final t in day.tasks) {
        if (t.imageFileName != null) {
          imagesToDelete.add(t.imageFileName!);
        }
        if (t.hasAlarm) {
          alarmsToCancel.add(t.id);
        }
      }
      taskIds.addAll(day.tasks.map((t) => t.id));
    }
    await _isar.writeTxn(() async {
      await _isar.tasks.deleteAll(taskIds);
      await _isar.routineDays.deleteAll(dayIds);
      await _isar.routines.delete(routineId);
    });
    for (final taskId in alarmsToCancel) {
      await AlarmService.cancelAlarm(taskId);
    }
    for (final image in imagesToDelete) {
      await ImageService.deleteImage(image);
    }
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
  Future<Map<DivisionType, List<Task>>> _getEligibleBlueTasks(
    DateTime today,
    List<Routine> pastRoutines,
    Set<String> tomorrowTexts,
  ) async {
    final allBlueTasks = await _isar.tasks
        .filter()
        .colorEqualTo(TaskColor.blue)
        .findAll();
    
    final Map<DivisionType, List<Task>> result = {
      DivisionType.morning: [],
      DivisionType.afternoon: [],
      DivisionType.night: [],
    };

    if (allBlueTasks.isEmpty) return result;

    // Agrupar por texto para obter a versão mais recente
    final Map<String, Task> latestTaskMap = {};
    for (final t in allBlueTasks) {
      final text = t.text.trim();
      final existing = latestTaskMap[text];
      if (existing == null || t.createdAt.isAfter(existing.createdAt)) {
        latestTaskMap[text] = t;
      }
    }

    for (final entry in latestTaskMap.entries) {
      final text = entry.key;
      final latestTask = entry.value;

      // Evita duplicidade se já está vindo via divisão amanhã
      if (tomorrowTexts.contains(text)) continue;

      // Encontrar a rotina mais recente onde esta task deveria ter aparecido
      Routine? mostRecentEligibleRoutine;
      for (final r in pastRoutines) {
        final rDate = DateTime(r.date.year, r.date.month, r.date.day);
        if (_blueEligible(latestTask, rDate)) {
          mostRecentEligibleRoutine = r;
          break;
        }
      }

      if (mostRecentEligibleRoutine == null) {
        // Sem ocorrência elegível passada: se elegível hoje, adiciona à manhã por padrão
        if (_blueEligible(latestTask, today)) {
          result[DivisionType.morning]!.add(latestTask);
        }
        continue;
      }

      // Verificar se ela existia na rotina mais recente elegível
      await mostRecentEligibleRoutine.days.load();
      bool existsInRoutine = false;
      DivisionType foundDivision = DivisionType.morning;

      for (final day in mostRecentEligibleRoutine.days) {
        await day.tasks.load();
        if (day.tasks.any((t) => t.text.trim() == text && t.color == TaskColor.blue)) {
          existsInRoutine = true;
          foundDivision = day.division;
          break;
        }
      }

      if (existsInRoutine) {
        final targetDivision = foundDivision == DivisionType.tomorrow ? DivisionType.morning : foundDivision;
        if (_blueEligible(latestTask, today)) {
          result[targetDivision]!.add(latestTask);
        }
      }
    }

    return result;
  }

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

  Task _copyTask(Task src, TaskColor color, DateTime targetDate) {
    DateTime? newAlarmTime;
    bool newAlarmRepeat = src.alarmRepeat;

    if (src.alarmTime != null) {
      final candidate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        src.alarmTime!.hour,
        src.alarmTime!.minute,
      );
      // P1: Se o horário calculado para hoje já passou, descartamos o alarme
      // para evitar badge ⏰ "fantasma" sem notificação real agendada.
      if (candidate.isAfter(DateTime.now())) {
        newAlarmTime = candidate;
      } else {
        newAlarmTime = null;
        newAlarmRepeat = false;
      }
    }

    final copiedSubtasks = _copySubtasks(src, color);

    TaskStatus newStatus = TaskStatus.active;
    DateTime? newCompletedOnDate;
    if (color == TaskColor.yellow &&
        copiedSubtasks.isNotEmpty &&
        copiedSubtasks.every((s) => s.isCompleted)) {
      newStatus = TaskStatus.completed;
      newCompletedOnDate = targetDate;
    }

    final copy = Task()
      ..text = src.text
      ..createdAt = src.createdAt
      ..sortOrder = src.sortOrder
      ..color = color
      ..status = newStatus
      ..scheduledDate = src.scheduledDate
      ..completedOnDate = newCompletedOnDate
      ..imageFileName = src.imageFileName
      ..frequency = src.frequency
      ..frequencyDays = List<int>.from(src.frequencyDays)
      ..lastAppearedDate = src.lastAppearedDate
      ..hasImage = src.hasImage
      ..hasSubtasks = src.hasSubtasks
      ..alarmTime = newAlarmTime
      ..alarmRepeat = newAlarmRepeat
      ..alarmFullScreen = src.alarmFullScreen
      ..subtasks = copiedSubtasks;
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
