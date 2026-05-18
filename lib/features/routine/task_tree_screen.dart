import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:isar/isar.dart';
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
  final bool isReadOnly;
  const TaskTreeScreen({super.key, required this.task, this.isReadOnly = false});

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

  /// Reordena subtasks via drag & drop.
  /// Chamado pelo ReorderableListView quando o usuário solta o item.
  void _reorderSubtasks(int oldIndex, int newIndex) async {
    // O ReorderableListView passa newIndex ANTES de remover o oldIndex,
    // então é necessário ajustar se newIndex > oldIndex.
    if (newIndex > oldIndex) newIndex -= 1;

    final subs = List<Subtask>.from(widget.task.subtasks);
    final moved = subs.removeAt(oldIndex);
    subs.insert(newIndex, moved);

    // Atualizar sortOrder de todos
    for (int i = 0; i < subs.length; i++) {
      subs[i].sortOrder = i;
    }

    widget.task.subtasks = subs;
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.tasks.put(widget.task);
    });
    await _invalidateProviders();
    setState(() {});
  }

  // ─── Helpers ───────────────────────────────────────────────────
  Color get _taskColor => switch (widget.task.color) {
    TaskColor.standard => AppColors.taskStandard,
    TaskColor.blue     => AppColors.taskBlue,
    TaskColor.yellow   => AppColors.taskYellow,
    TaskColor.red      => AppColors.taskRed,
  };

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDone = task.status == TaskStatus.completed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Árvore de Tasks', style: AppTextStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header da Task Principal ──────────────────────────
            _TaskHeader(task: task, taskColor: _taskColor, isDone: isDone),

            // ── Lista de Subtasks (arrastável) ───────────────────
            Expanded(
              child: task.subtasks.isEmpty
                  ? const _EmptySubtasks()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      buildDefaultDragHandles: false,
                      // Desativa drag em modo leitura
                      onReorder: widget.isReadOnly
                          ? (int oldIndex, int newIndex) {}
                          : _reorderSubtasks,
                      itemCount: task.subtasks.length,
                      itemBuilder: (context, index) {
                        final sub = task.subtasks[index];
                        return ReorderableDragStartListener(
                          key: ValueKey('reorder_$index'),
                          index: index,
                          // Só permite drag de subtasks não concluídas
                          enabled: !widget.isReadOnly && !sub.isCompleted,
                          child: _SubtaskItem(
                            key: ValueKey('sub_${sub.hashCode}_$index'),
                            sub: sub,
                            subIndex: index,
                            taskColor: _taskColor,
                            isReadOnly: widget.isReadOnly,
                            onToggle: () => _toggleSubtask(index),
                            onDelete: () => _deleteSubtask(index),
                            onAddMiniTask: (text) =>
                                _addMiniTask(sub, index, text),
                            onToggleMiniTask: (mIdx) =>
                                _toggleMiniTask(index, mIdx),
                            onDeleteMiniTask: (mIdx) =>
                                _deleteMiniTask(index, mIdx),
                            formatTime: _formatTime,
                          ),
                        );
                      },
                    ),
            ),

            // ── Input nova subtask ───────────────────────────────────
            if (!widget.isReadOnly)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: TaskInputField(
                  placeholder: 'Nova subtask...',
                  onSubmit: _addSubtask,
                  collapsed: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Header da Task Principal
// ══════════════════════════════════════════════════════════════════
class _TaskHeader extends StatelessWidget {
  final Task task;
  final Color taskColor;
  final bool isDone;

  const _TaskHeader({
    required this.task,
    required this.taskColor,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.background
            : AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: isDone ? AppColors.border : taskColor,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone de status da task principal (maior hierarquia)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isDone
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('done'),
                      color: AppColors.accent,
                      size: 22)
                  : Icon(Icons.circle_outlined,
                      key: const ValueKey('active'),
                      color: taskColor,
                      size: 22),
            ),
          ),
          const SizedBox(width: 14),

          // Texto da task
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.text,
                  style: TextStyle(
                    color: isDone
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                // Progress pill: "X / Y subtasks"
                _SubtaskProgressPill(task: task, taskColor: taskColor),
              ],
            ),
          ),

          // Badge de cor da task (pill no canto)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: taskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: taskColor.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: taskColor,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _colorLabel(task.color),
                  style: TextStyle(
                    color: taskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _colorLabel(TaskColor c) => switch (c) {
    TaskColor.standard => 'STD',
    TaskColor.blue     => 'FREQ',
    TaskColor.yellow   => 'PEND',
    TaskColor.red      => 'DATA',
  };
}

