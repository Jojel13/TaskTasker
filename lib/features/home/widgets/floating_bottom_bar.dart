import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/core_providers.dart';

class FloatingBottomBar extends ConsumerWidget {
  final VoidCallback onPlusTap;
  const FloatingBottomBar({super.key, required this.onPlusTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final xp = profile?.totalXP ?? 0;
    final level = profile?.currentLevel ?? 1;
    final streak = profile?.streakDays ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.glowShadow(AppColors.primary, intensity: 0.4),
      ),
      child: Row(children: [
        const SizedBox(width: 20),
        // Streak
        _InfoChip(icon: '🔥', label: '$streak'),
        const SizedBox(width: 16),
        // Level
        _InfoChip(icon: '⚡', label: 'Lv.$level'),
        const Spacer(),
        // XP
        Text('$xp XP',
            style: const TextStyle(
                color: AppColors.primaryDim,
                fontSize: 11,
                fontFamily: 'ShareTechMono')),
        const SizedBox(width: 12),
        // Botão +
        GestureDetector(
          onTap: onPlusTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: AppColors.glowShadow(AppColors.primary),
            ),
            child: const Icon(Icons.add, color: AppColors.background, size: 28),
          ),
        ),
        const SizedBox(width: 6),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    ]);
  }
}
