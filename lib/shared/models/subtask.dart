import 'package:isar/isar.dart';
import 'mini_task.dart';

part 'subtask.g.dart';

/// Nível 2 do TaskTree
@Embedded()
class Subtask {
  late String text;
  late DateTime createdAt;
  bool isCompleted = false;
  DateTime? completedAt; // Para exibir tempo de conclusão
  int sortOrder = 0;

  // Sub-subtasks (nível 3 — "taskmenores", inline com indentação)
  List<MiniTask> miniTasks = [];
}
