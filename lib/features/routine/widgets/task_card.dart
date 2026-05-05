import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onColorCycle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onColorCycle,
    required this.onDelete,
  });

  Color get _taskColor => switch (task.color) {
    TaskColor.standard => AppColors.taskStandard,
    TaskColor.blue     => AppColors.taskBlue,
    TaskColor.yellow   => AppColors.taskYellow,
    TaskColor.red      => AppColors.taskRed,
  };

  bool get _isDone => task.status == TaskStatus.completed;
  bool get _isLocked => task.color == TaskColor.red &&
      task.scheduledDate != null &&
      task.scheduledDate!.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(task.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.taskRed.withOpacity(0.15),
            foregroundColor: AppColors.taskRed,
            icon: Icons.delete_outline_rounded,
            label: 'Apagar',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDone
                ? AppColors.border
                : _taskColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(children: [
          // ── Color dot (tappable) ────────────────────────
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLocked ? null : onColorCycle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isDone ? AppColors.textMuted : _taskColor,
                boxShadow: _isDone
                    ? null
                    : AppColors.glowShadow(_taskColor, intensity: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Task text ───────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                task.text,
                style: TextStyle(
                  color: _isDone ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: 14,
                  decoration: _isDone ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textMuted,
                ),
              ),
            ),
          ),

          // ── Countdown badge (red task) ──────────────────
          if (task.color == TaskColor.red && task.scheduledDate != null)
            _CountdownBadge(scheduledDate: task.scheduledDate!),

          // ── Checkbox ────────────────────────────────────
          GestureDetector(
            onTap: _isLocked ? null : onToggle,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDone ? _taskColor.withOpacity(0.2) : Colors.transparent,
                  border: Border.all(
                    color: _isLocked ? AppColors.textMuted : _taskColor,
                    width: 1.5,
                  ),
                  boxShadow: _isDone
                      ? AppColors.glowShadow(_taskColor, intensity: 0.5)
                      : null,
                ),
                child: _isDone
                    ? Icon(Icons.check, size: 14, color: _taskColor)
                    : null,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final DateTime scheduledDate;
  const _CountdownBadge({required this.scheduledDate});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final diff = scheduledDate
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final label = diff == 0 ? 'Hoje!' : '${diff}d';
    final isToday = diff == 0;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.taskRed.withOpacity(isToday ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppColors.taskRed.withOpacity(isToday ? 0.8 : 0.4),
            width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              color: AppColors.taskRed,
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.normal)),
    );
  }
}
