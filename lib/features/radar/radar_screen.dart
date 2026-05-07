import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/enums.dart';
import '../routine/widgets/task_card.dart';

class RadarScreen extends ConsumerWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radarTasksAsync = ref.watch(radarProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by MainWrapper
      body: SafeArea(
        child: radarTasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.radar, size: 80, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'Radar Limpo!',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nenhuma pendência ou\ncompromisso eminente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }

            final redTasks = tasks.where((t) => t.color == TaskColor.red).toList();
            final yellowTasks = tasks.where((t) => t.color == TaskColor.yellow).toList();
            
            // Sort red by scheduledDate
            redTasks.sort((a, b) => (a.scheduledDate ?? DateTime.now()).compareTo(b.scheduledDate ?? DateTime.now()));
            // Sort yellow by createdAt
            yellowTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('RADAR', style: AppTextStyles.titleLarge),
                  ),
                ),
                if (redTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text('EMINENTES', style: AppTextStyles.labelSmall.copyWith(color: AppColors.taskRed)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AbsorbPointer(
                          absorbing: true, // Radar is read-only view
                          child: TaskCard(
                            task: redTasks[index],
                            onToggle: () {},
                            onColorCycle: () {},
                            onDelete: () {},
                          ),
                        ),
                      ),
                      childCount: redTasks.length,
                    ),
                  ),
                ],
                if (yellowTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text('PENDENTES', style: AppTextStyles.labelSmall.copyWith(color: AppColors.taskYellow)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AbsorbPointer(
                          absorbing: true,
                          child: TaskCard(
                            task: yellowTasks[index],
                            onToggle: () {},
                            onColorCycle: () {},
                            onDelete: () {},
                          ),
                        ),
                      ),
                      childCount: yellowTasks.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(child: Text('Erro: $err', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }
}
