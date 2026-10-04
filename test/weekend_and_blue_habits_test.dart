import 'package:flutter_test/flutter_test.dart';
import 'package:task_tasker/shared/models/task.dart';
import 'package:task_tasker/shared/models/enums.dart';
import 'package:task_tasker/core/utils/blue_cadence.dart';
import 'package:task_tasker/core/utils/habit_id.dart';

void main() {
  group('Weekend & Blue Habits Model Tests', () {
    test('Task model has proper default values for weekend and recurrence', () {
      final task = Task()
        ..text = 'Test Task'
        ..color = TaskColor.standard
        ..sortOrder = 0;

      expect(task.isWeekendTask, isFalse);
      expect(task.isRecurrenceActive, isTrue);
      expect(task.recurrenceEndDate, isNull);
      expect(task.hasAlarm, isFalse);
      expect(task.habitId, isNull);
      expect(task.cadenceAnchor, isNull);
    });

    test('Task model supports weekend task marking and termination dates', () {
      final now = DateTime.now();
      final task = Task()
        ..text = 'Limpar a casa'
        ..color = TaskColor.standard
        ..isWeekendTask = true
        ..isRecurrenceActive = false
        ..recurrenceEndDate = now;

      expect(task.isWeekendTask, isTrue);
      expect(task.isRecurrenceActive, isFalse);
      expect(task.recurrenceEndDate, equals(now));
    });

    test('HabitIdGenerator generates unique IDs', () {
      final id1 = HabitIdGenerator.generate();
      final id2 = HabitIdGenerator.generate();
      expect(id1.isNotEmpty, isTrue);
      expect(id2.isNotEmpty, isTrue);
      expect(id1, isNot(equals(id2)));
    });

    test('BlueCadence computes eligibility accurately', () {
      final base = DateTime(2026, 10, 1);
      final task = Task()
        ..text = 'Hábito Cadência'
        ..color = TaskColor.blue
        ..createdAt = base
        ..cadenceAnchor = base
        ..isRecurrenceActive = true
        ..frequency = FrequencyType.everyOtherDay;

      // Dia 1 (diferença 0): elegível
      expect(BlueCadence.isEligibleOn(task, base), isTrue);
      // Dia 2 (diferença 1): não elegível
      expect(BlueCadence.isEligibleOn(task, base.add(const Duration(days: 1))), isFalse);
      // Dia 3 (diferença 2): elegível
      expect(BlueCadence.isEligibleOn(task, base.add(const Duration(days: 2))), isTrue);

      // Desativado
      task.isRecurrenceActive = false;
      expect(BlueCadence.isEligibleOn(task, base), isFalse);

      // Com recurrenceEndDate
      task.isRecurrenceActive = true;
      task.recurrenceEndDate = base.add(const Duration(days: 2));
      expect(BlueCadence.isEligibleOn(task, base.add(const Duration(days: 2))), isFalse);
    });

    test('Alarm anti-collision calculation generates valid non-colliding ranges', () {
      int notifId(int taskId, int slot) {
        return (100000 + (taskId.abs() % 200000) * 10 + slot) % 2147483647;
      }

      final id1_0 = notifId(42, 0);
      final id1_1 = notifId(42, 1);
      final id1_2 = notifId(42, 2);
      final id2_0 = notifId(43, 0);

      expect(id1_0, isNot(equals(id1_1)));
      expect(id1_1, isNot(equals(id1_2)));
      expect(id1_0, isNot(equals(id2_0)));
      expect(id1_0, greaterThan(100000));
    });
  });
}

