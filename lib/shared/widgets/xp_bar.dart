import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../core/providers/core_providers.dart';
import '../../core/services/xp_service.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/dashboard/xp_dashboard_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;

class XpBar extends ConsumerStatefulWidget {
  const XpBar({super.key});

  @override
  ConsumerState<XpBar> createState() => _XpBarState();
}

class _XpBarState extends ConsumerState<XpBar> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    ref.listen<AsyncValue>(userProfileProvider, (previous, next) {
      if (previous?.value == null || next.value == null) return;
      final prevLevel = previous!.value!.currentLevel;
      final nextLevel = next.value!.currentLevel;
      if (nextLevel > prevLevel) {
        if (!context.mounted) return;
        _showLevelUpOverlay(context, nextLevel, theme);
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
                      style: theme.fontStyleMono(AppTextStyles.monoSmall).copyWith(
                        color: theme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$xpInCurrentLevel / $xpForCurrentLevel XP',
                      style: theme.fontStyleMono(AppTextStyles.monoSmall).copyWith(
                        color: theme.textMuted,
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
                    backgroundColor: theme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
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

  void _showLevelUpOverlay(BuildContext context, int newLevel, AppThemeData theme) {
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
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.star_rounded, color: theme.taskYellow, size: 80)
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scaleXY(begin: 1.0, end: 1.2, duration: 600.ms)
                      .tint(color: Colors.white, duration: 600.ms),
                  ...List.generate(12, (index) {
                    final angle = index * (2 * pi / 12);
                    final distance = 60.0;
                    final targetX = cos(angle) * distance;
                    final targetY = sin(angle) * distance;
                    
                    return Positioned(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index % 2 == 0 ? theme.primary : theme.accent,
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(begin: Offset.zero, end: const Offset(1.5, 1.5), duration: 1000.ms)
                          .move(
                            begin: Offset.zero,
                            end: Offset(targetX, targetY),
                            duration: 1000.ms,
                            curve: Curves.easeOutCubic,
                          )
                          .fadeOut(delay: 600.ms, duration: 400.ms),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'LEVEL UP!',
                style: theme.fontStyleBase(TextStyle(
                  color: theme.taskYellow,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: theme.taskYellow, blurRadius: 20),
                  ],
                )),
              ).animate().fade(duration: 400.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(
                'Nível $newLevel Alcançado',
                style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 18)),
              ).animate().fade(delay: 300.ms),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.taskYellow.withValues(alpha: 0.2),
                  foregroundColor: theme.taskYellow,
                  side: BorderSide(color: theme.taskYellow),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius)),
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
