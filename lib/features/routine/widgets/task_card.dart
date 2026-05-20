import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';
import '../../../core/services/image_service.dart';
import 'task_settings_sheet.dart';
import 'alarm_sheet.dart';
import '../task_tree_screen.dart';
import '../../../shared/widgets/blur_confirm_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/xp_service.dart';
import 'dart:ui' as ui;

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
  bool _wasDone = false;
  bool _showXpFloat = false;

  @override
  void initState() {
    super.initState();
    _wasDone = widget.task.status == TaskStatus.completed;
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isDoneNow = widget.task.status == TaskStatus.completed;
    if (!_wasDone && isDoneNow && !widget.isReadOnly) {
      // Tarefa foi completada agora
      setState(() => _showXpFloat = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showXpFloat = false);
      });
    }
    _wasDone = isDoneNow;
  }

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

  // Fundo do card tematizado pela cor da task
  Color get _cardBgColor => switch (widget.task.color) {
    TaskColor.standard => AppColors.card,
    TaskColor.blue     => AppColors.cardBlue,
    TaskColor.yellow   => AppColors.cardYellow,
    TaskColor.red      => AppColors.cardRed,
  };

  // Label da pílula de cor
  String get _colorLabel => switch (widget.task.color) {
    TaskColor.standard => 'STD',
    TaskColor.blue     => 'FREQ',
    TaskColor.yellow   => 'PEND',
    TaskColor.red      => 'DATA',
  };


  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.task.imageFileName != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Slidable(
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
                // M11: criar controller e garantir dispose ap\u00f3s o dialog fechar
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
                ctrl.dispose(); // M11: dispose do controller ap\u00f3s dialog
                 if (newText != null && newText.trim().isNotEmpty && context.mounted) {
                  widget.task.text = newText.trim();
                  if (widget.task.color == TaskColor.blue) {
                    widget.task.createdAt = DateTime.now(); // M6: Reset cadence reference on text edit
                  }
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
                  builder: (ctx) => BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.taskBlue.withValues(alpha: 0.5)),
                          boxShadow: AppColors.glowShadow(AppColors.taskBlue, intensity: 0.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Anexar Imagem',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            ListTile(
                              leading: const Icon(Icons.camera_alt, color: AppColors.taskBlue),
                              title: const Text('Câmera', style: TextStyle(color: AppColors.textPrimary)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              tileColor: AppColors.taskBlue.withValues(alpha: 0.1),
                              onTap: () => Navigator.pop(ctx, ImageSource.camera),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.photo_library, color: AppColors.taskBlue),
                              title: const Text('Galeria', style: TextStyle(color: AppColors.textPrimary)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              tileColor: AppColors.taskBlue.withValues(alpha: 0.1),
                              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                            ),
                          ],
                        ),
                      ),
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
                showDialog(
                  context: context,
                  builder: (_) => BlurConfirmDialog(
                    title: 'Apagar Tarefa',
                    message: 'Deseja apagar esta tarefa permanentemente?',
                    confirmLabel: 'Apagar',
                    onConfirm: () {
                      if (widget.task.imageFileName != null) {
                        ImageService.deleteImage(widget.task.imageFileName!);
                      }
                      widget.onDelete();
                    },
                  ),
                );
              },
              backgroundColor: AppColors.taskRed.withValues(alpha: 0.12),
              foregroundColor: AppColors.taskRed,
              icon: Icons.delete_outline_rounded,
              label: 'Apagar',
              borderRadius: BorderRadius.circular(12),
            ),
        ],
      ),

      // ── Swipe direito ─────────────────────────────────────────
      // Branco   → [Alarme]
      // Amarelo  → [Calendário] + [Alarme]
      // Azul     → [Freq]
      // Vermelho → sem startPane
      startActionPane: (!widget.isReadOnly &&
              widget.task.color != TaskColor.red)
          ? ActionPane(
              motion: const DrawerMotion(),
              // 2 acões para amarelo (50%), 1 para os demais (25%)
              extentRatio:
                  widget.task.color == TaskColor.yellow ? 0.50 : 0.25,
              children: [
                // ── Azul: Frequência ────────────────────────────
                if (widget.task.color == TaskColor.blue)
                  SlidableAction(
                    onPressed: (_) =>
                        TaskSettingsSheet.show(context, widget.task),
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.taskBlue,
                    icon: Icons.repeat_rounded,
                    label: 'Freq',
                    borderRadius: BorderRadius.circular(12),
                  )
                else ...[
                  // ── Branco/Amarelo: Calendário (→ vermelha) ────────
                  if (widget.task.color == TaskColor.yellow)
                    SlidableAction(
                      onPressed: (_) async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: widget.task.scheduledDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
                          await ref
                              .read(routineServiceProvider)
                              .setTaskRed(widget.task, date);
                          setState(() {});
                        }
                      },
                      backgroundColor:
                          AppColors.taskRed.withValues(alpha: 0.12),
                      foregroundColor: AppColors.taskRed,
                      icon: Icons.calendar_today_rounded,
                      label: 'Agendar',
                    ),

                  // ── Branco + Amarelo: Alarme ──────────────────────
                  SlidableAction(
                    onPressed: (_) =>
                        AlarmSheet.show(context, widget.task),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    foregroundColor: AppColors.primary,
                    icon: widget.task.hasAlarm
                        ? Icons.alarm_on_rounded
                        : Icons.alarm_add_rounded,
                    label: widget.task.hasAlarm ? 'Alarme ✓' : 'Alarme',
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ],
            )
          : null,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _isDone ? AppColors.card : _cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDone
                ? AppColors.border
                : _taskColor, // Borda sólida Peak
            width: _isDone ? 0.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(children: [
              // ── Color pill button ──────────────────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.isReadOnly || _isDone || _isToggleLocked ? null : () {
                  HapticFeedback.selectionClick();
                  if (widget.task.color == TaskColor.red) {
                    ref.read(routineServiceProvider).clearTaskRed(widget.task)
                        .then((_) => setState(() {}));
                  } else {
                    widget.onColorCycle();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isDone
                          ? AppColors.surfaceVariant
                          : AppColors.surfaceVariant, // Fundo escuro sólido Peak
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isDone
                            ? AppColors.textMuted.withValues(alpha: 0.3)
                            : _taskColor, // Borda sólida brilhante
                        width: 1.5, // Levemente mais espessa para compensar falta de preenchimento
                      ),
                      boxShadow: _isDone ? null : [
                        BoxShadow(
                          color: _taskColor.withValues(alpha: 0.2),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isDone ? AppColors.textMuted : _taskColor,
                          ),
                        ),
                        if (!widget.isReadOnly && !_isDone) ...[
                          const SizedBox(width: 5),
                          Text(
                            _colorLabel,
                            style: TextStyle(
                              color: _taskColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── Task text & Indicators ──────────────────────────
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
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
                           Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Alarme badge ────────────────────────────────────
              if (widget.task.hasAlarm && !_isDone)
                _AlarmBadge(alarmTime: widget.task.alarmTime!),

              // ── Countdown badge (task vermelha) ─────────────────
              if (widget.task.color == TaskColor.red && widget.task.scheduledDate != null)
                _CountdownBadge(scheduledDate: widget.task.scheduledDate!),

              // ── Checkbox & +XP Float ─────────────────────────────
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: _isToggleLocked ? null : widget.onToggle,
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isDone ? _taskColor : AppColors.surfaceVariant, // Cor sólida
                          border: Border.all(
                            color: _isToggleLocked ? AppColors.textMuted : _taskColor,
                            width: 1.5,
                          ),
                          boxShadow: _isDone
                              ? AppColors.glowShadow(_taskColor, intensity: 0.5)
                              : null,
                        ),
                        child: _isDone
                            ? const Icon(Icons.check_rounded, size: 15, color: AppColors.card) // check escuro
                            : null,
                      ),
                    ),
                  ),
                  if (_showXpFloat)
                    Positioned(
                      top: -10,
                      child: Text(
                        '+${XpService.xpForAction(widget.task.color)} XP',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          .animate()
                          .fade(duration: 200.ms)
                          .moveY(begin: 0, end: -30, duration: 800.ms, curve: Curves.easeOut)
                          .fadeOut(delay: 500.ms, duration: 300.ms),
                    ),
                ],
              ),
            ]),

            // ── Subtasks Expandables ────────────────────────────
            if (_expanded && widget.task.hasSubtasks)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: _taskColor.withValues(alpha: 0.15),
                      thickness: 0.5,
                      height: 12,
                    ),
                    ...widget.task.subtasks.map((sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            sub.isCompleted
                                ? Icons.check_circle_outline_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 15,
                            color: sub.isCompleted
                                ? AppColors.accent
                                : _taskColor.withValues(alpha: 0.6),
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
                    )),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
    ).animate(key: ValueKey('anim_task_${widget.task.id}')).fade(duration: 200.ms).slideX(begin: 0.04, end: 0, curve: Curves.easeOut);
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
    const badgeColor = AppColors.taskRed;

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

/// Badge que mostra o horário do alarme no card da task.
class _AlarmBadge extends StatelessWidget {
  final DateTime alarmTime;
  const _AlarmBadge({required this.alarmTime});

  @override
  Widget build(BuildContext context) {
    final h = alarmTime.hour.toString().padLeft(2, '0');
    final m = alarmTime.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.alarm_on_rounded, size: 11, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '$h:$m',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
