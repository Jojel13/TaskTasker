import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_config.dart';
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

  Color _accentColor(AppThemeData theme) => switch (day.division) {
    DivisionType.morning   => theme.taskYellow,
    DivisionType.afternoon => theme.secondary,
    DivisionType.night     => theme.accent,
    DivisionType.tomorrow  => theme.textSecondary,
  };

  IconData get _iconData => switch (day.division) {
    DivisionType.morning   => Icons.wb_sunny_rounded,
    DivisionType.afternoon => Icons.wb_cloudy_rounded,
    DivisionType.night     => Icons.nightlight_round,
    DivisionType.tomorrow  => Icons.arrow_forward_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final accent = _accentColor(theme);

    final tasks = day.tasks.toList()
      ..sort((a, b) => a.sortOrder != b.sortOrder
          ? a.sortOrder.compareTo(b.sortOrder)
          : a.createdAt.compareTo(b.createdAt));

    final completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;

    final children = <Widget>[];

    // ── Division header ───────────────────────────────────────
    children.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 10),
        child: Row(children: [
          Icon(_iconData, size: 14, color: accent),
          const SizedBox(width: 8),
          Text(
            day.customName.toUpperCase(),
            style: theme.fontStyleBase(TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 0.5,
              color: accent.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$completedCount/${tasks.length}',
            style: theme.fontStyleMono(TextStyle(
              color: completedCount == tasks.length && tasks.isNotEmpty
                  ? accent
                  : theme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            )),
          ),
        ]),
      ),
    );

    // ── Task list ──────────────────────────────────────────────
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      Key dragKey;
      if (taskKeys != null) {
        taskKeys![task.id] ??= GlobalKey();
        dragKey = taskKeys![task.id]!;
      } else {
        dragKey = ValueKey('drag_${task.id}');
      }

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
        children.add(
          SizedBox(key: dragKey, child: card)
              .animate(delay: Duration(milliseconds: i * 40))
              .fade(duration: 150.ms)
              .slideX(begin: 0.03, end: 0),
        );
        continue;
      }

      final draggable = LongPressDraggable<Task>(
        key: dragKey,
        data: task,
        delay: const Duration(milliseconds: 300),
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 40,
            child: Opacity(opacity: 0.85, child: card),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.2, child: card),
        onDragStarted: () => ref.read(isDraggingTaskProvider.notifier).state = true,
        onDragEnd: (_) => ref.read(isDraggingTaskProvider.notifier).state = false,
        onDraggableCanceled: (velocity, offset) => ref.read(isDraggingTaskProvider.notifier).state = false,
        child: card,
      );

      children.add(DragTarget<Task>(
        onWillAcceptWithDetails: (details) => details.data.id != task.id,
        onAcceptWithDetails: (details) async {
          final droppedTask = details.data;
          final oldIndex = tasks.indexWhere((t) => t.id == droppedTask.id);
          if (oldIndex != -1) {
            await ref.read(routineServiceProvider).reorderTasks(day.id, oldIndex, i);
          } else {
            await ref.read(routineServiceProvider).moveTaskToDay(droppedTask.id, day.id);
          }
          ref.invalidate(routineDaysProvider(routine.id));
        },
        builder: (context, candidateData, _) {
          final isHovering = candidateData.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isHovering)
                Container(
                  height: 56, // Tamanho aproximado de um card fechado
                  margin: const EdgeInsets.only(bottom: 6, top: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    border: Border.all(color: accent, width: 1.5, strokeAlign: BorderSide.strokeAlignOutside),
                    borderRadius: BorderRadius.circular(theme.borderRadius),
                  ),
                ),
              draggable,
            ],
          );
        },
      ).animate(delay: Duration(milliseconds: i * 40))
       .fade(duration: 150.ms)
       .slideX(begin: 0.03, end: 0));
    }

    // ── Input field ────────────────────────────────────────────
    if (isToday) {
      children.add(
        TaskInputField(
          onSubmit: (text) async {
            await ref.read(routineServiceProvider).addTask(day.id, text);
            ref.invalidate(routineDaysProvider(routine.id));
          },
        ),
      );
    }

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    if (!isToday) return content;

    return DragTarget<Task>(
      // BUG-17: aceitar apenas tasks que n\u00e3o s\u00e3o o \u00fanico elemento sendo arrastado
      // para si mesmo (sem mover) ou que vem de outra divis\u00e3o
      onWillAcceptWithDetails: (details) {
        final task = details.data;
        // Aceitar se vem de outra divis\u00e3o
        final isFromThisDay = tasks.any((t) => t.id == task.id);
        if (!isFromThisDay) return true;
        // Aceitar reordenação apenas se houver mais de 1 task
        return tasks.length > 1;
      },
      onAcceptWithDetails: (details) async {
        final task = details.data;
        final oldIndex = tasks.indexWhere((t) => t.id == task.id);
        if (oldIndex != -1) {
          // Soltou no final da própria divisão
          await ref.read(routineServiceProvider).reorderTasks(day.id, oldIndex, tasks.length);
        } else {
          // Veio de outra divisão
          await ref.read(routineServiceProvider).moveTaskToDay(task.id, day.id);
        }
        ref.invalidate(routineDaysProvider(routine.id));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHovering
                ? accent.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(theme.borderRadius),
            border: isHovering
                ? Border.all(color: accent.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: content,
        );
      },
    );
  }
}
