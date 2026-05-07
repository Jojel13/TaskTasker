import 'package:isar/isar.dart';
import 'routine_day.dart';

part 'routine.g.dart';

/// Uma rotina do usuário — agrupa as 4 divisões de um dia
@Collection()
class Routine {
  Id id = Isar.autoIncrement;

  /// Nome global da rotina (editável nas configurações)
  late String name;

  /// Data normalizada: yyyy-MM-dd 00:00:00 (sem hora)
  @Index()
  late DateTime date;

  late DateTime createdAt;

  final days = IsarLinks<RoutineDay>();
}
