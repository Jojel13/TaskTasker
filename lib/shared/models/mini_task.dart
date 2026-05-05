import 'package:isar/isar.dart';
import 'enums.dart';

part 'mini_task.g.dart';

/// Nível 3 do TaskTree — inline abaixo da Subtask
@Embedded()
class MiniTask {
  late String text;
  bool isCompleted = false;
  DateTime? completedAt;
  int sortOrder = 0;
}
