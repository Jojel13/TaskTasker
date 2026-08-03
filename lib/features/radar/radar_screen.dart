import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/routine.dart';
import '../routine/widgets/task_card.dart';
import '../routine/routine_screen.dart';

class RadarScreen extends ConsumerWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final radarTasksAsync = ref.watch(radarProvider);

    return radarTasksAsync.when(
      data: (tasks) {
        final redTasks = tasks.where((t) => t.task.color == TaskColor.red).toList();
        final yellowTasks = tasks.where((t) => t.task.color == TaskColor.yellow).toList();

        redTasks.sort((a, b) =>
            (a.task.scheduledDate ?? DateTime.now()).compareTo(b.task.scheduledDate ?? DateTime.now()));
        yellowTasks.sort((a, b) => a.task.createdAt.compareTo(b.task.createdAt));

        // ── Calcula as cores do degradê baseadas na proporção ────
        final int total = redTasks.length + yellowTasks.length;
        final double redRatio = total == 0 ? 0.0 : redTasks.length / total;

        final Color topColor;
        final Color midColor;
        final Color bottomColor = theme.background;

        final redTop = Color.lerp(theme.background, theme.taskRed, 0.35)!;
        final redMid = Color.lerp(theme.background, theme.taskRed, 0.15)!;
        final yellowTop = Color.lerp(theme.background, theme.taskYellow, 0.30)!;
        final yellowMid = Color.lerp(theme.background, theme.taskYellow, 0.12)!;

        if (total == 0) {
          topColor = theme.background;
          midColor = theme.background;
        } else if (redTasks.isNotEmpty && yellowTasks.isEmpty) {
          topColor = redTop;
          midColor = redMid;
        } else if (redTasks.isEmpty && yellowTasks.isNotEmpty) {
          topColor = yellowTop;
          midColor = yellowMid;
        } else {
          topColor = Color.lerp(yellowTop, redTop, redRatio)!;
          midColor = Color.lerp(yellowMid, redMid, redRatio)!;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: total == 0
                  ? [theme.background, theme.background, theme.background]
                  : [topColor, midColor, bottomColor],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),

          child: SafeArea(
            child: tasks.isEmpty
                ? _buildEmpty(theme)
                : CustomScrollView(
                    slivers: [
                      // ── Header ──────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RADAR', style: theme.fontStyleBase(AppTextStyles.displayMedium).copyWith(
                                color: theme.textPrimary,
                                letterSpacing: 4,
                              )),
                              const SizedBox(height: 4),
                              Text(
                                '${redTasks.length} eminentes · ${yellowTasks.length} pendentes',
                                style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(
                                  color: redRatio > 0.5 ? theme.taskRed : theme.taskYellow,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (total > 0) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Row(
                                    children: [
                                      if (redTasks.isNotEmpty)
                                        Flexible(
                                          flex: redTasks.length,
                                          child: Container(
                                            height: 3,
                                            color: theme.taskRed.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      if (yellowTasks.isNotEmpty)
                                        Flexible(
                                          flex: yellowTasks.length,
                                          child: Container(
                                            height: 3,
                                            color: theme.taskYellow.withValues(alpha: 0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // ── Hint de navegação ────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.surface.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(theme.borderRadius > 8 ? 8 : theme.borderRadius),
                              border: Border.all(color: theme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_rounded, size: 14, color: theme.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  'Segure um card para ir à rotina',
                                  style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Tasks Eminentes (Vermelhas) ──────────────────────
                      if (redTasks.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.taskRed,
                                    boxShadow: theme.useGlowBorder ? theme.glowShadow(theme.taskRed) : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'EMINENTES',
                                  style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(
                                    color: theme.taskRed,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _RadarTaskCard(taskInfo: redTasks[index]),
                            ),
                            childCount: redTasks.length,
                          ),
                        ),
                      ],

                      // ── Tasks Pendentes (Amarelas) ───────────────────────
                      if (yellowTasks.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.taskYellow,
                                    boxShadow: theme.useGlowBorder ? theme.glowShadow(theme.taskYellow) : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'PENDENTES',
                                  style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(
                                    color: theme.taskYellow,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _RadarTaskCard(taskInfo: yellowTasks[index]),
                            ),
                            childCount: yellowTasks.length,
                          ),
                        ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: theme.taskYellow)),
      error: (err, stack) => Center(
        child: Text('Erro: $err', style: theme.fontStyleBase(TextStyle(color: theme.taskRed))),
      ),
    );
  }

  Widget _buildEmpty(AppThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.surface,
              border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
              boxShadow: theme.useGlowBorder ? theme.glowShadow(theme.accent, intensity: 0.4) : null,
            ),
            child: Icon(Icons.radar, size: 40, color: theme.accent),
          ),
          const SizedBox(height: 20),
          Text('Radar Limpo!', style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.accent)),
          const SizedBox(height: 8),
          Text(
            'Nenhuma pendência\nou compromisso eminente.',
            textAlign: TextAlign.center,
            style: theme.fontStyleBase(AppTextStyles.bodySmall).copyWith(color: theme.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Card do Radar — somente leitura. LongPress navega para a rotina.
class _RadarTaskCard extends ConsumerWidget {
  final RadarTaskInfo taskInfo;
  const _RadarTaskCard({required this.taskInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _navigateToRoutine(context, ref),
      child: TaskCard(
        task: taskInfo.task,
        divisionName: taskInfo.divisionName,
        isReadOnly: true,
        showRadarInfo: true,
        onToggle: () {},
        onColorCycle: () {},
        onDelete: () {},
      ),
    );
  }

  Future<void> _navigateToRoutine(BuildContext context, WidgetRef ref) async {
    final isar = ref.read(isarProvider);

    // AVISO-05: O Radar sempre exibe tasks da rotina mais recente (latestRoutine),
    // portanto basta buscar essa única rotina — O(1) em vez de O(n*m).
    final latestRoutine = await isar.routines.where().sortByDateDesc().findFirst();

    if (latestRoutine == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineScreen(routine: latestRoutine, scrollToTaskId: taskInfo.task.id),
      ),
    );
  }
}
