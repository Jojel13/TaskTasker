import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/task.dart';
import 'widgets/task_input_field.dart';

class TaskTreeScreen extends ConsumerStatefulWidget {
  final Task task;
  const TaskTreeScreen({super.key, required this.task});

  @override
  ConsumerState<TaskTreeScreen> createState() => _TaskTreeScreenState();
}

class _TaskTreeScreenState extends ConsumerState<TaskTreeScreen> {
  
  void _addSubtask(String text) async {
    final isar = ref.read(isarProvider);
    final task = widget.task;
    
    final sub = Subtask()
      ..text = text
      ..createdAt = DateTime.now()
      ..sortOrder = task.subtasks.length;
      
    task.subtasks = [...task.subtasks, sub];
    task.hasSubtasks = true;
    
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });
    
    setState(() {});
  }

  void _toggleSubtask(Subtask sub) async {
    sub.isCompleted = !sub.isCompleted;
    sub.completedAt = sub.isCompleted ? DateTime.now() : null;
    
    // Check if all subtasks are completed to auto-complete parent task
    final allCompleted = widget.task.subtasks.every((s) => s.isCompleted);
    if (allCompleted && widget.task.status != TaskStatus.completed) {
       widget.task.status = TaskStatus.completed;
       widget.task.completedOnDate = DateTime.now();
    }
    
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(widget.task);
    });
    
    setState(() {});
  }

  void _deleteSubtask(Subtask sub) async {
    widget.task.subtasks = widget.task.subtasks.where((s) => s != sub).toList();
    if (widget.task.subtasks.isEmpty) {
      widget.task.hasSubtasks = false;
    }
    
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(widget.task);
    });
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Task Tree', style: AppTextStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parent Task Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                color: AppColors.surface.withOpacity(0.3),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getColor(task.color),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      task.text,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: task.status == TaskStatus.completed ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Subtasks List
            Expanded(
              child: task.subtasks.isEmpty 
                ? const Center(child: Text('Nenhuma subtask.', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    itemCount: task.subtasks.length,
                    itemBuilder: (context, index) {
                      final sub = task.subtasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleSubtask(sub),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  sub.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  color: sub.isCompleted ? AppColors.textMuted : AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                sub.text,
                                style: TextStyle(
                                  color: sub.isCompleted ? AppColors.textMuted : AppColors.textSecondary,
                                  decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (sub.completedAt != null)
                              Text(
                                '${sub.completedAt!.hour.toString().padLeft(2, '0')}:${sub.completedAt!.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.taskRed),
                              onPressed: () => _deleteSubtask(sub),
                            )
                          ],
                        ),
                      );
                    },
                ),
            ),
            
            // Input Field for Subtasks
            TaskInputField(
              onSubmit: _addSubtask,
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(TaskColor c) => switch (c) {
    TaskColor.standard => AppColors.taskStandard,
    TaskColor.blue     => AppColors.taskBlue,
    TaskColor.yellow   => AppColors.taskYellow,
    TaskColor.red      => AppColors.taskRed,
  };
}
