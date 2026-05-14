import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';
import '../../../core/services/image_service.dart';
import 'task_settings_sheet.dart';
import '../task_tree_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class TaskCard extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onColorCycle;
  final VoidCallback onDelete;
  final bool isReadOnly;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onColorCycle,
    required this.onDelete,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  bool _expanded = false;

  Color get _taskColor => switch (widget.task.color) {
    TaskColor.standard => AppColors.taskStandard,
    TaskColor.blue     => AppColors.taskBlue,
    TaskColor.yellow   => AppColors.taskYellow,
    TaskColor.red      => AppColors.taskRed,
  };

  bool get _isDone => widget.task.status == TaskStatus.completed;

  // Task vermelha futura: bloqueada para toggle mas não para outras ações
  bool get _isToggleLocked => widget.isReadOnly ||
      (widget.task.color == TaskColor.red &&
       widget.task.scheduledDate != null &&
       widget.task.scheduledDate!.isAfter(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.task.imageFileName != null;

    return Slidable(
      key: ValueKey(widget.task.id),

      // ── Swipe esquerdo: ações (editar, copiar, foto, tree, apagar) ─
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: widget.isReadOnly ? 0.25 : 0.75,
        children: [
          if (!widget.isReadOnly) ...[
            // Editar texto
            SlidableAction(
              onPressed: (_) async {
                final ctrl = TextEditingController(text: widget.task.text);
                final newText = await showDialog<String>(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Editar Task', style: TextStyle(color: AppColors.textPrimary)),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    content: TextField(
                      controller: ctrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondary)),
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, ctrl.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.background,
                        ),
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                );
                if (newText != null && newText.trim().isNotEmpty && context.mounted) {
                  widget.task.text = newText.trim();
                  final isar = ref.read(isarProvider);
                  await isar.writeTxn(() async => await isar.tasks.put(widget.task));
                  setState(() {});
                }
              },
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.taskBlue,
              icon: Icons.edit_rounded,
            ),
            // Copiar
            SlidableAction(
              onPressed: (_) async {
                await Clipboard.setData(ClipboardData(text: widget.task.text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Texto copiado!', style: TextStyle(color: Colors.white)),
                      backgroundColor: AppColors.secondary,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textSecondary,
              icon: Icons.copy_rounded,
            ),
            // Câmera/Galeria
            SlidableAction(
              onPressed: (_) async {
                final source = await showDialog<ImageSource>(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Imagem', style: TextStyle(color: AppColors.textPrimary)),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt, color: AppColors.taskBlue),
                          title: const Text('Câmera', style: TextStyle(color: AppColors.textPrimary)),
                          onTap: () => Navigator.pop(ctx, ImageSource.camera),
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library, color: AppColors.taskBlue),
                          title: const Text('Galeria', style: TextStyle(color: AppColors.textPrimary)),
                          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                        ),
                      ],
                    ),
                  ),
                );

                if (source != null) {
                  if (widget.task.imageFileName != null) {
                    await ImageService.deleteImage(widget.task.imageFileName!);
                  }
                  final fileName = await ImageService.pickAndSaveImage(
                    widget.task.id.toString(),
                    fromCamera: source == ImageSource.camera,
                  );
                  if (fileName != null && context.mounted) {
                    widget.task.imageFileName = fileName;
                    widget.task.hasImage = true;
                    final isar = ref.read(isarProvider);
                    await isar.writeTxn(() async => await isar.tasks.put(widget.task));
                    setState(() {});
                  }
                }
              },
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textSecondary,
              icon: Icons.camera_alt_rounded,
            ),
          ],

          // Task Tree (disponível sempre, inclusive no modo leitura)
          SlidableAction(
            onPressed: (_) async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskTreeScreen(task: widget.task, isReadOnly: widget.isReadOnly)),
              );
              setState(() {});
            },
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.taskYellow,
            icon: Icons.account_tree_rounded,
          ),

          if (!widget.isReadOnly)
            SlidableAction(
              onPressed: (_) {
                if (widget.task.imageFileName != null) {
                  ImageService.deleteImage(widget.task.imageFileName!);
                }
                widget.onDelete();
              },
              backgroundColor: AppColors.taskRed.withValues(alpha: 0.12),
              foregroundColor: AppColors.taskRed,
              icon: Icons.delete_outline_rounded,
              label: 'Apagar',
              borderRadius: BorderRadius.circular(12),
            ),
        ],
      ),

      // ── Swipe direito: Calendário (→vermelho) para tasks amarelas,
      //                   Frequência para tasks azuis.
      //                   Não aparece para tasks vermelhas. ─────────
      startActionPane: (!widget.isReadOnly &&
              widget.task.color != TaskColor.red)
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                if (widget.task.color == TaskColor.blue)
                  // Azul: ajustar frequência
                  SlidableAction(
                    onPressed: (_) => TaskSettingsSheet.show(context, widget.task),
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.taskBlue,
                    icon: Icons.repeat_rounded,
                    label: 'Freq',
                    borderRadius: BorderRadius.circular(12),
                  )
                else
                  // Branco/Amarelo: agendar como vermelho
                  SlidableAction(
                    onPressed: (_) async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: widget.task.scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppColors.taskRed,
                              onPrimary: Colors.white,
                              surface: AppColors.background,
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null && context.mounted) {
                        await ref.read(routineServiceProvider).setTaskRed(widget.task, date);
                        setState(() {});
                      }
                    },
                    backgroundColor: AppColors.taskRed.withValues(alpha: 0.12),
                    foregroundColor: AppColors.taskRed,
                    icon: Icons.calendar_today_rounded,
                    label: 'Agendar',
                    borderRadius: BorderRadius.circular(12),
                  ),
              ],
            )
          : null,

      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDone
                ? AppColors.border
                : _taskColor.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Row(children: [
              // ── Color dot (ciclo branco→azul→amarelo→branco) ────
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isToggleLocked || widget.isReadOnly ? null : () {
                  // Loop de cores: standard → blue → yellow → standard
                  // Vermelho: resetar para standard (via clearTaskRed)
                  if (widget.task.color == TaskColor.red) {
                    // Não deveria ocorrer (swipe não aparece para red),
                    // mas como fallback, volta para branco
                    ref.read(routineServiceProvider).clearTaskRed(widget.task).then((_) => setState(() {}));
                  } else {
                    widget.onColorCycle();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isDone ? AppColors.textMuted : _taskColor,
                    boxShadow: _isDone
                        ? null
                        : AppColors.glowShadow(_taskColor, intensity: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Task text & Indicators ──────────────────────────
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.task.hasSubtasks
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  onDoubleTap: hasImage ? () async {
                    final file = await ImageService.getImageFile(widget.task.imageFileName!);
                    if (file != null && context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: EdgeInsets.zero,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: InteractiveViewer(
                              child: Image.file(file, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      );
                    }
                  } : null,
                  onLongPress: widget.isReadOnly ? null :
                      (widget.task.color == TaskColor.blue)
                          ? () => TaskSettingsSheet.show(context, widget.task)
                          : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.task.text,
                            style: TextStyle(
                              color: _isDone ? AppColors.textMuted : AppColors.textPrimary,
                              fontSize: 14,
                              decoration: _isDone ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.textMuted,
                            ),
                          ),
                        ),
                        // Indicadores
                        if (hasImage)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.image_outlined, size: 14, color: AppColors.textMuted),
                          ),
                        if (widget.task.hasSubtasks)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.account_tree_outlined, size: 14, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Countdown badge (task vermelha) ─────────────────
              if (widget.task.color == TaskColor.red && widget.task.scheduledDate != null)
                _CountdownBadge(scheduledDate: widget.task.scheduledDate!),

              // ── Checkbox ────────────────────────────────────────
              GestureDetector(
                onTap: _isToggleLocked ? null : widget.onToggle,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDone ? _taskColor.withValues(alpha: 0.15) : Colors.transparent,
                      border: Border.all(
                        color: _isToggleLocked ? AppColors.textMuted : _taskColor,
                        width: 1.5,
                      ),
                      boxShadow: _isDone
                          ? AppColors.glowShadow(_taskColor, intensity: 0.4)
                          : null,
                    ),
                    child: _isDone
                        ? Icon(Icons.check, size: 14, color: _taskColor)
                        : null,
                  ),
                ),
              ),
            ]),

            // ── Subtasks Expandables ────────────────────────────
            if (_expanded && widget.task.hasSubtasks)
              Padding(
                padding: const EdgeInsets.only(left: 36, right: 12, bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.task.subtasks.map((sub) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          sub.isCompleted
                              ? Icons.check_circle_outline_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: sub.isCompleted
                              ? AppColors.accent
                              : _taskColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.text,
                            style: TextStyle(
                              color: sub.isCompleted ? AppColors.textMuted : AppColors.textSecondary,
                              fontSize: 13,
                              decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (sub.isCompleted && sub.completedAt != null)
                          Text(
                            '${sub.completedAt!.hour.toString().padLeft(2, '0')}:${sub.completedAt!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    ).animate().fade(duration: 200.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

class _CountdownBadge extends StatelessWidget {
  final DateTime scheduledDate;
  const _CountdownBadge({required this.scheduledDate});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final diff = scheduledDate
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final label = diff == 0 ? 'Hoje!' : diff < 0 ? 'Atrasado' : '${diff}d';
    final isToday = diff == 0;
    final isOverdue = diff < 0;
    final badgeColor = isOverdue ? AppColors.taskRed : AppColors.taskRed;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isToday || isOverdue ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: isToday || isOverdue ? 0.7 : 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: isToday || isOverdue ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
  }
}
