import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
class FloatingBottomBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: theme.border, width: 0.5),
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
                activeColor: theme.primary,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onNavTap(0);
                },
                textSecondaryColor: theme.textSecondary,
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
                    color: theme.primary,
                    boxShadow: theme.glowShadow(theme.primary, intensity: 1.5),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: theme.background,
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
                activeColor: theme.taskYellow,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onNavTap(1);
                },
                textSecondaryColor: theme.textSecondary,
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
  final Color textSecondaryColor;

  const _NavItem({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
    required this.textSecondaryColor,
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
          color: isActive ? activeColor : textSecondaryColor,
          size: 26,
        ),
      ),
    );
  }
}
