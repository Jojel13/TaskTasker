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
  DateTime? _selectedDate;
  FrequencyType _selectedFrequency = FrequencyType.daily;
  Set<int> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.task.scheduledDate;
    _selectedFrequency = widget.task.frequency;
    _selectedDays = Set.from(widget.task.frequencyDays);
  }

  void _save() async {
    final task = widget.task;
    task.scheduledDate = _selectedDate;
    task.frequency = _selectedFrequency;
    task.frequencyDays = _selectedDays.toList();
    
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurar Task',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 24),
          
          if (widget.task.color == TaskColor.red) ...[
            Text('Data Limite (Task Vermelha)', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.taskRed,
                          onPrimary: Colors.white,
                          surface: AppColors.background,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.taskRed),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null 
                        ? 'Selecione uma data...' 
                        : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (widget.task.color == TaskColor.blue) ...[
            Text('Frequência (Task Azul)', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<FrequencyType>(
              value: _selectedFrequency,
              dropdownColor: AppColors.surface,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              items: FrequencyType.values.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f.name),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFrequency = val);
              },
            ),
            if (_selectedFrequency == FrequencyType.custom) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1; // 1=Mon ... 7=Sun
                  final isSelected = _selectedDays.contains(day);
                  final labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) _selectedDays.remove(day);
                        else _selectedDays.add(day);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.taskBlue.withOpacity(0.2) : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.taskBlue : AppColors.border,
                        ),
                      ),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          color: isSelected ? AppColors.taskBlue : AppColors.textMuted,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ] else ...[
             const Text('Esta cor de task não possui configurações adicionais.', style: TextStyle(color: AppColors.textMuted)),
          ],
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save,
              child: const Text('Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}
