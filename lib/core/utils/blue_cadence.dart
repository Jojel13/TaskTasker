import '../../shared/models/task.dart';
import '../../shared/models/enums.dart';

/// Regras de cadência de hábitos azuis, compartilhadas entre a geração de
/// rotinas e o agendamento antecipado de alarmes.
class BlueCadence {
  BlueCadence._();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Âncora usada para a cadência "dia sim, dia não".
  static DateTime anchorOf(Task t) => _day(t.cadenceAnchor ?? t.createdAt);

  /// Indica se o hábito [t] deve aparecer no dia [day].
  static bool isEligibleOn(Task t, DateTime day) {
    final d = _day(day);
    if (!t.isRecurrenceActive) return false;
    if (t.recurrenceEndDate != null && !d.isBefore(_day(t.recurrenceEndDate!))) {
      return false;
    }
    switch (t.frequency) {
      case FrequencyType.daily:
        return true;
      case FrequencyType.everyOtherDay:
        final diff = d.difference(anchorOf(t)).inDays;
        return diff % 2 == 0;
      case FrequencyType.custom:
        return t.frequencyDays.contains(d.weekday);
    }
  }
}
