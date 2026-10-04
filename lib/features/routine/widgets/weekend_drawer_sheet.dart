import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_config.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/blur_confirm_dialog.dart';

/// Gatilho reativo com DragTarget para a aba de Fim de Semana
class WeekendTabTrigger extends ConsumerStatefulWidget {
  final int routineId;
  const WeekendTabTrigger({super.key, required this.routineId});

  @override
  ConsumerState<WeekendTabTrigger> createState() => _WeekendTabTriggerState();
}

class _WeekendTabTriggerState extends ConsumerState<WeekendTabTrigger> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHovered = false;
  bool _justDropped = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final isDragging = ref.watch(isDraggingTaskProvider);
    final weekendTasksAsync = ref.watch(weekendTasksProvider);
    final taskCount = weekendTasksAsync.valueOrNull?.length ?? 0;

    if (isDragging && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isDragging && _pulseController.isAnimating && !_isHovered && !_justDropped) {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DragTarget<Task>(
        onWillAcceptWithDetails: (details) {
          if (details.data.status == TaskStatus.completed) {
            return false;
          }
          if (!_isHovered) {
            HapticFeedback.selectionClick();
            setState(() => _isHovered = true);
          }
          return true;
        },
        onLeave: (_) {
          if (_isHovered) {
            setState(() => _isHovered = false);
          }
        },
        onAcceptWithDetails: (details) async {
          setState(() {
            _isHovered = false;
            _justDropped = true;
          });
          HapticFeedback.mediumImpact();
          final task = details.data;
          await ref.read(routineServiceProvider).moveToWeekendBacklog(task.id);
          ref.invalidate(routineDaysProvider(widget.routineId));
          ref.invalidate(weekendTasksProvider);

          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _justDropped = false);
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: theme.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.color != TaskColor.standard
                            ? '"${task.text}" movida para o Fim de Semana (convertida em tarefa padrão).'
                            : '"${task.text}" agendada para o Fim de Semana!',
                        style: theme.fontStyleBase(const TextStyle(color: Colors.white)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: theme.surface,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isTargetHovered = candidateData.isNotEmpty || _isHovered;

          return ScaleTransition(
            scale: _justDropped 
                ? const AlwaysStoppedAnimation(1.03) 
                : (isTargetHovered ? const AlwaysStoppedAnimation(1.04) : (isDragging ? _pulseAnimation : const AlwaysStoppedAnimation(1.0))),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _justDropped
                      ? [
                          theme.accent.withValues(alpha: 0.35),
                          theme.accent.withValues(alpha: 0.15),
                        ]
                      : (isTargetHovered
                          ? [
                              theme.secondary.withValues(alpha: 0.35),
                              theme.secondary.withValues(alpha: 0.18),
                            ]
                          : (isDragging
                              ? [
                                  theme.surfaceVariant.withValues(alpha: 0.95),
                                  theme.secondary.withValues(alpha: 0.15),
                                ]
                              : [
                                  theme.surface.withValues(alpha: 0.85),
                                  theme.surfaceVariant.withValues(alpha: 0.65),
                                ])),
                ),
                borderRadius: BorderRadius.circular(theme.borderRadius > 14 ? 14 : theme.borderRadius),
                border: Border.all(
                  color: _justDropped
                      ? theme.accent
                      : (isTargetHovered
                          ? theme.secondary
                          : (isDragging ? theme.secondary.withValues(alpha: 0.6) : theme.border)),
                  width: (_justDropped || isTargetHovered) ? 2.0 : 1.0,
                ),
                boxShadow: _justDropped
                    ? theme.glowShadow(theme.accent, intensity: 0.70)
                    : (isTargetHovered
                        ? theme.glowShadow(theme.secondary, intensity: 0.65)
                        : (isDragging ? theme.glowShadow(theme.secondary, intensity: 0.25) : null)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => WeekendDrawerSheet.show(context, widget.routineId),
                  borderRadius: BorderRadius.circular(theme.borderRadius > 14 ? 14 : theme.borderRadius),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _justDropped
                                ? theme.accent
                                : (isTargetHovered
                                    ? theme.secondary
                                    : theme.secondary.withValues(alpha: 0.15)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _justDropped
                                ? Icons.check_rounded
                                : Icons.weekend_rounded,
                            size: 16,
                            color: (_justDropped || isTargetHovered) ? Colors.white : theme.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _justDropped
                                    ? 'Task Absorvida! ✨'
                                    : (isTargetHovered
                                        ? 'Solte para o Fim de Semana ✨'
                                        : 'Aba de Fim de Semana'),
                                style: theme.fontStyleBase(TextStyle(
                                  color: _justDropped 
                                      ? theme.accent 
                                      : (isTargetHovered ? theme.secondary : theme.textPrimary),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                )),
                              ),
                              Text(
                                _justDropped
                                    ? 'Agendada com sucesso para o sábado'
                                    : (isTargetHovered
                                        ? 'Aparece no sábado como task branca'
                                        : (isDragging
                                            ? 'Arraste a task até aqui'
                                            : (taskCount == 0 ? 'Nenhuma task agendada' : '$taskCount ${taskCount == 1 ? 'task agendada' : 'tasks agendadas'}'))),
                                style: theme.fontStyleBase(TextStyle(
                                  color: _justDropped
                                      ? theme.accent.withValues(alpha: 0.9)
                                      : (isTargetHovered ? theme.secondary.withValues(alpha: 0.9) : theme.textMuted),
                                  fontSize: 10,
                                )),
                              ),
                            ],
                          ),
                        ),
                        if (taskCount > 0 && !isTargetHovered && !_justDropped) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.secondary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '$taskCount',
                              style: theme.fontStyleMono(TextStyle(
                                color: theme.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              )),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: _justDropped 
                              ? theme.accent 
                              : (isTargetHovered ? theme.secondary : theme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Modal Bottom Sheet exibindo a gestão completa das tasks de fim de semana
class WeekendDrawerSheet extends ConsumerStatefulWidget {
  final int routineId;
  const WeekendDrawerSheet({super.key, required this.routineId});

  static Future<void> show(BuildContext context, int routineId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      // useSafeArea garante que o sheet não fique atrás da nav bar
      useSafeArea: false,
      builder: (context) {
        final mq = MediaQuery.of(context);
        // viewInsets.bottom = teclado visível
        // viewPadding.bottom = barra de navegação do Android (gesture bar ou botões)
        final bottomInset = mq.viewInsets.bottom + mq.viewPadding.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: WeekendDrawerSheet(routineId: routineId),
        );
      },
    );
  }

  @override
  ConsumerState<WeekendDrawerSheet> createState() => _WeekendDrawerSheetState();
}

