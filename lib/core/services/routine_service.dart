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
import '../utils/blue_cadence.dart';
import '../utils/habit_id.dart';

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

  static bool _isCreating = false;

  // ── Criar rotina ─────────────────────────────────────────────
  Future<Routine> createRoutine() async {
    while (_isCreating) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _isCreating = true;
    try {
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
    final Set<String> propagatedHabitIds = {};

    final today = _today();

    if (lastRoutine != null) {
      await lastRoutine.days.load();
      for (final day in lastRoutine.days) {
        await day.tasks.load();
        // Ordenar conforme o sortOrder definido pelo usuário via drag & drop
        final tasks = day.tasks.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        
        if (day.division == DivisionType.tomorrow) {
          // Divisão "Para Amanhã" propaga independente da cor (se não concluída)
          for (final t in tasks) {
            if (t.status != TaskStatus.completed) {
              tomorrowTasks.add(t);
              if (t.color == TaskColor.blue && t.habitId != null) {
                propagatedHabitIds.add(t.habitId!);
              }
            }
          }
        } else {
          // Preserva a sequência exata de tarefas amarelas, vermelhas e azuis elegíveis
          final eligible = <Task>[];
          for (final t in tasks) {
            if (t.isWeekendTask) {
              // Task de fim de semana:
              // Se hoje for domingo e não foi concluída no sábado, propaga para domingo!
              // Se foi concluída, não propaga (desaparece).
              // Se hoje for segunda-feira ou outro dia da semana, não propaga (pula para o próximo fim de semana).
              if (today.weekday == DateTime.sunday && t.status != TaskStatus.completed) {
                eligible.add(t);
              }
              continue;
            }

            if (t.color == TaskColor.red) {
              // Vermelha não concluída propaga até ser feita; se a data já passou,
              // segue como "atrasada" (badge na UI) em vez de sumir.
              if (t.status == TaskStatus.completed) continue;
              if (t.scheduledDate == null) continue;
              eligible.add(t);
            } else if (t.color == TaskColor.yellow) {
              if (t.completedOnDate == null) eligible.add(t);
            } else if (t.color == TaskColor.blue) {
              if (BlueCadence.isEligibleOn(t, today)) {
                eligible.add(t);
                if (t.habitId != null) propagatedHabitIds.add(t.habitId!);
              }
            }
          }
          propagate[day.division] = eligible;
        }
      }
    }

    // Coletar tasks de fim de semana se hoje for sábado ou domingo
    final weekendTasksToInject = <Task>[];
    bool didInjectWeekendTasks = false;
    if (today.weekday == DateTime.saturday || today.weekday == DateTime.sunday) {
      bool alreadyInjected = false;
      if (profile.lastWeekendInjection != null) {
        final last = profile.lastWeekendInjection!;
        final thisSaturday = today.weekday == DateTime.saturday ? today : today.subtract(const Duration(days: 1));
        if (!last.isBefore(thisSaturday)) {
          alreadyInjected = true;
        }
      }
      if (!alreadyInjected) {
        final backlog = await _isar.tasks
            .filter()
            .isWeekendTaskEqualTo(true)
            .weekendOriginIdIsNull()
            .statusEqualTo(TaskStatus.active)
            .findAll();
        weekendTasksToInject.addAll(backlog);
        didInjectWeekendTasks = true;
      }
    }

    // Coletar outras tasks azuis elegíveis que não estavam na rotina de ontem (ex: cadências semanais)
    final blueTasksMap = await _getEligibleBlueTasks(today, propagatedHabitIds);

    // ── Copiar imagens fora da transação (Evitar I/O pesado no writeTxn)
    final Map<int, String?> copiedImages = {};
    for (final division in DivisionType.values) {
      final tasksToCopy = division == DivisionType.morning
          ? [
              ...(propagate[division] ?? []),
              ...(blueTasksMap[division] ?? []),
              ...tomorrowTasks,
              ...weekendTasksToInject,
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

    final List<Task> createdCopies = [];
    final List<int> sourceIds = [];

    final routine = await _isar.writeTxn(() async {
      final doubleCheck = await _isar.routines
          .where()
          .filter()
          .dateBetween(today, today.add(const Duration(hours: 23, minutes: 59)))
          .findFirst();
      if (doubleCheck != null) return doubleCheck;

      if (didInjectWeekendTasks) {
        profile.lastWeekendInjection = today;
        await _isar.userProfiles.put(profile);
      }

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
                ...weekendTasksToInject,
              ]
            : [
                ...(propagate[division] ?? []),
                ...(blueTasksMap[division] ?? []),
              ];

        // Normalização contínua do sortOrder para preservar drag & drop
        for (int i = 0; i < tasks.length; i++) {
          final src = tasks[i];
          final copy = _copyTask(src, src.color, today);
          copy.sortOrder = i;

          if (copiedImages.containsKey(src.id)) {
            copy.imageFileName = copiedImages[src.id];
          } else {
            copy.imageFileName = null;
          }
          await _isar.tasks.put(copy);
          day.tasks.add(copy);
          createdCopies.add(copy);
          sourceIds.add(src.id);
        }
        await day.tasks.save();
        r.days.add(day);
      }
      await r.days.save();
      return r;
    });

    // Alarmes migram da task de origem (rotina anterior) para a cópia de hoje:
    // sem isso o "✓ Concluir" da notificação marcaria a task de ontem.
    final soundEnabled = profile.alarmSoundEnabled;
    for (final id in sourceIds) {
      await AlarmService.cancelAllForTask(id);
    }
    for (final copy in createdCopies) {
      if (copy.hasAlarm) {
        await AlarmService.scheduleAlarm(copy, soundEnabled: soundEnabled);
      }
      if (copy.color == TaskColor.red) {
        await AlarmService.scheduleRedTaskNotification(copy, soundEnabled: soundEnabled);
      }
    }
    // A rotina de hoje passa a ser a fonte dos alarmes azuis de hoje;
    // os pré-agendamentos de hábito seguem cobrindo os próximos dias.
    await refreshAllHabitAlarms();

    // P5: Notificar tasks amarelas propagadas do dia anterior
    await _notifyPendingYellowTasks(routine, notifEnabled: profile.notifEnabled);

    // ── Streak: verificar se o dia anterior teve tasks concluídas ─
    await _checkAndFinalizeStreak(profile, today);

    return routine;
    } finally {
      _isCreating = false;
    }
  }

  /// P5: Conta tasks amarelas propagadas e dispara notificação discreta se houver pendências.
  /// [notifEnabled] vem do UserProfile para respeitar preferência global de notificações.
  Future<void> _notifyPendingYellowTasks(Routine routine, {required bool notifEnabled}) async {
    try {
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
      } else {
        // Se a rotina de ontem não está no banco (ex: histórico limpo), mas o lastRoutineDate
        // confirma que o app foi aberto ontem e streak está ativo, mantém continuidade.
        yesterdayHadCompletedTasks = updatedProfile.streakDays > 0;
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
      await day.tasks.load();
      int maxSort = -1;
      for (final t in day.tasks) {
        if (t.sortOrder > maxSort) {
          maxSort = t.sortOrder;
        }
      }
      final task = Task()
        ..text = text
        ..createdAt = DateTime.now()
        ..sortOrder = maxSort + 1
        ..color = TaskColor.standard
        ..status = TaskStatus.active;
      await _isar.tasks.put(task);
      day.tasks.add(task);
      await day.tasks.save();
      return task;
    });
  }

  /// Conclusão de task — ponto único para UI, notificações e subtasks
  Future<void> completeTask(int taskId) async {
    final task = await _isar.tasks.get(taskId);
    if (task == null || task.status == TaskStatus.completed) return;
    await toggleTask(task);
  }

  /// Desmarcação de task
  Future<void> uncompleteTask(int taskId) async {
    final task = await _isar.tasks.get(taskId);
    if (task == null || task.status != TaskStatus.completed) return;
    await toggleTask(task);
  }

  /// Deleta task e estorna XP se estava concluída.
  /// Se [endHabit] for true, desativa a recorrência do hábito em todas as cópias.
  Future<void> deleteTask(Id dayId, Id taskId, {bool endHabit = false}) async {
    // Ler task ANTES da transação para decisão de XP
    final task = await _isar.tasks.get(taskId);
    final String? imageToDelete = task?.imageFileName;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _isar.writeTxn(() async {
      final day = await _isar.routineDays.get(dayId);
      if (day != null) {
        await day.tasks.load();
        day.tasks.removeWhere((t) => t.id == taskId);
        await day.tasks.save();
      }
      await _isar.tasks.delete(taskId);
    });

    if (task != null && task.color == TaskColor.blue) {
      if (endHabit) {
        await terminateBlueHabitFromToday(taskId);
      } else if (task.habitId != null) {
        // Apagada apenas hoje: cancela o alarme de hoje deste hábito
        await AlarmService.cancelHabitAlarmForDay(task.habitId!, today);
      }
    }

    if (imageToDelete != null) {
      await ImageService.deleteImage(imageToDelete);
    }

    if (task != null) {
      await AlarmService.cancelAllForTask(taskId);
    }

    // Estornar XP se a task estava concluída
    if (task != null && task.status == TaskStatus.completed) {
      final xpAmount = XpService.xpForAction(task.color);
      await _xp.deductXp(xpAmount, 'Task concluída deletada (${task.color.name})');
    }
  }

  Future<void> moveTaskToDay(Id taskId, Id newDayId, {int? targetIndex}) async {
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task == null) return;

      // M6: Atualizar âncora de cadência sem alterar createdAt
      if (task.color == TaskColor.blue) {
        task.cadenceAnchor = DateTime.now();
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
        final existingTasks = newDay.tasks.toList()
          ..sort((a, b) => a.sortOrder != b.sortOrder
              ? a.sortOrder.compareTo(b.sortOrder)
              : a.createdAt.compareTo(b.createdAt));

        if (targetIndex != null && targetIndex >= 0 && targetIndex <= existingTasks.length) {
          existingTasks.insert(targetIndex, task);
        } else {
          existingTasks.add(task);
        }

        for (int i = 0; i < existingTasks.length; i++) {
          existingTasks[i].sortOrder = i;
        }
        await _isar.tasks.putAll(existingTasks);

        newDay.tasks.clear();
        newDay.tasks.addAll(existingTasks);
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
    int subtasksXpDelta = 0;

    await _isar.writeTxn(() async {
      task.status = nowCompleted ? TaskStatus.completed : TaskStatus.active;
      task.completedOnDate = nowCompleted ? DateTime.now() : null;

      // Cascata em subtasks e mini-tasks
      if (nowCompleted) {
        for (final sub in task.subtasks) {
          if (!sub.isCompleted) {
            sub.isCompleted = true;
            sub.completedAt = DateTime.now();
            subtasksXpDelta += 3;
          }
          for (final mini in sub.miniTasks) {
            if (!mini.isCompleted) {
              mini.isCompleted = true;
              mini.completedAt = DateTime.now();
              subtasksXpDelta += 5;
            }
          }
        }
      } else {
        for (final sub in task.subtasks) {
          if (sub.isCompleted) {
            sub.isCompleted = false;
            sub.completedAt = null;
            subtasksXpDelta -= 3;
          }
          for (final mini in sub.miniTasks) {
            if (mini.isCompleted) {
              mini.isCompleted = false;
              mini.completedAt = null;
              subtasksXpDelta -= 5;
            }
          }
        }
      }

      await _isar.tasks.put(task);

      // Se for cópia de FDS na rotina, sincroniza com o original no backlog (fica riscada)
      if (task.weekendOriginId != null) {
        final origin = await _isar.tasks.get(task.weekendOriginId!);
        if (origin != null) {
          origin.status = task.status;
          origin.completedOnDate = task.completedOnDate;
          await _isar.tasks.put(origin);
        }
      }
    });

    final desc = '${nowCompleted ? "Task" : "Desmarcou task"} (${task.color.name})';
    final mainXp = XpService.xpForAction(task.color);

    if (nowCompleted) {
      await _xp.addXp(mainXp, desc);
      if (subtasksXpDelta > 0) {
        await _xp.addXp(subtasksXpDelta, 'Subtasks concluídas em cascata');
      }
      await AlarmService.cancelAlarm(task.id);
      await AlarmService.cancelRedTaskNotification(task.id);
      if (task.color == TaskColor.blue && task.habitId != null) {
        final now = DateTime.now();
        await AlarmService.cancelHabitAlarmForDay(
          task.habitId!,
          DateTime(now.year, now.month, now.day),
        );
      }
    } else {
      await _xp.deductXp(mainXp, desc);
      if (subtasksXpDelta < 0) {
        await _xp.deductXp(subtasksXpDelta.abs(), 'Subtasks desmarcadas em cascata');
      }
      final profile = await _isar.userProfiles.get(1);
      final soundEnabled = profile?.alarmSoundEnabled ?? true;
      await AlarmService.scheduleAlarm(task, soundEnabled: soundEnabled);
      if (task.color == TaskColor.red) {
        await AlarmService.scheduleRedTaskNotification(task, soundEnabled: soundEnabled);
      }
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

    // Ao virar azul: atribuir habitId se não tiver e definir âncora de cadência
    if (next == TaskColor.blue) {
      task.habitId ??= HabitIdGenerator.generate();
      task.cadenceAnchor ??= DateTime.now();
      task.isRecurrenceActive = true;
    }

    // Ao sair do azul (para amarelo): encerrar recorrência das outras cópias
    if (task.color == TaskColor.blue && next != TaskColor.blue) {
      final habitId = task.habitId;
      if (habitId != null) {
        await AlarmService.cancelHabitAlarms(habitId);
        final siblings = await _isar.tasks
            .filter()
            .habitIdEqualTo(habitId)
            .findAll();
        for (final s in siblings) {
          if (s.id != task.id) {
            s.isRecurrenceActive = false;
            s.recurrenceEndDate = DateTime.now();
          }
        }
        if (siblings.isNotEmpty) {
          await _isar.writeTxn(() => _isar.tasks.putAll(siblings));
        }
      }
      task.frequency = FrequencyType.daily;
      task.frequencyDays = [];
      task.isRecurrenceActive = true;
    }

    // Ao voltar para branco, limpar data agendada e frequência
    if (next == TaskColor.standard) {
      task.scheduledDate = null;
      if (task.hasAlarm) {
        await AlarmService.cancelAlarm(task.id);
        task.alarmTime = null;
        task.alarmRepeat = false;
      }
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
    }
    // BUG-07: salvar no banco ANTES de agendar alarme para garantir consistência
    await _isar.writeTxn(() => _isar.tasks.put(task));
    // Ler preferência de som do usuário antes de agendar
    final profile = await _isar.userProfiles.get(1);
    if (task.hasAlarm) {
      // Re-agendar alarme individual para a nova data
      await AlarmService.scheduleAlarm(task, soundEnabled: profile?.alarmSoundEnabled ?? true);
    }
    await AlarmService.scheduleRedTaskNotification(
      task,
      soundEnabled: profile?.alarmSoundEnabled ?? true,
    );
  }

  /// Remove o status vermelho, voltando para branco.
  Future<void> clearTaskRed(Task task) async {
    // BUG-12: cancelar também o alarme individual (slots 0-2) além do slot 9
    if (task.hasAlarm) {
      await AlarmService.cancelAlarm(task.id);
      task.alarmTime = null;
      task.alarmRepeat = false;
      task.alarmFullScreen = false;
    }
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

    final profile = await _isar.userProfiles.get(1);
    final soundEnabled = profile?.alarmSoundEnabled ?? true;

    // Resposta do usuário: vermelha toca as duas (alarme pontual + notificação das 8h)
    if (task.color == TaskColor.red) {
      await AlarmService.scheduleRedTaskNotification(task, soundEnabled: soundEnabled);
    }

    // Se for azul com hábito, sincronizar alarme com todas as cópias ativas e re-agendar janela
    if (task.color == TaskColor.blue && task.habitId != null) {
      final siblings = await _isar.tasks
          .filter()
          .habitIdEqualTo(task.habitId!)
          .isRecurrenceActiveEqualTo(true)
          .findAll();
      for (final s in siblings) {
        if (s.id != task.id) {
          s.alarmTime = time;
          s.alarmRepeat = repeat;
          s.alarmFullScreen = fullScreen;
        }
      }
      if (siblings.isNotEmpty) {
        await _isar.writeTxn(() => _isar.tasks.putAll(siblings));
      }
      await AlarmService.refreshHabitAlarms(
        task,
        includeToday: false,
        soundEnabled: soundEnabled,
      );
    }

    await AlarmService.scheduleAlarm(task, soundEnabled: soundEnabled);
  }

  /// Remove o alarme de uma task.
  Future<void> clearAlarm(Task task) async {
    await AlarmService.cancelAlarm(task.id);
    task.alarmTime = null;
    task.alarmRepeat = false;
    task.alarmFullScreen = false;
    await _isar.writeTxn(() => _isar.tasks.put(task));

    // Se for azul com hábito, cancelar alarmes futuros e limpar cópias ativas
    if (task.color == TaskColor.blue && task.habitId != null) {
      await AlarmService.cancelHabitAlarms(task.habitId!);
      final siblings = await _isar.tasks
          .filter()
          .habitIdEqualTo(task.habitId!)
          .isRecurrenceActiveEqualTo(true)
          .findAll();
      for (final s in siblings) {
        if (s.id != task.id) {
          s.alarmTime = null;
          s.alarmRepeat = false;
          s.alarmFullScreen = false;
        }
      }
      if (siblings.isNotEmpty) {
        await _isar.writeTxn(() => _isar.tasks.putAll(siblings));
      }
    }

    // Se for vermelha, ao limpar o alarme individual devemos re-agendar a notificação padrão das 8h (slot 9)
    if (task.color == TaskColor.red) {
      final profile = await _isar.userProfiles.get(1);
      await AlarmService.scheduleRedTaskNotification(task, soundEnabled: profile?.alarmSoundEnabled ?? true);
    }
  }

  /// Renomeia a tarefa. Se for azul com hábito, propaga o novo nome para todas as cópias
  /// ativas sem mexer no createdAt histórico.
  Future<void> renameTask(int taskId, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task == null) return;
      task.text = trimmed;
      await _isar.tasks.put(task);

      if (task.color == TaskColor.blue && task.habitId != null) {
        final siblings = await _isar.tasks
            .filter()
            .habitIdEqualTo(task.habitId!)
            .isRecurrenceActiveEqualTo(true)
            .findAll();
        for (final s in siblings) {
          s.text = trimmed;
        }
        if (siblings.isNotEmpty) {
          await _isar.tasks.putAll(siblings);
        }
      }
    });
  }

  /// Vincula imagem à tarefa e apaga arquivo anterior se existir
  Future<void> attachTaskImage(int taskId, String fileName) async {
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task == null) return;
      if (task.imageFileName != null && task.imageFileName != fileName) {
        await ImageService.deleteImage(task.imageFileName!);
      }
      task.imageFileName = fileName;
      task.hasImage = true;
      await _isar.tasks.put(task);
    });
  }

  /// Registra conclusão de foco Pomodoro com incremento seguro e XP
  Future<void> recordFocusSession(int taskId) async {
    final task = await _isar.tasks.get(taskId);
    if (task == null) return;
    await _isar.writeTxn(() async {
      task.focusCount++;
      await _isar.tasks.put(task);
    });
    await _xp.addXp(8, 'Sessão de foco concluída 🎯 (${task.text})');
  }

  /// Atualiza tarefa do backlog de fim de semana
  Future<void> updateWeekendTask(int taskId, String text, List<String> subtaskTexts) async {
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task == null) return;
      task.text = text.trim();
      for (int i = 0; i < task.subtasks.length && i < subtaskTexts.length; i++) {
        final subText = subtaskTexts[i].trim();
        if (subText.isNotEmpty) {
          task.subtasks[i].text = subText;
        }
      }
      await _isar.tasks.put(task);
    });
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
        if (t.hasAlarm || t.color == TaskColor.red) {
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
      await AlarmService.cancelAllForTask(taskId);
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
    Set<String> alreadyPropagatedHabitIds,
  ) async {
    final allBlueTasks = await _isar.tasks
        .filter()
        .colorEqualTo(TaskColor.blue)
        .isRecurrenceActiveEqualTo(true)
        .findAll();

    final Map<DivisionType, List<Task>> result = {
      DivisionType.morning: [],
      DivisionType.afternoon: [],
      DivisionType.night: [],
    };

    if (allBlueTasks.isEmpty) return result;

    // Agrupar por habitId (ou texto se habitId for nulo)
    final Map<String, Task> latestTaskMap = {};
    for (final t in allBlueTasks) {
      final key = t.habitId ?? t.text.trim().toLowerCase();
      final existing = latestTaskMap[key];
      if (existing == null || t.id > existing.id) {
        latestTaskMap[key] = t;
      }
    }

    for (final entry in latestTaskMap.entries) {
      final key = entry.key;
      final latestTask = entry.value;

      // Evita duplicidade se já foi propagada na rotina
      if (alreadyPropagatedHabitIds.contains(key) ||
          (latestTask.habitId != null && alreadyPropagatedHabitIds.contains(latestTask.habitId!))) {
        continue;
      }

      if (!BlueCadence.isEligibleOn(latestTask, today)) continue;

      // Encontrar a divisão mais recente onde este hábito esteve
      DivisionType targetDivision = DivisionType.morning;
      final parentDay = await _isar.routineDays
          .filter()
          .tasks((q) => q.idEqualTo(latestTask.id))
          .findFirst();
      if (parentDay != null && parentDay.division != DivisionType.tomorrow) {
        targetDivision = parentDay.division;
      }

      result[targetDivision]!.add(latestTask);
    }

    return result;
  }

  /// Re-agenda alarmes para a janela de próximos dias de todos os hábitos azuis ativos
  Future<void> refreshAllHabitAlarms() async {
    final habits = await getAllActiveBlueHabits();
    final profile = await _isar.userProfiles.get(1);
    final soundEnabled = profile?.alarmSoundEnabled ?? true;
    for (final h in habits) {
      await AlarmService.refreshHabitAlarms(
        h,
        includeToday: false, // rotina de hoje tem os alarmes das tasks de hoje
        soundEnabled: soundEnabled,
      );
    }
  }

  /// Localiza a task correspondente a um hábito na rotina de hoje
  Future<Task?> resolveHabitTaskForToday(String habitId, {bool createIfMissing = false}) async {
    final todayRoutine = await findTodayRoutine();
    if (todayRoutine != null) {
      await todayRoutine.days.load();
      for (final day in todayRoutine.days) {
        await day.tasks.load();
        for (final t in day.tasks) {
          if (t.habitId == habitId) return t;
        }
      }
    }
    if (createIfMissing) {
      final r = await createRoutine();
      await r.days.load();
      for (final day in r.days) {
        await day.tasks.load();
        for (final t in day.tasks) {
          if (t.habitId == habitId) return t;
        }
      }
    }
    return null;
  }

  Task _copyTask(Task src, TaskColor color, DateTime targetDate) {
    DateTime? newAlarmTime;
    bool newAlarmRepeat = src.alarmRepeat;

    if (src.alarmTime != null) {
      newAlarmTime = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        src.alarmTime!.hour,
        src.alarmTime!.minute,
      );
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
      ..color = src.isWeekendTask ? TaskColor.standard : color
      ..status = newStatus
      ..scheduledDate = src.scheduledDate
      ..completedOnDate = newCompletedOnDate
      ..imageFileName = src.imageFileName
      ..frequency = src.frequency
      ..frequencyDays = List<int>.from(src.frequencyDays)
      ..lastAppearedDate = src.lastAppearedDate
      ..isRecurrenceActive = src.isRecurrenceActive
      ..recurrenceEndDate = src.recurrenceEndDate
      ..isWeekendTask = false
      ..weekendOriginId = src.isWeekendTask ? (src.weekendOriginId ?? src.id) : null
      ..hasImage = src.hasImage
      ..hasSubtasks = src.hasSubtasks
      ..habitId = src.habitId
      ..cadenceAnchor = src.cadenceAnchor
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

  // ── Gestão Semanal de Tasks Azuis (A partir do dia atual) ────
  /// Retorna a lista de hábitos azuis ativos para exibição no gerenciador.
  /// Deduplica por `habitId` (com fallback para texto normalizado).
  Future<List<Task>> getAllActiveBlueHabits() async {
    final allBlue = await _isar.tasks
        .filter()
        .colorEqualTo(TaskColor.blue)
        .isRecurrenceActiveEqualTo(true)
        .findAll();

    final Map<String, Task> result = {};
    for (final t in allBlue) {
      final key = t.habitId ?? t.text.trim().toLowerCase();
      final existing = result[key];
      if (existing == null || t.id > existing.id) {
        result[key] = t;
      }
    }

    final list = result.values.toList();
    list.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
    return list;
  }

  Future<void> updateBlueHabit({
    required int sampleTaskId,
    required String newText,
    required FrequencyType newFrequency,
    required List<int> newDays,
  }) async {
    final sample = await _isar.tasks.get(sampleTaskId);
    if (sample == null) return;
    final habitId = sample.habitId;
    final oldText = sample.text.trim().toLowerCase();

    final allBlue = await _isar.tasks
        .filter()
        .colorEqualTo(TaskColor.blue)
        .findAll();

    final toUpdate = allBlue.where((t) {
      if (habitId != null && t.habitId == habitId) return true;
      return t.text.trim().toLowerCase() == oldText;
    }).toList();

    await _isar.writeTxn(() async {
      for (final t in toUpdate) {
        t.text = newText.trim();
        t.frequency = newFrequency;
        t.frequencyDays = List<int>.from(newDays);
        await _isar.tasks.put(t);
      }
    });

    if (toUpdate.isNotEmpty) {
      final profile = await _isar.userProfiles.get(1);
      final soundEnabled = profile?.alarmSoundEnabled ?? true;
      await AlarmService.refreshHabitAlarms(
        toUpdate.last,
        includeToday: false,
        soundEnabled: soundEnabled,
      );
    }
  }

  Future<void> terminateBlueHabitFromToday(int sampleTaskId) async {
    final sample = await _isar.tasks.get(sampleTaskId);
    if (sample == null) return;
    final habitId = sample.habitId;
    final textLower = sample.text.trim().toLowerCase();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (habitId != null) {
      await AlarmService.cancelHabitAlarms(habitId);
    }

    final allBlue = await _isar.tasks
        .filter()
        .colorEqualTo(TaskColor.blue)
        .findAll();

    final toDeactivate = allBlue.where((t) {
      if (habitId != null && t.habitId == habitId) return true;
      return t.text.trim().toLowerCase() == textLower;
    }).toList();

    await _isar.writeTxn(() async {
      for (final t in toDeactivate) {
        t.isRecurrenceActive = false;
        t.recurrenceEndDate = today;
        await _isar.tasks.put(t);
      }
    });

    // Remover da rotina de hoje se não concluída
    final todayRoutine = await _isar.routines.filter().dateEqualTo(today).findFirst();
    if (todayRoutine != null) {
      await todayRoutine.days.load();
      for (final day in todayRoutine.days) {
        await day.tasks.load();
        final toRemove = day.tasks.where((t) {
          final matches = (habitId != null && t.habitId == habitId) ||
              t.text.trim().toLowerCase() == textLower;
          return t.color == TaskColor.blue && matches && t.status != TaskStatus.completed;
        }).toList();

        for (final rem in toRemove) {
          day.tasks.remove(rem);
          await AlarmService.cancelAllForTask(rem.id);
          await _isar.writeTxn(() async => await _isar.tasks.delete(rem.id));
        }
        if (toRemove.isNotEmpty) {
          await _isar.writeTxn(() async => await day.tasks.save());
        }
      }
    }
  }

  // ── Backlog de Tasks de Fim de Semana (Aba Escondida) ───────
  /// Retorna as tarefas do backlog do FDS (mantém concluídas riscadas para o usuário ver)
  Future<List<Task>> getWeekendBacklogTasks() async {
    return await _isar.tasks
        .filter()
        .isWeekendTaskEqualTo(true)
        .weekendOriginIdIsNull()
        .findAll();
  }

  Future<Task> addWeekendTask(String text) async {
    final task = Task()
      ..text = text.trim()
      ..createdAt = DateTime.now()
      ..color = TaskColor.standard
      ..status = TaskStatus.active
      ..isWeekendTask = true;

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });
    return task;
  }

  Future<void> moveToWeekendBacklog(int taskId) async {
    await AlarmService.cancelAllForTask(taskId);

    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task == null) return;

      final parentDay = await _isar.routineDays
          .filter()
          .tasks((q) => q.idEqualTo(taskId))
          .findFirst();

      if (parentDay != null) {
        await parentDay.tasks.load();
        parentDay.tasks.remove(task);
        await parentDay.tasks.save();
      }

      task.isWeekendTask = true;
      task.color = TaskColor.standard;
      task.status = TaskStatus.active;
      task.alarmTime = null;
      task.alarmRepeat = false;
      task.alarmFullScreen = false;
      await _isar.tasks.put(task);
    });
  }

  Future<void> deleteWeekendTask(int taskId) async {
    await AlarmService.cancelAllForTask(taskId);
    await _isar.writeTxn(() async {
      final task = await _isar.tasks.get(taskId);
      if (task != null) {
        final parentDay = await _isar.routineDays
            .filter()
            .tasks((q) => q.idEqualTo(taskId))
            .findFirst();
        if (parentDay != null) {
          await parentDay.tasks.load();
          parentDay.tasks.remove(task);
          await parentDay.tasks.save();
        }
        await _isar.tasks.delete(taskId);
      }
    });
  }
}

