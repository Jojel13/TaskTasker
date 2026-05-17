import 'package:isar/isar.dart';
import 'enums.dart';
import 'mini_task.dart';
import 'subtask.dart';

part 'task.g.dart';

/// Task principal — nível 1 do TaskTree
@Collection()
class Task {
  Id id = Isar.autoIncrement;

  late String text;
  late DateTime createdAt;
  int sortOrder = 0; // Alterado pelo drag & drop

  @Enumerated(EnumType.name)
  late TaskColor color;

  @Enumerated(EnumType.name)
  TaskStatus status = TaskStatus.active;

  // ─── Task Vermelha ───────────────────────────────────────────
  DateTime? scheduledDate;

  // ─── Task Amarela — controle de propagação ───────────────────
  // null = não concluída = propaga para próxima rotina
  DateTime? completedOnDate;

  // ─── Imagem (apenas nome do arquivo, não path completo) ──────
  String? imageFileName;

  // ─── Frequência (task azul) ──────────────────────────────────
  @Enumerated(EnumType.name)
  FrequencyType frequency = FrequencyType.daily;
  List<int> frequencyDays = []; // ISO weekdays: [1=seg ... 7=dom]
  DateTime? lastAppearedDate;

  // ─── Alarme Individual (Fase 3) ──────────────────────────────
  /// Horário do alarme. null = sem alarme.
  DateTime? alarmTime;

  /// Se true: dispara 3 notificações com intervalo de 5 min
  bool alarmRepeat = false;

  // ─── Cache para evitar queries extras no UI ──────────────────
  bool hasImage = false;
  bool hasSubtasks = false;

  // ─── Subtasks embedded ───────────────────────────────────────
  List<Subtask> subtasks = [];

  // ─── Getters computados (não persistidos) ────────────────────
  @ignore
  bool get hasAlarm => alarmTime != null;
}
