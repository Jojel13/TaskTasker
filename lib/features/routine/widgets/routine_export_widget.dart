import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_config.dart';
import '../../../shared/models/routine.dart';
import '../../../shared/models/routine_day.dart';
import '../../../shared/models/enums.dart';

class RoutineExportWidget extends StatelessWidget {
  final Routine routine;
  final List<RoutineDay> days;
  final AppThemeData theme;

  const RoutineExportWidget({
    super.key,
    required this.routine,
    required this.days,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(routine.date);

    // Calcular progresso
    int totalTasks = 0;
    int completedTasks = 0;
    for (final day in days) {
      for (final t in day.tasks) {
        totalTasks++;
        if (t.status == TaskStatus.completed) {
          completedTasks++;
        }
      }
    }
    final double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    final int percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.background,
            theme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: theme.primary, width: 2.0),
        borderRadius: BorderRadius.circular(theme.borderRadius > 16 ? 16 : theme.borderRadius),
        boxShadow: theme.useGlowBorder ? theme.glowShadow(theme.primary, intensity: 0.3) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: theme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'TASKTASKER',
                    style: theme.fontStyleMono(TextStyle(
                      color: theme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    )),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'ROTINA',
                  style: theme.fontStyleMono(TextStyle(
                    color: theme.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Title & Date
          Text(
            routine.name,
            style: theme.fontStyleBase(TextStyle(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: theme.fontStyleBase(TextStyle(
              color: theme.textMuted,
              fontSize: 12,
            )),
          ),
          const SizedBox(height: 20),
          Divider(color: theme.border, height: 1),
          const SizedBox(height: 20),

          // Division and Tasks
          ...days.where((d) => d.tasks.isNotEmpty).map((day) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.customName.toUpperCase(),
                  style: theme.fontStyleMono(TextStyle(
                    color: theme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  )),
                ),
                const SizedBox(height: 8),
                ...day.tasks.map((task) {
                  final isDone = task.status == TaskStatus.completed;
                  final taskColor = switch (task.color) {
                    TaskColor.standard => theme.taskStandard,
                    TaskColor.blue => theme.taskBlue,
                    TaskColor.yellow => theme.taskYellow,
                    TaskColor.red => theme.taskRed,
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isDone 
                              ? Icons.check_box_rounded 
                              : Icons.check_box_outline_blank_rounded,
                          color: isDone ? theme.accent : taskColor.withValues(alpha: 0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.text,
                            style: theme.fontStyleBase(TextStyle(
                              color: isDone ? theme.textMuted : theme.textPrimary,
                              fontSize: 13,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            )),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),

          const SizedBox(height: 12),
          Divider(color: theme.border, height: 1),
          const SizedBox(height: 16),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso da Rotina',
                style: theme.fontStyleBase(TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                )),
              ),
              Text(
                '$completedTasks/$totalTasks ($percentage%)',
                style: theme.fontStyleMono(TextStyle(
                  color: theme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐸 ', style: TextStyle(fontSize: 14)),
                Text(
                  'Gerado pelo TaskTasker',
                  style: theme.fontStyleMono(TextStyle(
                    color: theme.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
