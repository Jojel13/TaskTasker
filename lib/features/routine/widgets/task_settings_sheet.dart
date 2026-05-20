import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';


class TaskSettingsSheet extends ConsumerStatefulWidget {
  final Task task;
  const TaskSettingsSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TaskSettingsSheet(task: task),
      ),
    );
  }

  @override
  ConsumerState<TaskSettingsSheet> createState() => _TaskSettingsSheetState();
}

class _TaskSettingsSheetState extends ConsumerState<TaskSettingsSheet> {
  FrequencyType _selectedFrequency = FrequencyType.daily;
  Set<int> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.task.frequency;
    _selectedDays = Set.from(widget.task.frequencyDays);
  }

  Future<void> _save() async {
    final task = widget.task;

    if (task.color == TaskColor.blue) {
      // M16: n\u00e3o salvar frequ\u00eancia customizada sem dias selecionados
      if (_selectedFrequency == FrequencyType.custom && _selectedDays.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selecione pelo menos um dia da semana.'),
              backgroundColor: AppColors.taskRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      task.frequency = _selectedFrequency;
      task.frequencyDays = _selectedDays.toList();
      task.createdAt = DateTime.now(); // M6: Reset cadence reference date on settings change
    }

    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle + Header ──────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.task.color == TaskColor.blue
                    ? 'Frequência da Task'
                    : 'Configurar Task',
                style: AppTextStyles.titleMedium,
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Conteúdo por tipo de task ────────────────────────
          if (widget.task.color == TaskColor.blue) ...[
            Text('Com que frequência essa task aparece?',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),

            // Seleção de frequência
            ...FrequencyType.values.map((freq) {
              final isSelected = _selectedFrequency == freq;
              return GestureDetector(
                onTap: () => setState(() => _selectedFrequency = freq),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.cardBlue
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.taskBlue : AppColors.border,
                      width: isSelected ? 1 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isSelected ? AppColors.taskBlue : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        freq.label,
                        style: TextStyle(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Dias da semana (modo personalizado)
            if (_selectedFrequency == FrequencyType.custom) ...[
              const SizedBox(height: 8),
              Text('Dias da semana:',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  final labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.taskBlue.withValues(alpha: 0.15)
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.taskBlue : AppColors.border,
                          width: isSelected ? 1 : 0.5,
                        ),
                      ),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected ? AppColors.taskBlue : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ] else ...[
            Text(
              'Esta task não possui configurações adicionais.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],

          const SizedBox(height: 28),

          // ── Botão Salvar ─────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.taskBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _save,
              child: const Text(
                'Salvar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
