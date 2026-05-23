import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/routine.dart';
import '../routine/widgets/task_card.dart';
import '../routine/routine_screen.dart';

class RadarScreen extends ConsumerWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        const Color bottomColor = Color(0xFF070B14); // AppColors.background

        if (total == 0) {
          topColor = AppColors.background;
          midColor = AppColors.background;
        } else if (redTasks.isNotEmpty && yellowTasks.isEmpty) {
          // Full Vermelho
          topColor = const Color(0xFF4C0E0E); // Vermelho cyber profundo
          midColor = const Color(0xFF1E0505);
        } else if (redTasks.isEmpty && yellowTasks.isNotEmpty) {
          // Full Amarelo
          topColor = const Color(0xFF362A00); // Amarelo cyber profundo
          midColor = const Color(0xFF1C1600);
        } else {
          // Interpolação inteligente
          final redTop = const Color(0xFF4C0E0E);
          final yellowTop = const Color(0xFF362A00);
          final redMid = const Color(0xFF1E0505);
          final yellowMid = const Color(0xFF1C1600);
          
          topColor = Color.lerp(yellowTop, redTop, redRatio)!;
          midColor = Color.lerp(yellowMid, redMid, redRatio)!;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: total == 0
                  ? [AppColors.background, AppColors.background, AppColors.background]
                  : [topColor, midColor, bottomColor],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),

          child: SafeArea(
            child: tasks.isEmpty
                ? _buildEmpty()
                : CustomScrollView(
                    slivers: [
                      // ── Header ──────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('RADAR', style: AppTextStyles.displayMedium.copyWith(
                                color: AppColors.textPrimary,
                                letterSpacing: 4,
                              )),
                              const SizedBox(height: 4),
                              Text(
                                '${redTasks.length} eminentes · ${yellowTasks.length} pendentes',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: redRatio > 0.5 ? AppColors.taskRed : AppColors.taskYellow,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Barra de proporção red/yellow
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
                                            color: AppColors.taskRed.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      if (yellowTasks.isNotEmpty)
                                        Flexible(
                                          flex: yellowTasks.length,
                                          child: Container(
                                            height: 3,
                                            color: AppColors.taskYellow.withValues(alpha: 0.8),
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
                              color: AppColors.surface.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 8),
                                Text(
                                  'Segure um card para ir à rotina',
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
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
                                    color: AppColors.taskRed,
                                    boxShadow: AppColors.glowShadow(AppColors.taskRed),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'EMINENTES',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.taskRed,
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
                                    color: AppColors.taskYellow,
                                    boxShadow: AppColors.glowShadow(AppColors.taskYellow),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'PENDENTES',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.taskYellow,
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
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.taskYellow)),
      error: (err, stack) => Center(
        child: Text('Erro: $err', style: const TextStyle(color: AppColors.taskRed)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
              boxShadow: AppColors.glowShadow(AppColors.accent, intensity: 0.4),
            ),
            child: const Icon(Icons.radar, size: 40, color: AppColors.accent),
          ),
          const SizedBox(height: 20),
          Text('Radar Limpo!', style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent)),
          const SizedBox(height: 8),
          Text(
            'Nenhuma pendência\nou compromisso eminente.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
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
    final svc = ref.read(routineServiceProvider);

    // Buscar a rotina que contém a task via RoutineService
    final allRoutines = await svc.allRoutines();
    Routine? targetRoutine;

    outer:
    for (final routine in allRoutines) {
      final days = await svc.loadDays(routine);
      for (final day in days) {
        if (day.tasks.any((t) => t.id == taskInfo.task.id)) {
          targetRoutine = routine;
          break outer;
        }
      }
    }

    if (targetRoutine == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineScreen(routine: targetRoutine!, scrollToTaskId: taskInfo.task.id),
      ),
    );
  }
}
