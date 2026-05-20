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
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home
            Semantics(
              label: 'Aba Início',
              selected: currentIndex == 0,
              button: true,
              child: _NavItem(
                icon: Icons.home_rounded,
                isActive: currentIndex == 0,
                activeColor: AppColors.primary,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onNavTap(0);
                },
              ),
            ),

            // Botão + central
            Semantics(
              label: 'Nova Rotina',
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onPlusTap();
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    boxShadow: AppColors.glowShadowIntense(AppColors.primary),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.background,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Radar
            Semantics(
              label: 'Aba Radar',
              selected: currentIndex == 1,
              button: true,
              child: _NavItem(
                icon: Icons.radar_rounded,
                isActive: currentIndex == 1,
                activeColor: AppColors.taskYellow,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onNavTap(1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
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
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: isActive
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              )
            : null,
        child: Icon(
          icon,
          color: isActive ? activeColor : AppColors.textSecondary,
          size: 26,
        ),
      ),
    );
  }
}
