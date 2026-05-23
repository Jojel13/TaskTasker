import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../../shared/models/routine.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/task.dart';
import '../../shared/models/subtask.dart';
import '../../shared/models/mini_task.dart';
import '../../shared/models/user_profile.dart';
import '../../shared/models/xp_event.dart';
import '../../shared/models/enums.dart';

class BackupService {
  final Isar isar;
  BackupService(this.isar);

  // ── Serialization ──────────────────────────────────────────────────────────

  Map<String, dynamic> _taskToJson(Task task) {
    return {
      'id': task.id,
      'text': task.text,
      'createdAt': task.createdAt.toIso8601String(),
      'sortOrder': task.sortOrder,
      'color': task.color.name,
      'status': task.status.name,
      'scheduledDate': task.scheduledDate?.toIso8601String(),
      'completedOnDate': task.completedOnDate?.toIso8601String(),
      'imageFileName': task.imageFileName,
      'frequency': task.frequency.name,
      'frequencyDays': task.frequencyDays,
      'lastAppearedDate': task.lastAppearedDate?.toIso8601String(),
      'alarmTime': task.alarmTime?.toIso8601String(),
      'alarmRepeat': task.alarmRepeat,
      'hasImage': task.hasImage,
      'hasSubtasks': task.hasSubtasks,
      'subtasks': task.subtasks.map((s) => _subtaskToJson(s)).toList(),
    };
  }

  Map<String, dynamic> _subtaskToJson(Subtask sub) {
    return {
      'text': sub.text,
      'createdAt': sub.createdAt.toIso8601String(),
      'isCompleted': sub.isCompleted,
      'completedAt': sub.completedAt?.toIso8601String(),
      'sortOrder': sub.sortOrder,
      'miniTasks': sub.miniTasks.map((m) => _miniTaskToJson(m)).toList(),
    };
  }

  Map<String, dynamic> _miniTaskToJson(MiniTask mini) {
    return {
      'text': mini.text,
      'isCompleted': mini.isCompleted,
      'completedAt': mini.completedAt?.toIso8601String(),
      'sortOrder': mini.sortOrder,
    };
  }

  Map<String, dynamic> _routineDayToJson(RoutineDay day) {
    return {
      'id': day.id,
      'division': day.division.name,
      'customName': day.customName,
      'taskIds': day.tasks.map((t) => t.id).toList(),
    };
  }

  Map<String, dynamic> _routineToJson(Routine r) {
    return {
      'id': r.id,
      'name': r.name,
      'date': r.date.toIso8601String(),
      'createdAt': r.createdAt.toIso8601String(),
      'dayIds': r.days.map((d) => d.id).toList(),
    };
  }

  Map<String, dynamic> _userProfileToJson(UserProfile p) {
    return {
      'id': p.id,
      'routineName': p.routineName,
      'totalXP': p.totalXP,
      'currentLevel': p.currentLevel,
      'streakDays': p.streakDays,
      'streakRecord': p.streakRecord,
      'lastOpenedDate': p.lastOpenedDate?.toIso8601String(),
      'lastRoutineDate': p.lastRoutineDate?.toIso8601String(),
      'divisionMorningName': p.divisionMorningName,
      'divisionAfternoonName': p.divisionAfternoonName,
      'divisionNightName': p.divisionNightName,
      'divisionTomorrowName': p.divisionTomorrowName,
      'notifMorningOffsetMin': p.notifMorningOffsetMin,
      'notifAfternoonOffsetMin': p.notifAfternoonOffsetMin,
      'notifNightOffsetMin': p.notifNightOffsetMin,
      'notificationFrequencyHours': p.notificationFrequencyHours,
      'appTheme': p.appTheme.name,
    };
  }

  Map<String, dynamic> _xpEventToJson(XPEvent e) {
    return {
      'id': e.id,
      'earnedAt': e.earnedAt.toIso8601String(),
      'amount': e.amount,
      'description': e.description,
    };
  }

  // ── Deserialization ────────────────────────────────────────────────────────

