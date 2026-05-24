import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_config.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';

class TaskSettingsSheet extends ConsumerStatefulWidget {
  final Task task;
  const TaskSettingsSheet({super.key, required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
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

  Future<void> _save(AppThemeData theme) async {
    final task = widget.task;

    if (task.color == TaskColor.blue) {
      if (_selectedFrequency == FrequencyType.custom && _selectedDays.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Selecione pelo menos um dia da semana.'),
              backgroundColor: theme.taskRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      task.frequency = _selectedFrequency;
      task.frequencyDays = _selectedDays.toList();
      task.createdAt = DateTime.now();
    }

    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(theme.borderRadius > 20 ? 20 : theme.borderRadius)),
      ),
      child: Padding(
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
                  color: theme.border,
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
                  style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: theme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Conteúdo por tipo de task ────────────────────────
            if (widget.task.color == TaskColor.blue) ...[
              Text('Com que frequência essa task aparece?',
                  style: theme.fontStyleBase(AppTextStyles.bodySmall).copyWith(color: theme.textMuted)),
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
                          ? theme.cardBlue
                          : theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius),
                      border: Border.all(
                        color: isSelected ? theme.taskBlue : theme.border,
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
                          color: isSelected ? theme.taskBlue : theme.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          freq.label,
                          style: theme.fontStyleBase(TextStyle(
                            color: isSelected ? theme.textPrimary : theme.textSecondary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          )),
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
                    style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.textMuted)),
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
                              ? theme.taskBlue.withValues(alpha: 0.15)
                              : theme.surfaceVariant,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? theme.taskBlue : theme.border,
                            width: isSelected ? 1 : 0.5,
                          ),
                        ),
                        child: Text(
                          labels[index],
                          style: theme.fontStyleBase(TextStyle(
                            color: isSelected ? theme.taskBlue : theme.textMuted,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          )),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ] else ...[
              Text(
                'Esta task não possui configurações adicionais.',
                style: theme.fontStyleBase(AppTextStyles.bodySmall).copyWith(color: theme.textMuted),
              ),
            ],

            const SizedBox(height: 28),

            // ── Botão Salvar ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.taskBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius)),
                  elevation: 0,
                ),
                onPressed: () => _save(theme),
                child: Text(
                  'Salvar',
                  style: theme.fontStyleBase(const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
