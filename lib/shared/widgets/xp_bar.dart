import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/xp_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/dashboard/xp_dashboard_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;

class XpBar extends ConsumerWidget {
  const XpBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue>(userProfileProvider, (previous, next) {
      if (previous?.value == null || next.value == null) return;
      final prevLevel = previous!.value!.currentLevel;
      final nextLevel = next.value!.currentLevel;
      if (nextLevel > prevLevel) {
        if (!context.mounted) return;
        _showLevelUpOverlay(context, nextLevel);
      }
    });

    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final currentXp = profile.totalXP;
        final currentLevel = profile.currentLevel;
        
        // Calcular progresso do nível atual
        final accumulatedBeforeCurrent = XpService.xpAccumulatedForLevel(currentLevel);
        final xpForCurrentLevel = XpService.xpRequiredForLevel(currentLevel);
        
        final xpInCurrentLevel = currentXp - accumulatedBeforeCurrent;
        final progress = (xpForCurrentLevel > 0) ? xpInCurrentLevel / xpForCurrentLevel : 0.0;

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
                      '$xpInCurrentLevel / $xpForCurrentLevel XP',
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
      error: (_, _) => const SizedBox(height: 30),
    );
  }

  void _showLevelUpOverlay(BuildContext context, int newLevel) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.taskYellow, size: 80)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.2, duration: 600.ms)
                  .tint(color: Colors.white, duration: 600.ms),
              const SizedBox(height: 24),
              const Text(
                'LEVEL UP!',
                style: TextStyle(
                  color: AppColors.taskYellow,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: AppColors.taskYellow, blurRadius: 20),
                  ],
                ),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                'Nível $newLevel Alcançado',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ).animate().fade(delay: 300.ms),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.taskYellow.withValues(alpha: 0.2),
                  foregroundColor: AppColors.taskYellow,
                  side: const BorderSide(color: AppColors.taskYellow),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
              ).animate().fade(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
