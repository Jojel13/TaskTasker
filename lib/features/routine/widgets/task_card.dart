import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';
import '../../../core/services/image_service.dart';
import 'task_settings_sheet.dart';
import '../task_tree_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onColorCycle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onColorCycle,
    required this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _expanded = false;

  Color get _taskColor => switch (widget.task.color) {
    TaskColor.standard => AppColors.taskStandard,
    TaskColor.blue     => AppColors.taskBlue,
    TaskColor.yellow   => AppColors.taskYellow,
    TaskColor.red      => AppColors.taskRed,
  };

  bool get _isDone => widget.task.status == TaskStatus.completed;
  bool get _isLocked => widget.task.color == TaskColor.red &&
      widget.task.scheduledDate != null &&
      widget.task.scheduledDate!.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final bool hasImage = widget.task.imageFileName != null;
    
    return Slidable(
      key: ValueKey(widget.task.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.8, // More space for more actions
        children: [
          SlidableAction(
            onPressed: (_) async {
              // Copiar texto
              await Clipboard.setData(ClipboardData(text: widget.task.text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texto copiado!', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.primary),
                );
              }
            },
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            icon: Icons.copy_rounded,
          ),
          SlidableAction(
            onPressed: (_) async {
              // Câmera
              final fileName = await ImageService.pickAndSaveImage(widget.task.id.toString(), fromCamera: true);
              if (fileName != null && context.mounted) {
                // To keep it simple, we don't have direct access to RoutineService here to update the task
                // We'll rely on the provider invalidation handled outside, or we should pass an onImageUpdate callback
                // Let's assume onToggle or another callback will trigger a refresh.
              }
            },
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.taskBlue,
            icon: Icons.camera_alt_rounded,
          ),
          SlidableAction(
            onPressed: (_) {
              // Task Tree
              Navigator.push(context, MaterialPageRoute(builder: (_) => TaskTreeScreen(task: widget.task)));
            },
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.taskYellow,
            icon: Icons.account_tree_rounded,
          ),
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: AppColors.taskRed.withOpacity(0.15),
            foregroundColor: AppColors.taskRed,
            icon: Icons.delete_outline_rounded,
            label: 'Apagar',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDone
                ? AppColors.border
                : _taskColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Row(children: [
          // ── Color dot (tappable) ────────────────────────
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLocked ? null : widget.onColorCycle,
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

          // ── Task text & Indicators ──────────────────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.task.hasSubtasks ? () => setState(() => _expanded = !_expanded) : null,
              onDoubleTap: hasImage ? () async {
                 // Double tap to view image
                 final file = await ImageService.getImageFile(widget.task.imageFileName!);
                 if (file != null && context.mounted) {
                    showDialog(
                      context: context,
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
              onLongPress: (widget.task.color == TaskColor.red || widget.task.color == TaskColor.blue) 
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
              
              // ── Indicators (Image / Subtasks) ───────────────
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

          // ── Settings Icon for Red/Blue tasks ────────────
          if (widget.task.color == TaskColor.red || widget.task.color == TaskColor.blue)
            GestureDetector(
              onTap: () => TaskSettingsSheet.show(context, widget.task),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.settings_outlined, size: 16, color: AppColors.textMuted),
              ),
            ),

          // ── Countdown badge (red task) ──────────────────
          if (widget.task.color == TaskColor.red && widget.task.scheduledDate != null)
            _CountdownBadge(scheduledDate: widget.task.scheduledDate!),

          // ── Checkbox ────────────────────────────────────
          GestureDetector(
            onTap: _isLocked ? null : widget.onToggle,
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
                  color: _isDone ? _taskColor.withOpacity(0.2) : Colors.transparent,
                  border: Border.all(
                    color: _isLocked ? AppColors.textMuted : _taskColor,
                    width: 1.5,
                  ),
                  boxShadow: _isDone
                      ? AppColors.glowShadow(_taskColor, intensity: 0.5)
                      : null,
                ),
                child: _isDone
                    ? Icon(Icons.check, size: 14, color: _taskColor)
                    : null,
              ),
            ),
          ),
        ]),
        
        // ── Subtasks Expandables ────────────────────────
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
                      sub.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 16,
                      color: sub.isCompleted ? AppColors.textMuted : _taskColor.withOpacity(0.8),
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
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
      ),
    ).animate().fade(duration: 250.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
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
    final label = diff == 0 ? 'Hoje!' : '${diff}d';
    final isToday = diff == 0;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.taskRed.withOpacity(isToday ? 0.25 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppColors.taskRed.withOpacity(isToday ? 0.8 : 0.4),
            width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              color: AppColors.taskRed,
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.normal)),
    );
  }
}
