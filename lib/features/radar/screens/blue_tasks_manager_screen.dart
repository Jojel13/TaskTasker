import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_config.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/blur_confirm_dialog.dart';
import '../../routine/widgets/alarm_sheet.dart';

class BlueTasksManagerScreen extends ConsumerStatefulWidget {
  const BlueTasksManagerScreen({super.key});

  @override
  ConsumerState<BlueTasksManagerScreen> createState() => _BlueTasksManagerScreenState();
}

class _BlueTasksManagerScreenState extends ConsumerState<BlueTasksManagerScreen> {
  void _editHabit(BuildContext context, Task habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _EditHabitModal(habit: habit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final blueHabitsAsync = ref.watch(blueHabitsProvider);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: theme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TASKS AZUIS RECORRENTES',
                          style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(
                            color: theme.taskBlue,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Gerenciar cadências da semana',
                          style: theme.fontStyleBase(AppTextStyles.bodySmall).copyWith(color: theme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.taskBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.taskBlue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'SEMANAL',
                      style: theme.fontStyleMono(TextStyle(
                        color: theme.taskBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      )),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info banner ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: theme.taskBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Qualquer alteração ou exclusão feita aqui afeta somente do dia atual em diante. Seu histórico passado permanece intacto.',
                        style: theme.fontStyleBase(TextStyle(
                          color: theme.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        )),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Lista de Tasks Azuis ────────────────────────────
            Expanded(
              child: blueHabitsAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: theme.taskBlue)),
                error: (e, _) => Center(child: Text('Erro: $e', style: theme.fontStyleBase(TextStyle(color: theme.taskRed)))),
                data: (habits) {
                  if (habits.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat_rounded, size: 48, color: theme.taskBlue.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma task azul ativa',
                              style: theme.fontStyleBase(TextStyle(
                                color: theme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Transforme uma task em azul na rotina para configurá-la como um hábito frequente.',
                              style: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 12)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: habits.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final daysLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

                      return Container(
                        decoration: BoxDecoration(
                          color: theme.cardBlue,
                          borderRadius: BorderRadius.circular(theme.borderRadius),
                          border: Border.all(
                            color: theme.useGlowBorder ? theme.taskBlue : theme.taskBlue.withValues(alpha: 0.35),
                            width: theme.borderWidth,
                          ),
                          boxShadow: theme.useGlowBorder ? theme.glowShadow(theme.taskBlue, intensity: 0.25) : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(theme.borderRadius),
                            onTap: () => _editHabit(context, habit),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: theme.taskBlue.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: theme.taskBlue.withValues(alpha: 0.5)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: theme.taskBlue,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'FREQ',
                                              style: theme.fontStyleMono(TextStyle(
                                                color: theme.taskBlue,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              )),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          habit.frequency.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.fontStyleBase(TextStyle(
                                            color: theme.taskBlue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          )),
                                        ),
                                      ),
                                      // Badge de alarme
                                      if (habit.hasAlarm) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.primary.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: theme.primary.withValues(alpha: 0.4),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.alarm_on_rounded, size: 11, color: theme.primary),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${habit.alarmTime!.hour.toString().padLeft(2, '0')}:${habit.alarmTime!.minute.toString().padLeft(2, '0')}',
                                                style: theme.fontStyleMono(TextStyle(
                                                  color: theme.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                )),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      // Botões de ação compactos
                                      IconButton(
                                        icon: Icon(
                                          habit.hasAlarm ? Icons.alarm_on_rounded : Icons.alarm_add_rounded,
                                          size: 18,
                                          color: habit.hasAlarm ? theme.primary : theme.textMuted,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          await AlarmSheet.show(context, habit);
                                          ref.invalidate(blueHabitsProvider);
                                        },
                                        tooltip: habit.hasAlarm ? 'Editar alarme' : 'Adicionar alarme',
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(Icons.edit_rounded, size: 18, color: theme.taskBlue),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _editHabit(context, habit),
                                        tooltip: 'Editar hábito',
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: theme.taskRed),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => BlurConfirmDialog(
                                              title: 'Encerrar Task Azul',
                                              message: 'Deseja encerrar "${habit.text}" a partir de hoje?\n\nO histórico dos dias anteriores continuará salvo com suas estatísticas e XP intactos.',
                                              confirmLabel: 'Encerrar de hoje em diante',
                                              onConfirm: () async {
                                                await ref.read(routineServiceProvider).terminateBlueHabitFromToday(habit.id);
                                                ref.invalidate(blueHabitsProvider);
                                                ref.invalidate(radarProvider);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Task azul encerrada a partir de hoje!', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
                                                      backgroundColor: theme.taskBlue,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        },
                                        tooltip: 'Apagar a partir de hoje',
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Text(
                                    habit.text,
                                    style: theme.fontStyleBase(TextStyle(
                                      color: theme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    )),
                                  ),

                                  if (habit.frequency == FrequencyType.custom && habit.frequencyDays.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 10,
                                      children: List.generate(7, (dIdx) {
                                        final dayNumber = dIdx + 1;
                                        final isSelected = habit.frequencyDays.contains(dayNumber);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? theme.taskBlue.withValues(alpha: 0.25)
                                                : theme.surfaceVariant.withValues(alpha: 0.4),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSelected ? theme.taskBlue : theme.border.withValues(alpha: 0.4),
                                              width: isSelected ? 1.0 : 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            daysLabels[dIdx],
                                            style: theme.fontStyleBase(TextStyle(
                                              color: isSelected ? theme.taskBlue : theme.textMuted,
                                              fontSize: 10,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            )),
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditHabitModal extends ConsumerStatefulWidget {
  final Task habit;
  const _EditHabitModal({required this.habit});

  @override
  ConsumerState<_EditHabitModal> createState() => _EditHabitModalState();
}

class _EditHabitModalState extends ConsumerState<_EditHabitModal> {
  late TextEditingController _textController;
  late FrequencyType _selectedFrequency;
  late Set<int> _selectedDays;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.habit.text);
    _selectedFrequency = widget.habit.frequency;
    _selectedDays = Set.from(widget.habit.frequencyDays);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save(AppThemeData theme) async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('O nome não pode ser vazio.'), backgroundColor: theme.taskRed),
      );
      return;
    }

    if (_selectedFrequency == FrequencyType.custom && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Selecione ao menos um dia da semana.'), backgroundColor: theme.taskRed),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(routineServiceProvider).updateBlueHabit(
        sampleTaskId: widget.habit.id,
        newText: text,
        newFrequency: _selectedFrequency,
        newDays: _selectedDays.toList(),
      );
      ref.invalidate(blueHabitsProvider);
      ref.invalidate(radarProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final daysLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(theme.borderRadius > 20 ? 20 : theme.borderRadius)),
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  'Configurar Task Azul',
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
            const SizedBox(height: 20),

            // Nome da Task
            Text('Nome da Tarefa', style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.textMuted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border),
              ),
              child: TextField(
                controller: _textController,
                style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 14)),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),

            const SizedBox(height: 20),

            // Frequência
            Text('Frequência de repetição', style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.textMuted)),
            const SizedBox(height: 10),

            ...FrequencyType.values.map((freq) {
              final isSelected = _selectedFrequency == freq;
              return GestureDetector(
                onTap: () => setState(() => _selectedFrequency = freq),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.cardBlue : theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(theme.borderRadius > 10 ? 10 : theme.borderRadius),
                    border: Border.all(
                      color: isSelected ? theme.taskBlue : theme.border,
                      width: isSelected ? 1 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isSelected ? theme.taskBlue : theme.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        freq.label,
                        style: theme.fontStyleBase(TextStyle(
                          color: isSelected ? theme.textPrimary : theme.textSecondary,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (_selectedFrequency == FrequencyType.custom) ...[
              const SizedBox(height: 10),
              Text('Dias da semana:', style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
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
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? theme.taskBlue.withValues(alpha: 0.2) : theme.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.taskBlue : theme.border,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Text(
                        daysLabels[index],
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

            const SizedBox(height: 24),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.taskBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius)),
                ),
                onPressed: _isSaving ? null : () => _save(theme),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Salvar Alterações', style: theme.fontStyleBase(const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
