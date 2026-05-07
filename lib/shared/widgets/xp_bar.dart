import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/xp_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/dashboard/xp_dashboard_screen.dart';

class XpBar extends ConsumerWidget {
  const XpBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final currentXp = profile.totalXP;
        final currentLevel = profile.currentLevel;
        
        // Calcular progresso do nível atual
        final xpNeededForCurrent = currentLevel == 1 ? 0 : XpService.xpRequiredForLevel(currentLevel - 1);
        final xpNeededForNext = XpService.xpRequiredForLevel(currentLevel);
        
        final xpInCurrentLevel = currentXp - xpNeededForCurrent;
        final xpToNextLevel = xpNeededForNext - xpNeededForCurrent;
        
        final progress = (xpToNextLevel > 0) ? xpInCurrentLevel / xpToNextLevel : 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const XpDashboardScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LVL $currentLevel',
                      style: AppTextStyles.monoSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$xpInCurrentLevel / $xpToNextLevel XP',
                      style: AppTextStyles.monoSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 30),
      error: (_, __) => const SizedBox(height: 30),
    );
  }
}
