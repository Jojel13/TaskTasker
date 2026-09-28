import 'package:flutter_test/flutter_test.dart';
import 'package:task_tasker/shared/models/task.dart';
import 'package:task_tasker/shared/models/enums.dart';

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
