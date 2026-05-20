import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/xp_service.dart';
import '../../shared/widgets/sapo_mascot_widget.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class XpDashboardScreen extends ConsumerWidget {
  const XpDashboardScreen({super.key});

  /// M18: nome do mascote baseado no n\u00edvel do usu\u00e1rio
  String _getMascotName(int level) {
    if (level <= 2)  return 'Sapo Iniciante';
    if (level <= 5)  return 'Sapo Treinado';
    if (level <= 9)  return 'Sapo Dedicado';
    if (level <= 14) return 'Sapo Expert';
    if (level <= 19) return 'Sapo Mestre';
    if (level <= 29) return 'Sapo Lend\u00e1rio';
    return 'Sapo Imortal';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile == null) return const Scaffold(backgroundColor: AppColors.background);

    final totalXp = profile.totalXP;
    final level = profile.currentLevel;
    final accumulatedBeforeCurrent = XpService.xpAccumulatedForLevel(level);
    final xpForCurrentLevel = XpService.xpRequiredForLevel(level);
    
    final xpInCurrentLevel = totalXp - accumulatedBeforeCurrent;
    final progress = (xpForCurrentLevel > 0) ? (xpInCurrentLevel / xpForCurrentLevel).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Dashboard', style: AppTextStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mascot interativo animado
              const SapoMascotWidget(size: 120),
              const SizedBox(height: 16),
              Text(_getMascotName(level), style: AppTextStyles.titleLarge),
              Text('Nível $level', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
              
              // XP Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('XP TOTAL: $totalXp', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                      Text('$xpInCurrentLevel / $xpForCurrentLevel XP', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * progress,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [...AppColors.glowShadow(AppColors.primary, intensity: 0.8)],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.taskYellow,
                      title: 'STREAK ATUAL',
                      value: '${profile.streakDays} dias',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.taskBlue,
                      title: 'RECORDE',
                      value: '${profile.streakRecord} dias',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Heatmap
              Text('HISTÓRICO DE PRODUTIVIDADE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final heatmapAsync = ref.watch(heatmapProvider);
                  return heatmapAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, _) => Text('Erro: $err', style: const TextStyle(color: AppColors.taskRed)),
                    data: (dataset) {
                      if (dataset.isEmpty) {
                        return const Center(child: Text('Nenhum dado ainda.', style: TextStyle(color: AppColors.textMuted)));
                      }
                      return HeatMap(
                        datasets: dataset,
                        colorMode: ColorMode.opacity,
                        showText: false,
                        scrollable: true,
                        size: 30,
                        colorsets: const {
                          1: AppColors.taskYellow, // 1-24%
                          2: AppColors.taskBlue, // 25-49%
                          3: AppColors.accent, // 50-74%
                          4: AppColors.primary, // 75-100%
                        },
                        onClick: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Atividade no dia ${value.day}/${value.month}'),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}