  Task _taskFromJson(Map<String, dynamic> json) {
    final task = Task()
      ..id = json['id'] as int
      ..text = json['text'] as String
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..sortOrder = json['sortOrder'] as int
      ..color = TaskColor.values.byName(json['color'] as String)
      ..status = TaskStatus.values.byName(json['status'] as String)
      ..scheduledDate = json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate'] as String) : null
      ..completedOnDate = json['completedOnDate'] != null ? DateTime.parse(json['completedOnDate'] as String) : null
      ..imageFileName = json['imageFileName'] as String?
      ..frequency = FrequencyType.values.byName(json['frequency'] as String)
      ..frequencyDays = (json['frequencyDays'] as List).cast<int>()
      ..lastAppearedDate = json['lastAppearedDate'] != null ? DateTime.parse(json['lastAppearedDate'] as String) : null
      ..alarmTime = json['alarmTime'] != null ? DateTime.parse(json['alarmTime'] as String) : null
      ..alarmRepeat = json['alarmRepeat'] as bool
      ..hasImage = json['hasImage'] as bool
      ..hasSubtasks = json['hasSubtasks'] as bool;

    if (json['subtasks'] != null) {
      task.subtasks = (json['subtasks'] as List)
          .map((s) => _subtaskFromJson(s as Map<String, dynamic>))
          .toList();
    }
    return task;
  }

  Subtask _subtaskFromJson(Map<String, dynamic> json) {
    final sub = Subtask()
      ..text = json['text'] as String
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..isCompleted = json['isCompleted'] as bool
      ..completedAt = json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null
      ..sortOrder = json['sortOrder'] as int;

    if (json['miniTasks'] != null) {
      sub.miniTasks = (json['miniTasks'] as List)
          .map((m) => _miniTaskFromJson(m as Map<String, dynamic>))
          .toList();
    }
    return sub;
  }

  MiniTask _miniTaskFromJson(Map<String, dynamic> json) {
    return MiniTask()
      ..text = json['text'] as String
      ..isCompleted = json['isCompleted'] as bool
      ..completedAt = json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null
      ..sortOrder = json['sortOrder'] as int;
  }

  RoutineDay _routineDayFromJson(Map<String, dynamic> json) {
    return RoutineDay()
      ..id = json['id'] as int
      ..division = DivisionType.values.byName(json['division'] as String)
      ..customName = json['customName'] as String;
  }

  Routine _routineFromJson(Map<String, dynamic> json) {
    return Routine()
      ..id = json['id'] as int
      ..name = json['name'] as String
      ..date = DateTime.parse(json['date'] as String)
      ..createdAt = DateTime.parse(json['createdAt'] as String);
  }

  UserProfile _userProfileFromJson(Map<String, dynamic> json) {
    return UserProfile()
      ..id = json['id'] as int
      ..routineName = json['routineName'] as String
      ..totalXP = json['totalXP'] as int
      ..currentLevel = json['currentLevel'] as int
      ..streakDays = json['streakDays'] as int
      ..streakRecord = json['streakRecord'] as int
      ..lastOpenedDate = json['lastOpenedDate'] != null ? DateTime.parse(json['lastOpenedDate'] as String) : null
      ..lastRoutineDate = json['lastRoutineDate'] != null ? DateTime.parse(json['lastRoutineDate'] as String) : null
      ..divisionMorningName = json['divisionMorningName'] as String
      ..divisionAfternoonName = json['divisionAfternoonName'] as String
      ..divisionNightName = json['divisionNightName'] as String
      ..divisionTomorrowName = json['divisionTomorrowName'] as String
      ..notifMorningOffsetMin = json['notifMorningOffsetMin'] as int
      ..notifAfternoonOffsetMin = json['notifAfternoonOffsetMin'] as int
      ..notifNightOffsetMin = json['notifNightOffsetMin'] as int
      ..notificationFrequencyHours = json['notificationFrequencyHours'] as int
      ..appTheme = AppThemeType.values.byName(json['appTheme'] as String);
  }

  XPEvent _xpEventFromJson(Map<String, dynamic> json) {
    return XPEvent()
      ..id = json['id'] as int
      ..earnedAt = DateTime.parse(json['earnedAt'] as String)
      ..amount = json['amount'] as int
      ..description = json['description'] as String;
  }

  // ── Operations ─────────────────────────────────────────────────────────────

  /// Exporta o banco de dados inteiro em formato JSON em string
  Future<String> exportBackupData() async {
    final profile = await isar.userProfiles.get(1);
    final routines = await isar.routines.where().findAll();
    final routineDays = await isar.routineDays.where().findAll();
    
    // Para as tasks e xpevents, precisamos carregar e serializar
    final tasks = await isar.tasks.where().findAll();
    final xpEvents = await isar.xPEvents.where().findAll();

    final backup = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'userProfile': profile != null ? _userProfileToJson(profile) : null,
      'routines': routines.map((r) => _routineToJson(r)).toList(),
      'routineDays': routineDays.map((d) => _routineDayToJson(d)).toList(),
      'tasks': tasks.map((t) => _taskToJson(t)).toList(),
      'xpEvents': xpEvents.map((e) => _xpEventToJson(e)).toList(),
    };