// ── Pill de progresso das subtasks ──────────────────────────────
class _SubtaskProgressPill extends StatelessWidget {
  final Task task;
  final Color taskColor;
  const _SubtaskProgressPill({required this.task, required this.taskColor});

  @override
  Widget build(BuildContext context) {
    if (task.subtasks.isEmpty) return const SizedBox.shrink();
    final done = task.subtasks.where((s) => s.isCompleted).length;
    final total = task.subtasks.length;
    final ratio = done / total;

    return Row(
      children: [
        // Barra de progresso
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                done == total ? AppColors.accent : taskColor,
              ),
              minHeight: 3,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$done/$total',
          style: TextStyle(
            color: done == total ? AppColors.accent : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Item de Subtask (Nível 2) — com Swipe-left
// ══════════════════════════════════════════════════════════════════
class _SubtaskItem extends StatefulWidget {
  final Subtask sub;
  final int subIndex;
  final Color taskColor;
  final bool isReadOnly;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(String) onAddMiniTask;
  final Function(int) onToggleMiniTask;
  final Function(int) onDeleteMiniTask;
  final String Function(DateTime?) formatTime;

  const _SubtaskItem({
    super.key,
    required this.sub,
    required this.subIndex,
    required this.taskColor,
    required this.isReadOnly,
    required this.onToggle,
    required this.onDelete,
    required this.onAddMiniTask,
    required this.onToggleMiniTask,
    required this.onDeleteMiniTask,
    required this.formatTime,
  });

  @override
  State<_SubtaskItem> createState() => _SubtaskItemState();
}

class _SubtaskItemState extends State<_SubtaskItem> {
  // Controla se o input de mini-task está visível
  // (ativado pelo swipe-left "adicionar mini-task")
  bool _showMiniInput = false;

  @override
  Widget build(BuildContext context) {
    final isDone = widget.sub.isCompleted;
    final sub = widget.sub;

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.background
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? AppColors.border
              : widget.taskColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha da Subtask ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle (visível apenas em modo de edição)
                if (!widget.isReadOnly && !isDone)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 20,
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ),

                // Ícone hierárquico nível 2
                GestureDetector(
                  onTap: widget.isReadOnly ? null : widget.onToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isDone
                          ? Icon(
                              Icons.check_circle_rounded,
                              key: const ValueKey('sub_done'),
                              color: AppColors.accent,
                              size: 22,
                            )
                          : Icon(
                              Icons.radio_button_unchecked_rounded,
                              key: const ValueKey('sub_active'),
                              color: widget.taskColor,
                              size: 22,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Texto
                Expanded(
                  child: Text(
                    sub.text,
                    style: TextStyle(
                      color: isDone
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight:
                          isDone ? FontWeight.normal : FontWeight.w500,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ),

                // Badge de horário de conclusão
                if (isDone && sub.completedAt != null)
                  _TimePill(
                      time: widget.formatTime(sub.completedAt)),

                // Hint de swipe (só se não-readonly e não concluído)
                if (!widget.isReadOnly && !isDone)
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 16,
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),

          // ── Mini-tasks (Nível 3) ──────────────────────────
          if (sub.miniTasks.isNotEmpty ||
              (!widget.isReadOnly && _showMiniInput))
            Padding(
              padding: const EdgeInsets.fromLTRB(44, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sub.miniTasks.isNotEmpty)
                    Divider(
                      color: widget.taskColor.withValues(alpha: 0.1),
                      thickness: 0.5,
                      height: 8,
                    ),

                  // Lista de mini-tasks
                  ...List.generate(sub.miniTasks.length, (mIdx) {
                    final m = sub.miniTasks[mIdx];
                    return _MiniTaskItem(
                      mini: m,
                      isReadOnly: widget.isReadOnly,
                      taskColor: widget.taskColor,
                      onToggle: () => widget.onToggleMiniTask(mIdx),
                      onDelete: () => widget.onDeleteMiniTask(mIdx),
                      formatTime: widget.formatTime,
                    );
                  }),

                  // Input de nova mini-task (colapsável, cor verde)
                  if (!widget.isReadOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TaskInputField(
                        placeholder: 'Nova mini-task...',
                        onSubmit: (text) {
                          widget.onAddMiniTask(text);
                          setState(() => _showMiniInput = false);
                        },
                        collapsed: true,
                        accentColor: AppColors.accent,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    // ── Sem swipe em modo leitura ───────────────────────────
    if (widget.isReadOnly) return cardContent;

    // ── Slidable com swipe-left (edição) ────────────────────
    return Slidable(
      key: ValueKey('sub_${widget.subIndex}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.50,
        children: [
          // Ação 1: Adicionar mini-task
          SlidableAction(
            onPressed: (_) {
              setState(() => _showMiniInput = true);
            },
            backgroundColor: AppColors.accent.withValues(alpha: 0.12),
            foregroundColor: AppColors.accent,
            icon: Icons.add_task_rounded,
            label: '+ Mini',
            borderRadius: BorderRadius.circular(12),
          ),
          // Ação 2: Deletar subtask
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: AppColors.taskRed.withValues(alpha: 0.12),
            foregroundColor: AppColors.taskRed,
            icon: Icons.delete_outline_rounded,
            label: 'Apagar',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: cardContent,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Item de Mini-task (Nível 3 — visual menor e mais recuado)
// ══════════════════════════════════════════════════════════════════
class _MiniTaskItem extends StatelessWidget {
  final MiniTask mini;
  final bool isReadOnly;
  final Color taskColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final String Function(DateTime?) formatTime;

  const _MiniTaskItem({
    required this.mini,
    required this.isReadOnly,
    required this.taskColor,
    required this.onToggle,
    required this.onDelete,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = mini.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone hierárquico nível 3 — menor e mais sutil
          GestureDetector(
            onTap: isReadOnly ? null : onToggle,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isDone
                    ? Icon(
                        Icons.done_rounded,
                        key: const ValueKey('mini_done'),
                        color: AppColors.accent.withValues(alpha: 0.7),
                        size: 16,
                      )
                    : Icon(
                        Icons.fiber_manual_record_rounded,
                        key: const ValueKey('mini_active'),
                        color: AppColors.textMuted,
                        size: 10,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Texto menor e mais sutil
          Expanded(
            child: Text(
              mini.text,
              style: TextStyle(
                color: isDone
                    ? AppColors.textMuted
                    : AppColors.textSecondary.withValues(alpha: 0.8),
                fontSize: 12,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),

          // Badge de horário (mini-task)
          if (isDone && mini.completedAt != null)
            _TimePill(time: formatTime(mini.completedAt), small: true),

          // Botão deletar
          if (!isReadOnly)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Pill de horário de conclusão
// ══════════════════════════════════════════════════════════════════
class _TimePill extends StatelessWidget {
  final String time;
  final bool small;

  const _TimePill({required this.time, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_rounded,
            size: small ? 9 : 10,
            color: AppColors.accent,
          ),
          const SizedBox(width: 3),
          Text(
            time,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: small ? 9 : 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Estado vazio
// ══════════════════════════════════════════════════════════════════
class _EmptySubtasks extends StatelessWidget {
  const _EmptySubtasks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.06),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.account_tree_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma subtask ainda',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use o campo abaixo para adicionar',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
