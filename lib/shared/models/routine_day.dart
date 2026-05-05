import 'package:isar/isar.dart';
import 'enums.dart';
import 'task.dart';

part 'routine_day.g.dart';

/// Uma divisão da rotina: Manhã, Tarde, Noite ou Para Amanhã
@Collection()
class RoutineDay {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  late DivisionType division;

  /// Nome customizável da divisão (editável nas configurações)
  late String customName;

  final tasks = IsarLinks<Task>();
}
