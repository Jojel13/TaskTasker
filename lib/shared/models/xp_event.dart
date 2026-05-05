import 'package:isar/isar.dart';

part 'xp_event.g.dart';

/// Histórico de ganhos/perdas de XP
@Collection()
class XPEvent {
  Id id = Isar.autoIncrement;

  late DateTime earnedAt;
  late int amount; // Positivo = ganho, negativo = desconto
  late String description; // Ex: "Task azul concluída", "Streak 7 dias"
}
