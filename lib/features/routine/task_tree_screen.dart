import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/task.dart';
import '../../shared/models/subtask.dart';
import '../../shared/models/mini_task.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/routine_day.dart';
import '../../shared/models/routine.dart';
import '../../core/services/xp_service.dart';
import 'widgets/task_input_field.dart';

class TaskTreeScreen extends ConsumerStatefulWidget {
  final Task task;
  const TaskTreeScreen({super.key, required this.task});

  @override
  ConsumerState<TaskTreeScreen> createState() => _TaskTreeScreenState();
}

class _TaskTreeScreenState extends ConsumerState<TaskTreeScreen> {
  
  Future<void> _invalidateProviders() async {
    final isar = ref.read(isarProvider);
    final day = await isar.routineDays.filter().tasks((q) => q.idEqualTo(widget.task.id)).findFirst();
    if (day != null) {
      final routine = await isar.routines.filter().days((q) => q.idEqualTo(day.id)).findFirst();
      if (routine != null) {
        ref.invalidate(routineDaysProvider(routine.id));
      }
    }
  }

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
    await _invalidateProviders();
    setState(() {});
  }

  void _addMiniTask(Subtask parentSubtask, int subIndex, String text) async {
    final isar = ref.read(isarProvider);
    final task = widget.task;
    
    final mini = MiniTask()
      ..text = text
      ..sortOrder = parentSubtask.miniTasks.length;
      
    parentSubtask.miniTasks = [...parentSubtask.miniTasks, mini];
    
    // Modify the task subtask array to trigger ISAR embedded object updates
    final newSubs = List<Subtask>.from(task.subtasks);
    newSubs[subIndex] = parentSubtask;
    task.subtasks = newSubs;
    
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });
    await _invalidateProviders();
    setState(() {});
  }

  void _toggleSubtask(int index) async {
    final sub = widget.task.subtasks[index];
    sub.isCompleted = !sub.isCompleted;
    sub.completedAt = sub.isCompleted ? DateTime.now() : null;
    
    final xpService = ref.read(xpServiceProvider);
    if (sub.isCompleted) {
      await xpService.addXp(3, 'Subtask concluída');
    } else {
      await xpService.deductXp(3, 'Subtask desmarcada');
    }

    // Auto-complete all mini-tasks if subtask is marked done
    if (sub.isCompleted) {
       for (final m in sub.miniTasks) {
          if (!m.isCompleted) {
             m.isCompleted = true;
             m.completedAt = DateTime.now();
             await xpService.addXp(5, 'MiniTask auto-concluída');
          }
       }
    }
    
    await _saveAndCheckParent();
  }

  void _toggleMiniTask(int subIndex, int miniIndex) async {
    final sub = widget.task.subtasks[subIndex];
    final mini = sub.miniTasks[miniIndex];
    
    mini.isCompleted = !mini.isCompleted;
    mini.completedAt = mini.isCompleted ? DateTime.now() : null;
    
    final xpService = ref.read(xpServiceProvider);
    if (mini.isCompleted) {
      await xpService.addXp(5, 'MiniTask concluída');
    } else {
      await xpService.deductXp(5, 'MiniTask desmarcada');
    }

    // Auto-complete subtask if all mini-tasks are done
    final allMinisDone = sub.miniTasks.every((m) => m.isCompleted);
    if (allMinisDone && !sub.isCompleted) {
        sub.isCompleted = true;
        sub.completedAt = DateTime.now();
        await xpService.addXp(3, 'Subtask auto-concluída');
    }

    await _saveAndCheckParent();
  }

  Future<void> _saveAndCheckParent() async {
    // Check if all subtasks are completed to auto-complete parent task
    final allCompleted = widget.task.subtasks.every((s) => s.isCompleted);
    if (allCompleted && widget.task.status != TaskStatus.completed) {
       widget.task.status = TaskStatus.completed;
       widget.task.completedOnDate = DateTime.now();
       final xpService = ref.read(xpServiceProvider);
       await xpService.addXp(XpService.xpForAction(widget.task.color), 'Task principal auto-concluída');
    }
    
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(widget.task);
    });
    await _invalidateProviders();
    setState(() {});
  }

  void _deleteSubtask(int index) async {
    final newSubs = List<Subtask>.from(widget.task.subtasks);
    newSubs.removeAt(index);
    widget.task.subtasks = newSubs;
    
    if (widget.task.subtasks.isEmpty) {
      widget.task.hasSubtasks = false;
    }
    
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(widget.task);
    });
    await _invalidateProviders();
    setState(() {});
  }

  void _deleteMiniTask(int subIndex, int miniIndex) async {
    final sub = widget.task.subtasks[subIndex];
    final newMinis = List<MiniTask>.from(sub.miniTasks);
    newMinis.removeAt(miniIndex);
    sub.miniTasks = newMinis;
    
    final newSubs = List<Subtask>.from(widget.task.subtasks);
    newSubs[subIndex] = sub;
    widget.task.subtasks = newSubs;
    
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(widget.task);
    });
    await _invalidateProviders();
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleSubtask(index),
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
                                  onPressed: () => _deleteSubtask(index),
                                )
                              ],
                            ),
                            // MiniTasks
                            if (sub.miniTasks.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 36.0, top: 4.0),
                                child: Column(
                                  children: List.generate(sub.miniTasks.length, (mIndex) {
                                     final m = sub.miniTasks[mIndex];
                                     return Row(
                                       children: [
                                          GestureDetector(
                                            onTap: () => _toggleMiniTask(index, mIndex),
                                            child: Icon(
                                              m.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                              color: m.isCompleted ? AppColors.textMuted : AppColors.accent,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              m.text,
                                              style: TextStyle(
                                                color: m.isCompleted ? AppColors.textMuted : AppColors.textSecondary,
                                                fontSize: 13,
                                                decoration: m.isCompleted ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                                            onPressed: () => _deleteMiniTask(index, mIndex),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          )
                                       ],
                                     );
                                  }),
                                ),
                              ),
                              // Add MiniTask Field
                              Padding(
                                padding: const EdgeInsets.only(left: 36.0, top: 4.0),
                                child: TaskInputField(
                                  placeholder: 'Nova mini-task...',
                                  onSubmit: (text) => _addMiniTask(sub, index, text),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                ),
            ),
            
            // Input Field for Subtasks
            Padding(
               padding: const EdgeInsets.all(8.0),
               child: TaskInputField(
                 placeholder: 'Nova subtask...',
                 onSubmit: _addSubtask,
               ),
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
