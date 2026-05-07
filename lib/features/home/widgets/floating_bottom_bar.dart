import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FloatingBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavTap;
  final VoidCallback onPlusTap;

  const FloatingBottomBar({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
    required this.onPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
             color: AppColors.primary.withOpacity(0.15),
             blurRadius: 20,
             spreadRadius: 5,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => onNavTap(0),
            behavior: HitTestBehavior.opaque,
            child: Container(
               padding: const EdgeInsets.all(12),
               child: Icon(
                 Icons.home_rounded, 
                 color: currentIndex == 0 ? AppColors.primary : AppColors.textMuted,
                 size: 26,
               ),
            ),
          ),
          
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
          
          GestureDetector(
            onTap: () => onNavTap(1),
            behavior: HitTestBehavior.opaque,
            child: Container(
               padding: const EdgeInsets.all(12),
               child: Icon(
                 Icons.radar_rounded, 
                 color: currentIndex == 1 ? AppColors.taskYellow : AppColors.textMuted,
                 size: 26,
               ),
            ),
          ),
        ],
      ),
    );
  }
}
