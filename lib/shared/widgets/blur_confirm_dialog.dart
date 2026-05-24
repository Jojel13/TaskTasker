import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';

/// Diálogo de confirmação com fundo blur e tema cyberpunk
class BlurConfirmDialog extends ConsumerWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color? confirmColor;
  final VoidCallback onConfirm;

  const BlurConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'Confirmar',
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final activeConfirmColor = confirmColor ?? theme.taskRed;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(color: theme.border),
          boxShadow: theme.glowShadow(activeConfirmColor, intensity: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.fontStyleBase(const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700)).copyWith(color: theme.textPrimary)
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.fontStyleBase(const TextStyle(
                  fontSize: 14)).copyWith(color: theme.textSecondary),
              textAlign: TextAlign.center
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: theme.fontStyleBase(const TextStyle()).copyWith(color: theme.textMuted)
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeConfirmColor.withValues(alpha: 0.15),
                    foregroundColor: activeConfirmColor,
                    side: BorderSide(color: activeConfirmColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.borderRadius > 8 ? 8 : theme.borderRadius)),
                  ),
                  child: Text(confirmLabel, style: theme.fontStyleBase(const TextStyle())),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
