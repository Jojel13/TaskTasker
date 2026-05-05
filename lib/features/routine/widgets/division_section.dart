import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/routine_day.dart';
import '../../../shared/models/enums.dart';
import 'task_card.dart';
import 'task_input_field.dart';

class DivisionSection extends ConsumerWidget {
  final Routine routine;
  final RoutineDay day;

  const DivisionSection({
    super.key,
    required this.routine,
    required this.day,
  });

  Color get _accentColor => switch (day.division) {
    DivisionType.morning   => AppColors.taskYellow,
    DivisionType.afternoon => AppColors.primary,
    DivisionType.night     => AppColors.secondary,
    DivisionType.tomorrow  => AppColors.accent,
  };

  String get _icon => switch (day.division) {
    DivisionType.morning   => '☀️',
    DivisionType.afternoon => '🌤️',
    DivisionType.night     => '🌙',
    DivisionType.tomorrow  => '➡️',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = day.tasks.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Division header ───────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
        child: Row(children: [
          Text(_icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(day.customName.toUpperCase(),
              style: TextStyle(
                color: _accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              )),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: _accentColor.withOpacity(0.3), height: 1)),
          const SizedBox(width: 8),
          Text('${tasks.where((t) => t.status == TaskStatus.completed).length}/${tasks.length}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      ),

      // ── Task list ─────────────────────────────────────────
      ...tasks.map((task) => TaskCard(
            key: ValueKey(task.id),
            task: task,
            onToggle: () async {
              await ref.read(routineServiceProvider).toggleTask(task);
              ref.invalidate(routineDaysProvider(routine.id));
            },
            onColorCycle: () async {
              await ref.read(routineServiceProvider).cycleColor(task);
              ref.invalidate(routineDaysProvider(routine.id));
            },
            onDelete: () async {
              await ref.read(routineServiceProvider).deleteTask(day.id, task.id);
              ref.invalidate(routineDaysProvider(routine.id));
            },
          )),

      // ── Input field ───────────────────────────────────────
      TaskInputField(
        onSubmit: (text) async {
          await ref.read(routineServiceProvider).addTask(day.id, text);
          ref.invalidate(routineDaysProvider(routine.id));
        },
      ),
    ]);
  }
}