class _WeekendDrawerSheetState extends ConsumerState<WeekendDrawerSheet> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAdding = false;

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitNewTask() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isAdding) return;

    setState(() => _isAdding = true);
    try {
      await ref.read(routineServiceProvider).addWeekendTask(text);
      _inputController.clear();
      ref.invalidate(weekendTasksProvider);
      ref.invalidate(routineDaysProvider(widget.routineId));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final tasksAsync = ref.watch(weekendTasksProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(theme.borderRadius > 22 ? 22 : theme.borderRadius)),
        border: Border(top: BorderSide(color: theme.border, width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.weekend_rounded, color: theme.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks do Fim de Semana',
                        style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary),
                      ),
                      Text(
                        'Aparecem no sábado como tasks brancas',
                        style: theme.fontStyleBase(AppTextStyles.bodySmall).copyWith(color: theme.textMuted),
                      ),
                    ],
                  ),
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
          ),

          // ── Regra explicativa ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: theme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se não concluídas no sábado, passam para o domingo. Se não feitas no domingo, pulam para o próximo fim de semana.',
                      style: theme.fontStyleBase(TextStyle(
                        color: theme.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Campo para nova task ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.border),
                    ),
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 13)),
                      decoration: InputDecoration(
                        hintText: 'Adicionar task de fim de semana...',
                        hintStyle: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 13)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submitNewTask(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: theme.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                  onPressed: _submitNewTask,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Lista de Tasks ──────────────────────────────────
          Flexible(
            child: tasksAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Erro: $e', style: theme.fontStyleBase(TextStyle(color: theme.taskRed))),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.weekend_outlined, size: 40, color: theme.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          'Nenhuma task no backlog de fim de semana',
                          style: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 13)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Arraste uma task da sua rotina ou digite acima para agendar.',
                          style: theme.fontStyleBase(TextStyle(color: theme.textMuted.withValues(alpha: 0.7), fontSize: 11)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).viewPadding.bottom),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    return _WeekendTaskCard(
                      task: t,
                      theme: theme,
                      onToggle: () async {
                        await ref.read(routineServiceProvider).toggleTask(t);
                        ref.invalidate(weekendTasksProvider);
                        ref.invalidate(routineDaysProvider(widget.routineId));
                      },
                      onDelete: () async {
                        await ref.read(routineServiceProvider).deleteWeekendTask(t.id);
                        ref.invalidate(weekendTasksProvider);
                        ref.invalidate(routineDaysProvider(widget.routineId));
                      },
                      onEdit: () async {
                        await _WeekendEditSheet.show(context, t);
                        ref.invalidate(weekendTasksProvider);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card de task de fim de semana ────────────────────────────────────────────
class _WeekendTaskCard extends StatefulWidget {
  final Task task;
  final AppThemeData theme;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _WeekendTaskCard({
    required this.task,
    required this.theme,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_WeekendTaskCard> createState() => _WeekendTaskCardState();
}

class _WeekendTaskCardState extends State<_WeekendTaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final theme = widget.theme;
    final isCompleted = t.status == TaskStatus.completed;
    final hasSubtasks = t.subtasks.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isCompleted ? theme.surfaceVariant.withValues(alpha: 0.6) : theme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCompleted ? theme.border.withValues(alpha: 0.5) : theme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? theme.accent : Colors.transparent,
                      border: Border.all(
                        color: isCompleted ? theme.accent : theme.border,
                        width: 1.5,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: hasSubtasks ? () => setState(() => _expanded = !_expanded) : widget.onToggle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.text,
                          style: theme.fontStyleBase(TextStyle(
                            color: isCompleted ? theme.textMuted : theme.textPrimary,
                            fontSize: 13,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          )),
                        ),
                        if (hasSubtasks)
                          Text(
                            '${t.subtasks.length} subtask${t.subtasks.length > 1 ? 's' : ''}  •  toque para ver',
                            style: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                ),
                if (hasSubtasks)
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: theme.textMuted,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: theme.textMuted),
                  onPressed: widget.onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Editar task',
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: theme.textMuted),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => BlurConfirmDialog(
                      title: 'Remover Task',
                      message: 'Deseja remover esta task do fim de semana?',
                      confirmLabel: 'Remover',
                      onConfirm: widget.onDelete,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (_expanded && hasSubtasks)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(34, 0, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: t.subtasks.map((sub) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        sub.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: sub.isCompleted ? theme.secondary : theme.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sub.text,
                          style: theme.fontStyleBase(TextStyle(
                            color: sub.isCompleted ? theme.textMuted : theme.textSecondary,
                            fontSize: 12,
                            decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                          )),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sheet de edicao de task de fim de semana ─────────────────────────────────
class _WeekendEditSheet extends ConsumerStatefulWidget {
  final Task task;
  const _WeekendEditSheet({required this.task});

  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: _WeekendEditSheet(task: task),
      ),
    );
  }

  @override
  ConsumerState<_WeekendEditSheet> createState() => _WeekendEditSheetState();
}

class _WeekendEditSheetState extends ConsumerState<_WeekendEditSheet> {
  late TextEditingController _textController;
  late List<TextEditingController> _subtaskControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.task.text);
    _subtaskControllers = widget.task.subtasks
        .map((s) => TextEditingController(text: s.text))
        .toList();
  }

  @override
  void dispose() {
    _textController.dispose();
    for (final c in _subtaskControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(routineServiceProvider).updateWeekendTask(
        widget.task.id,
        text,
        _subtaskControllers.map((c) => c.text).toList(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.borderRadius > 22 ? 22 : theme.borderRadius),
        ),
        border: Border(top: BorderSide(color: theme.border)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: theme.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar Task de Fim de Semana',
                  style: theme.fontStyleBase(const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))
                      .copyWith(color: theme.textPrimary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: theme.surfaceVariant, shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded, size: 18, color: theme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Nome', style: theme.fontStyleBase(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)).copyWith(color: theme.textMuted)),
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
                autofocus: true,
                style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 14)),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
            if (widget.task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Subtasks', style: theme.fontStyleBase(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)).copyWith(color: theme.textMuted)),
              const SizedBox(height: 8),
              ...List.generate(widget.task.subtasks.length, (i) {
                final sub = widget.task.subtasks[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sub.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: sub.isCompleted ? theme.secondary : theme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _subtaskControllers[i],
                          style: theme.fontStyleBase(TextStyle(
                            color: theme.textPrimary,
                            fontSize: 13,
                            decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                          )),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Salvar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
