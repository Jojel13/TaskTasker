import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: currentIndex == 0,
              activeColor: AppColors.primary,
              onTap: () {
                HapticFeedback.selectionClick();
                onNavTap(0);
              },
            ),

            // Radar
            _NavItem(
              icon: Icons.radar_rounded,
              label: 'Radar',
              isActive: currentIndex == 1,
              activeColor: AppColors.taskYellow,
              onTap: () {
                HapticFeedback.selectionClick();
                onNavTap(1);
              },
            ),

            // Botão central + (criar rotina)
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onPlusTap();
              },
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: AppColors.glowShadowIntense(AppColors.primary),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.background, size: 28),
              ),
            ),

            // XP
            _NavItem(
              icon: Icons.star_rounded,
              label: 'XP',
              isActive: currentIndex == 2,
              activeColor: AppColors.accent,
              onTap: () {
                HapticFeedback.selectionClick();
                onNavTap(2);
              },
            ),

            // Análise
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Análise',
              isActive: currentIndex == 3,
              activeColor: AppColors.secondary,
              onTap: () {
                HapticFeedback.selectionClick();
                onNavTap(3);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive ? activeColor : Colors.transparent,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
