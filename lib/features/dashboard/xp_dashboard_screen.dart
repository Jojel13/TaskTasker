import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/xp_service.dart';

class XpDashboardScreen extends ConsumerWidget {
  const XpDashboardScreen({super.key});

  String _getMascot(int level) {
    if (level < 5) return '🥚';
    if (level < 15) return '🐣';
    if (level < 30) return '🤖';
    if (level < 50) return '⚡';
    return '👾';
  }

  String _getMascotName(int level) {
    if (level < 5) return 'Glitch Egg';
    if (level < 15) return 'Byte';
    if (level < 30) return 'Nano';
    if (level < 50) return 'Volt';
    return 'NEXUS';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile == null) return const Scaffold(backgroundColor: AppColors.background);

    final xpService = ref.watch(xpServiceProvider);
    final totalXp = profile.totalXP;
    final level = xpService.calculateLevel(totalXp);
    final xpForCurrent = xpService.xpForLevel(level);
    final xpForNext = xpService.xpForLevel(level + 1);
    
    final progress = (totalXp - xpForCurrent) / (xpForNext - xpForCurrent);

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
              // Mascot
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [...AppColors.glowShadow(AppColors.primary, intensity: 0.5)],
                ),
                child: Center(
                  child: Text(
                    _getMascot(level),
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_getMascotName(level), style: AppTextStyles.titleLarge),
              Text('Nível $level', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
              
              const SizedBox(height: 40),
              
              // XP Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('XP TOTAL: $totalXp', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
                      Text('${totalXp - xpForCurrent} / ${xpForNext - xpForCurrent} XP', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
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
