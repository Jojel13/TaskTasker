import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_config.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/routine_day.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/blur_confirm_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoutineCard extends ConsumerStatefulWidget {
  final Routine routine;
  final List<RoutineDay> days;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.days,
    required this.isToday,
    required this.onTap,
    required this.onDelete,
  });

  @override
  ConsumerState<RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends ConsumerState<RoutineCard> {
  bool _expanded = false;

  List<Task> _allTasks() => widget.days.todayTasks;

  double _progress() {
    final tasks = _allTasks();
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.status == TaskStatus.completed).length;
    return done / tasks.length;
  }

  Set<TaskColor> _colors() =>
      _allTasks().map((t) => t.color).toSet();

  Color _colorDot(TaskColor c, AppThemeData theme) => switch (c) {
    TaskColor.standard => theme.taskStandard,
    TaskColor.blue     => theme.taskBlue,
    TaskColor.yellow   => theme.taskYellow,
    TaskColor.red      => theme.taskRed,
  };

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => BlurConfirmDialog(
        title: 'Apagar Rotina',
        message: 'Deseja apagar esta rotina permanentemente?',
        confirmLabel: 'Apagar',
        onConfirm: widget.onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final date = widget.routine.date;
    final dateStr = DateFormat('EEEE, dd MMM', 'pt_BR').format(date).toUpperCase();
    final progress = _progress();
    final tasks = _allTasks();
    final colors = _colors();

    if (!widget.isToday) {
      return GestureDetector(
        onLongPress: _showDeleteDialog,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(theme.borderRadius > 10 ? 10 : theme.borderRadius),
            border: Border.all(color: theme.border, width: 0.5),
          ),
          child: Row(
            children: [
              Text(
                dateStr, 
                style: theme.fontStyleMono(const TextStyle(
                  color: Colors.grey, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w500, 
                  letterSpacing: 0.5
                )).copyWith(color: theme.textSecondary)
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.routine.name, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: theme.fontStyleBase(const TextStyle(
                    fontSize: 13
                  )).copyWith(color: theme.textMuted)
                ),
              ),
              if (colors.isNotEmpty) ...[
                ...colors.map((c) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _colorDot(c, theme)),
                    )),
                const SizedBox(width: 12),
              ],
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: theme.textMuted),
            ],
          ),
        ),
      ).animate(key: ValueKey('anim_r_${widget.routine.id}')).fade(duration: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
    }

    return GestureDetector(
      onLongPress: _showDeleteDialog,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(
            color: widget.isToday
                ? theme.primary
                : theme.border,
            width: widget.isToday ? 1.5 : 0.5,
          ),
          boxShadow: widget.isToday
              ? theme.glowShadow(theme.primary, intensity: 0.3)
              : null,
        ),
        child: Column(children: [
          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    dateStr,
                    style: theme.fontStyleMono(const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2
                    )).copyWith(color: theme.textSecondary)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.routine.name,
                    style: theme.fontStyleBase(const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600
                    )).copyWith(color: theme.textPrimary)
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: theme.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isToday ? theme.primary : theme.primaryDim),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(
                      '${tasks.where((t) => t.status == TaskStatus.completed).length}/${tasks.length} tasks',
                      style: theme.fontStyleMono(const TextStyle(fontSize: 11)).copyWith(color: theme.textMuted)
                    ),
                    const SizedBox(width: 10),
                    ...colors.map((c) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _colorDot(c, theme)),
                        )),
                  ]),
                ]),
              ),
              // Expand + Navigate buttons
              Column(children: [
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded,
                      size: 18, color: theme.primary),
                  onPressed: widget.onTap,
                ),
                IconButton(
                  icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: theme.textMuted),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ]),
            ]),
          ),

          // ── Expanded tasks preview ─────────────────────────
          if (_expanded) ...[
            Divider(color: theme.divider, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.days
                    .where((d) => d.tasks.isNotEmpty)
                    .map((d) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.customName,
                              style: theme.fontStyleMono(const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.1)).copyWith(color: theme.primary)
                            ),
                            const SizedBox(height: 4),
                            ...d.tasks.take(3).map((t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(children: [
                                    Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _colorDot(t.color, theme))),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        t.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.fontStyleBase(TextStyle(
                                            fontSize: 13,
                                            decoration: t.status == TaskStatus.completed
                                                ? TextDecoration.lineThrough
                                                : null)).copyWith(
                                                  color: t.status == TaskStatus.completed
                                                      ? theme.textMuted
                                                      : theme.textSecondary,
                                                )
                                      ),
                                    ),
                                  ]),
                                )),
                            if (d.tasks.length > 3)
                              Text(
                                '+${d.tasks.length - 3} mais',
                                style: theme.fontStyleMono(const TextStyle(fontSize: 11)).copyWith(color: theme.textMuted)
                              ),
                            const SizedBox(height: 8),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
        ]),
      ),
    ).animate(key: ValueKey('anim_r_today_${widget.routine.id}')).fade(duration: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}
