import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/routine_day.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';
import 'task_card.dart';
import 'task_input_field.dart';

class DivisionSection extends ConsumerWidget {
  final Routine routine;
  final RoutineDay day;
  final bool isToday;
  /// Mapa de GlobalKeys para permitir scroll-to-task a partir do Radar
  final Map<int, GlobalKey>? taskKeys;

  const DivisionSection({
    super.key,
    required this.routine,
    required this.day,
    this.isToday = true,
    this.taskKeys,
  });

  Color get _accentColor => switch (day.division) {
    DivisionType.morning   => AppColors.taskYellow,
    DivisionType.afternoon => AppColors.secondary,
    DivisionType.night     => AppColors.accent,
    DivisionType.tomorrow  => AppColors.textSecondary,
  };

  IconData get _iconData => switch (day.division) {
    DivisionType.morning   => Icons.wb_sunny_rounded,
    DivisionType.afternoon => Icons.wb_cloudy_rounded,
    DivisionType.night     => Icons.nightlight_round,
    DivisionType.tomorrow  => Icons.arrow_forward_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = day.tasks.toList()
      ..sort((a, b) => a.sortOrder != b.sortOrder
          ? a.sortOrder.compareTo(b.sortOrder)
          : a.createdAt.compareTo(b.createdAt));

    final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;

    Widget content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Division header ───────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
        child: Row(children: [
          Icon(_iconData, size: 14, color: _accentColor),
          const SizedBox(width: 8),
          Text(
            day.customName.toUpperCase(),
            style: TextStyle(
              color: _accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 0.5,
              color: _accentColor.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$completedCount/${tasks.length}',
            style: TextStyle(
              color: completedCount == tasks.length && tasks.isNotEmpty
                  ? _accentColor
                  : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ),

      // ── Task list ──────────────────────────────────────────────
      ...tasks.map((task) {
        // Registrar GlobalKey para scroll-to-task
        final gKey = GlobalKey();
        taskKeys?[task.id] = gKey;

        final card = TaskCard(
          key: ValueKey(task.id),
          task: task,
          isReadOnly: !isToday,
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
        );

        if (!isToday) {
          return SizedBox(key: gKey, child: card);
        }

        return LongPressDraggable<Task>(
          key: gKey,
          data: task,
          delay: const Duration(milliseconds: 400),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: Opacity(opacity: 0.85, child: card),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.2, child: card),
          child: card,
        );
      }),

      // ── Input field ────────────────────────────────────────────
      if (isToday)
        TaskInputField(
          onSubmit: (text) async {
            await ref.read(routineServiceProvider).addTask(day.id, text);
            ref.invalidate(routineDaysProvider(routine.id));
          },
        ),
    ]);

    if (!isToday) return content;

    return DragTarget<Task>(
      onAcceptWithDetails: (details) async {
        final task = details.data;
        await ref.read(routineServiceProvider).moveTaskToDay(task.id, day.id);
        ref.invalidate(routineDaysProvider(routine.id));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHovering
                ? _accentColor.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isHovering
                ? Border.all(color: _accentColor.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: content,
        );
      },
    );
  }
}
