import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../core/theme/theme_config.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/alarm_service.dart';
import 'task_settings_sheet.dart';
import 'alarm_sheet.dart';
import '../task_tree_screen.dart';
import '../../focus/focus_screen.dart';
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
  final String? divisionName;
  final bool showRadarInfo;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onColorCycle,
    required this.onDelete,
    this.isReadOnly = false,
    this.divisionName,
    this.showRadarInfo = false,
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
      setState(() => _showXpFloat = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showXpFloat = false);
      });
    }
    _wasDone = isDoneNow;
  }

  Color _getTaskColor(AppThemeData theme, TaskColor color) => switch (color) {
    TaskColor.standard => theme.taskStandard,
    TaskColor.blue     => theme.taskBlue,
    TaskColor.yellow   => theme.taskYellow,
    TaskColor.red      => theme.taskRed,
  };

  bool get _isDone => widget.task.status == TaskStatus.completed;

  bool get _isToggleLocked => widget.isReadOnly ||
      (widget.task.color == TaskColor.red &&
       widget.task.scheduledDate != null &&
       widget.task.scheduledDate!.isAfter(DateTime.now()));

  Color _getCardBgColor(AppThemeData theme, TaskColor color) => switch (color) {
    TaskColor.standard => theme.cardStandard,
    TaskColor.blue     => theme.cardBlue,
    TaskColor.yellow   => theme.cardYellow,
    TaskColor.red      => theme.cardRed,
  };

  String get _colorLabel => switch (widget.task.color) {
    TaskColor.standard => 'STD',
    TaskColor.blue     => 'FREQ',
    TaskColor.yellow   => 'PEND',
    TaskColor.red      => 'DATA',
  };

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final taskColor = _getTaskColor(theme, widget.task.color);
    final cardBg = _getCardBgColor(theme, widget.task.color);
    final bool hasImage = widget.task.imageFileName != null;

    final double activeBorderRadius = theme.borderRadius;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(activeBorderRadius),
        child: Slidable(
        key: ValueKey('slidable_${widget.task.id}_${widget.task.color.name}_${widget.task.status.name}'),

      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: widget.isReadOnly ? 0.25 : 0.75,
        children: [
          if (!widget.isReadOnly) ...[
            SlidableAction(
              onPressed: (_) async {
                final ctrl = TextEditingController(text: widget.task.text);
                final newText = await showDialog<String>(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: theme.surface,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Editar Task', style: theme.fontStyleBase(TextStyle(color: theme.textPrimary))),
                        IconButton(
                          icon: Icon(Icons.close, color: theme.textMuted, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    content: TextField(
                      controller: ctrl,
                      style: theme.fontStyleBase(TextStyle(color: theme.textPrimary)),
                      decoration: InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.border)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.secondary)),
                      ),
                      autofocus: true,
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, ctrl.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.secondary,
                          foregroundColor: theme.background,
                        ),
                        child: Text('Salvar', style: theme.fontStyleBase(const TextStyle(fontWeight: FontWeight.bold))),
                      ),
                    ],
                  ),
                );
                ctrl.dispose();
                if (newText != null && newText.trim().isNotEmpty && context.mounted) {
                  final trimmed = newText.trim();
                  final originalText = widget.task.text;
                  final originalCreatedAt = widget.task.createdAt;
                  
                  widget.task.text = trimmed;
                  if (widget.task.color == TaskColor.blue) {
                    widget.task.createdAt = DateTime.now();
                  }
                  
                  try {
                    final isar = ref.read(isarProvider);
                    await isar.writeTxn(() async => await isar.tasks.put(widget.task));
                    if (mounted) {
                      setState(() {});
                    }
                  } catch (e) {
                    widget.task.text = originalText;
                    widget.task.createdAt = originalCreatedAt;
                    rethrow;
                  }
                }
              },
              backgroundColor: theme.surface,
              foregroundColor: theme.taskBlue,
              icon: Icons.edit_rounded,
              padding: EdgeInsets.zero,
            ),
            SlidableAction(
              onPressed: (_) async {
                await Clipboard.setData(ClipboardData(text: widget.task.text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Texto copiado!', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
                      backgroundColor: theme.secondary,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              backgroundColor: theme.surface,
              foregroundColor: theme.textSecondary,
              icon: Icons.copy_rounded,
              padding: EdgeInsets.zero,
            ),
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
                          color: theme.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.taskBlue.withValues(alpha: 0.5)),
                          boxShadow: theme.glowShadow(theme.taskBlue, intensity: 0.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Anexar Imagem',
                                style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
                            const SizedBox(height: 24),
                            ListTile(
                              leading: Icon(Icons.camera_alt, color: theme.taskBlue),
                              title: Text('Câmera', style: theme.fontStyleBase(TextStyle(color: theme.textPrimary))),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              tileColor: theme.taskBlue.withValues(alpha: 0.1),
                              onTap: () => Navigator.pop(ctx, ImageSource.camera),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: Icon(Icons.photo_library, color: theme.taskBlue),
                              title: Text('Galeria', style: theme.fontStyleBase(TextStyle(color: theme.textPrimary))),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              tileColor: theme.taskBlue.withValues(alpha: 0.1),
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
              backgroundColor: theme.surface,
              foregroundColor: theme.textSecondary,
              icon: Icons.camera_alt_rounded,
              padding: EdgeInsets.zero,
            ),
          ],

          SlidableAction(
            onPressed: (_) async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TaskTreeScreen(task: widget.task, isReadOnly: widget.isReadOnly)),
              );
              setState(() {});
            },
            backgroundColor: theme.surface,
            foregroundColor: theme.taskYellow,
            icon: Icons.account_tree_rounded,
            padding: EdgeInsets.zero,
          ),

          SlidableAction(
            onPressed: (_) async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FocusScreen(task: widget.task)),
              );
              setState(() {});
            },
            backgroundColor: theme.surface,
            foregroundColor: theme.accent,
            icon: Icons.timer_rounded,
            padding: EdgeInsets.zero,
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
              backgroundColor: theme.taskRed.withValues(alpha: 0.12),
              foregroundColor: theme.taskRed,
              icon: Icons.delete_outline_rounded,
              padding: EdgeInsets.zero,
            ),
        ],
      ),

      startActionPane: (!widget.isReadOnly &&
              widget.task.color != TaskColor.red)
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: widget.task.color == TaskColor.blue ? 0.75 : 0.50,
              children: [
                if (widget.task.color == TaskColor.blue)
                  SlidableAction(
                    onPressed: (_) =>
                        TaskSettingsSheet.show(context, widget.task),
                    backgroundColor: theme.surface,
                    foregroundColor: theme.taskBlue,
                    icon: Icons.repeat_rounded,
                    padding: EdgeInsets.zero,
                  ),

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
                          colorScheme: ColorScheme.dark(
                            primary: theme.taskRed,
                            onPrimary: Colors.white,
                            surface: theme.background,
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
                      theme.taskRed.withValues(alpha: 0.12),
                  foregroundColor: theme.taskRed,
                  icon: Icons.calendar_today_rounded,
                  padding: EdgeInsets.zero,
                ),

                SlidableAction(
                  onPressed: (_) =>
                      AlarmSheet.show(context, widget.task),
                  backgroundColor: theme.primary.withValues(alpha: 0.12),
                  foregroundColor: theme.primary,
                  icon: widget.task.hasAlarm
                      ? Icons.alarm_on_rounded
                      : Icons.alarm_add_rounded,
                  padding: EdgeInsets.zero,
                ),
              ],
            )
          : null,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _isDone ? theme.card : cardBg,
          borderRadius: BorderRadius.circular(activeBorderRadius),
          border: Border.all(
            color: _isDone
                ? theme.border
                : theme.useGlowBorder ? taskColor : taskColor.withValues(alpha: 0.4),
            width: _isDone ? 0.5 : theme.borderWidth,
          ),
          boxShadow: (_isDone || !theme.useGlowBorder) ? null : theme.glowShadow(taskColor, intensity: 0.35),
        ),
        child: Column(
          children: [
            Row(children: [
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
                      color: theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isDone
                            ? theme.textMuted.withValues(alpha: 0.3)
                            : taskColor,
                        width: 1.5,
                      ),
                      boxShadow: (_isDone || !theme.useGlowBorder) ? null : [
                        BoxShadow(
                          color: taskColor.withValues(alpha: 0.2),
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
                            color: _isDone ? theme.textMuted : taskColor,
                          ),
                        ),
                        if (!widget.isReadOnly && !_isDone) ...[
                          const SizedBox(width: 5),
                          Text(
                            _colorLabel,
                            style: theme.fontStyleBase(TextStyle(
                              color: taskColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            )),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

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
                  onLongPress: widget.isReadOnly
                      ? null
                      : () => TaskSettingsSheet.show(context, widget.task),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.task.text,
                                style: theme.fontStyleBase(TextStyle(
                                  color: _isDone ? theme.textMuted : theme.textPrimary,
                                  fontSize: 14,
                                  decoration: _isDone ? TextDecoration.lineThrough : null,
                                  decorationColor: theme.textMuted,
                                )),
                              ),
                              if (widget.divisionName != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  widget.divisionName!.toUpperCase(),
                                  style: theme.fontStyleBase(TextStyle(
                                    color: _isDone
                                        ? theme.textMuted
                                        : taskColor.withValues(alpha: 0.75),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  )),
                                ),
                              ],
                              if (widget.showRadarInfo) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 2,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Criada em: ${DateFormat('dd/MM/yyyy').format(widget.task.createdAt)}',
                                      style: theme.fontStyleBase(TextStyle(
                                        color: theme.textSecondary,
                                        fontSize: 10,
                                      )),
                                    ),
                                    if (widget.task.color == TaskColor.red && widget.task.scheduledDate != null)
                                      Text(
                                        '·  Agendada: ${DateFormat('dd/MM/yyyy').format(widget.task.scheduledDate!)}',
                                        style: theme.fontStyleBase(TextStyle(
                                          color: theme.taskRed,
                                          fontSize: 10,
                                        )),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (hasImage)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.image_outlined, size: 14, color: theme.textMuted),
                          ),
                        if (widget.task.hasSubtasks) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              '${widget.task.subtasks.where((s) => s.isCompleted).length}/${widget.task.subtasks.length}',
                              style: theme.fontStyleMono(TextStyle(
                                color: theme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              )),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Icon(
                              _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              if (widget.task.hasAlarm && !_isDone)
                _AlarmBadge(alarmTime: widget.task.alarmTime!),

              if (widget.task.color == TaskColor.red && widget.task.scheduledDate != null) ...[
                IconButton(
                  icon: Icon(Icons.calendar_month_rounded, size: 16, color: theme.taskRed),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: widget.task.scheduledDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: theme.taskRed,
                            onPrimary: Colors.white,
                            surface: theme.background,
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null && context.mounted) {
                      widget.task.scheduledDate = date;
                      final isar = ref.read(isarProvider);
                      await isar.writeTxn(() async {
                        await isar.tasks.put(widget.task);
                      });
                      await AlarmService.scheduleRedTaskNotification(widget.task);
                      ref.invalidate(radarProvider);
                      setState(() {});
                    }
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                _CountdownBadge(scheduledDate: widget.task.scheduledDate!),
              ],

              if (!widget.isReadOnly || _isDone)
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
                            color: _isDone ? taskColor : theme.surfaceVariant,
                            border: Border.all(
                              color: _isToggleLocked ? theme.textMuted : taskColor,
                              width: 1.5,
                            ),
                            boxShadow: (_isDone && theme.useGlowBorder)
                                ? theme.glowShadow(taskColor, intensity: 0.5)
                                : null,
                          ),
                          child: _isDone
                              ? Icon(Icons.check_rounded, size: 15, color: theme.card)
                              : (widget.task.color == TaskColor.red &&
                                      widget.task.scheduledDate != null &&
                                      widget.task.scheduledDate!.isAfter(DateTime.now())
                                  ? Icon(Icons.lock_rounded, size: 12, color: theme.textMuted)
                                  : null),
                        ),
                      ),
                    ),
                    if (_showXpFloat) ...[
                      ...List.generate(8, (index) {
                        final angle = index * (2 * math.pi / 8);
                        final distance = 24.0;
                        final targetX = math.cos(angle) * distance;
                        final targetY = -15.0 + math.sin(angle) * distance;
                        return Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: taskColor.withValues(alpha: 0.6 + 0.4 * (index % 2)),
                            ),
                          )
                              .animate()
                              .scale(begin: Offset.zero, end: const Offset(1.2, 1.2), duration: 250.ms)
                              .move(
                                begin: Offset.zero,
                                end: Offset(targetX, targetY),
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              )
                              .fadeOut(delay: 350.ms, duration: 200.ms),
                        );
                      }),
                      Positioned(
                        top: -10,
                        child: Text(
                          '+${XpService.xpForAction(widget.task.color)} XP',
                          style: theme.fontStyleBase(TextStyle(
                            color: theme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                        )
                            .animate()
                            .fade(duration: 200.ms)
                            .moveY(begin: 0, end: -30, duration: 800.ms, curve: Curves.easeOut)
                            .fadeOut(delay: 500.ms, duration: 300.ms),
                      ),
                    ],
                  ],
                )
              else
                const SizedBox(width: 16),
            ]),

            if (_expanded && widget.task.hasSubtasks)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: taskColor.withValues(alpha: 0.15),
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
                                ? theme.accent
                                : taskColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.text,
                              style: theme.fontStyleBase(TextStyle(
                                color: sub.isCompleted ? theme.textMuted : theme.textSecondary,
                                fontSize: 13,
                                decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                              )),
                            ),
                          ),
                          if (sub.isCompleted && sub.completedAt != null)
                            Text(
                              '${sub.completedAt!.hour.toString().padLeft(2, '0')}:${sub.completedAt!.minute.toString().padLeft(2, '0')}',
                              style: theme.fontStyleMono(TextStyle(color: theme.textMuted, fontSize: 10)),
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
    ),
    ).animate(key: ValueKey('anim_task_${widget.task.id}')).fade(duration: 200.ms).slideX(begin: 0.04, end: 0, curve: Curves.easeOut);
  }
}