    return jsonEncode(backup);
  }

  /// Gera o arquivo de backup e abre o popup de compartilhamento (Share) nativo do sistema
  Future<bool> shareBackupFile() async {
    try {
      final jsonString = await exportBackupData();
      final tempDir = await getTemporaryDirectory();
      final backupFile = File('${tempDir.path}/tasktasker_backup.json');
      await backupFile.writeAsString(jsonString);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          text: 'Backup do TaskTasker',
        ),
      );
      
      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }

  /// Restaura o banco de dados Isar a partir de uma string JSON
  Future<void> importBackupData(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    if (data['version'] == null) {
      throw const FormatException('Formato de backup inválido.');
    }

    final Map<String, dynamic>? profileJson = data['userProfile'];
    final List<dynamic>? routinesJson = data['routines'];
    final List<dynamic>? routineDaysJson = data['routineDays'];
    final List<dynamic>? tasksJson = data['tasks'];
    final List<dynamic>? xpEventsJson = data['xpEvents'];

    // Instancia os modelos
    final userProfile = profileJson != null ? _userProfileFromJson(profileJson) : null;
    final tasksList = tasksJson != null ? tasksJson.map((t) => _taskFromJson(t as Map<String, dynamic>)).toList() : <Task>[];
    final daysList = routineDaysJson != null ? routineDaysJson.map((d) => _routineDayFromJson(d as Map<String, dynamic>)).toList() : <RoutineDay>[];
    final routinesList = routinesJson != null ? routinesJson.map((r) => _routineFromJson(r as Map<String, dynamic>)).toList() : <Routine>[];
    final xpEventsList = xpEventsJson != null ? xpEventsJson.map((e) => _xpEventFromJson(e as Map<String, dynamic>)).toList() : <XPEvent>[];

    await isar.writeTxn(() async {
      // 1. Limpar todas as tabelas
      await isar.userProfiles.clear();
      await isar.routines.clear();
      await isar.routineDays.clear();
      await isar.tasks.clear();
      await isar.xPEvents.clear();

      // 2. Inserir os registros com os IDs originais
      if (userProfile != null) {
        await isar.userProfiles.put(userProfile);
      }
      if (tasksList.isNotEmpty) {
        await isar.tasks.putAll(tasksList);
      }
      if (daysList.isNotEmpty) {
        await isar.routineDays.putAll(daysList);
      }
      if (routinesList.isNotEmpty) {
        await isar.routines.putAll(routinesList);
      }
      if (xpEventsList.isNotEmpty) {
        await isar.xPEvents.putAll(xpEventsList);
      }
    });

    // 3. Reconstruir os relacionamentos (IsarLinks)
    await isar.writeTxn(() async {
      // RoutineDay -> Task
      if (routineDaysJson != null) {
        for (final dayJson in routineDaysJson) {
          final map = dayJson as Map<String, dynamic>;
          final dayId = map['id'] as int;
          final taskIds = (map['taskIds'] as List).cast<int>();
          final dayObj = await isar.routineDays.get(dayId);
          if (dayObj != null) {
            final tasks = await isar.tasks.getAll(taskIds);
            dayObj.tasks.addAll(tasks.whereType<Task>());
            await dayObj.tasks.save();
          }
        }
      }

      // Routine -> RoutineDay
      if (routinesJson != null) {
        for (final routineJson in routinesJson) {
          final map = routineJson as Map<String, dynamic>;
          final routineId = map['id'] as int;
          final dayIds = (map['dayIds'] as List).cast<int>();
          final routineObj = await isar.routines.get(routineId);
          if (routineObj != null) {
            final days = await isar.routineDays.getAll(dayIds);
            routineObj.days.addAll(days.whereType<RoutineDay>());
            await routineObj.days.save();
          }
        }
      }
    });
  }

  /// Abre o seletor de arquivos, lê o arquivo backup JSON e restaura os dados
  Future<bool> importBackupFromFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return false; // Cancelado
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      await importBackupData(content);
      return true;
    } catch (e) {
      return false;
    }
  }
}