class _CountdownBadge extends ConsumerWidget {
  final DateTime scheduledDate;
  const _CountdownBadge({required this.scheduledDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final today = DateTime.now();
    final diff = scheduledDate
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final label = diff == 0 ? 'Hoje!' : diff < 0 ? 'Atrasado' : '${diff}d';
    final isToday = diff == 0;
    final isOverdue = diff < 0;
    final badgeColor = theme.taskRed;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isToday || isOverdue ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(theme.borderRadius > 6 ? 6 : theme.borderRadius),
        border: Border.all(
          color: badgeColor.withValues(alpha: isToday || isOverdue ? 0.7 : 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: theme.fontStyleBase(TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: isToday || isOverdue ? FontWeight.w700 : FontWeight.normal,
        )),
      ),
    );
  }
}

class _AlarmBadge extends ConsumerWidget {
  final DateTime alarmTime;
  const _AlarmBadge({required this.alarmTime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final h = alarmTime.hour.toString().padLeft(2, '0');
    final m = alarmTime.minute.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(theme.borderRadius > 6 ? 6 : theme.borderRadius),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm_on_rounded, size: 11, color: theme.primary),
          const SizedBox(width: 4),
          Text(
            '$h:$m',
            style: theme.fontStyleMono(TextStyle(
              color: theme.primary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
          ),
        ],
      ),
    );
  }
}
