import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_config.dart';
import '../../../shared/models/task.dart';

class AlarmSheet extends ConsumerStatefulWidget {
  final Task task;

  const AlarmSheet({super.key, required this.task});

  /// Abre o bottom sheet de alarme.
  static Future<void> show(BuildContext context, Task task) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AlarmSheet(task: task),
      ),
    );
  }

  @override
  ConsumerState<AlarmSheet> createState() => _AlarmSheetState();
}

class _AlarmSheetState extends ConsumerState<AlarmSheet> {
  late TimeOfDay _selectedTime;
  late bool _repeat;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.task.alarmTime != null) {
      final t = widget.task.alarmTime!;
      _selectedTime = TimeOfDay(hour: t.hour, minute: t.minute);
    } else {
      final now = DateTime.now();
      final nextMin = now.minute < 30 ? 30 : 0;
      final nextHour = now.minute < 30 ? now.hour : (now.hour + 1) % 24;
      _selectedTime = TimeOfDay(hour: nextHour, minute: nextMin);
    }
    _repeat = widget.task.alarmRepeat;
  }

  Future<void> _pickTime(AppThemeData theme) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: theme.primary,
            onPrimary: theme.background,
            surface: theme.surface,
            onSurface: theme.textPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: theme.surface,
            hourMinuteColor: theme.surfaceVariant,
            hourMinuteTextColor: theme.textPrimary,
            dialBackgroundColor: theme.surfaceVariant,
            dialHandColor: theme.primary,
            dialTextColor: theme.textPrimary,
            entryModeIconColor: theme.textSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveAlarm(AppThemeData theme) async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final now = DateTime.now();
      var alarmDateTime = DateTime(
        now.year, now.month, now.day,
        _selectedTime.hour, _selectedTime.minute,
      );
      if (alarmDateTime.isBefore(now)) {
        alarmDateTime = alarmDateTime.add(const Duration(days: 1));
      }

      await ref.read(routineServiceProvider).setAlarm(
        widget.task,
        alarmDateTime,
        repeat: _repeat,
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(Icons.alarm_on_rounded, color: theme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Alarme definido para ${_selectedTime.format(context)}',
                style: theme.fontStyleBase(TextStyle(color: theme.textPrimary)),
              ),
            ]),
            backgroundColor: theme.surface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearAlarm() async {
    HapticFeedback.selectionClick();
    await ref.read(routineServiceProvider).clearAlarm(widget.task);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final hasAlarm = widget.task.hasAlarm;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(theme.borderRadius > 24 ? 24 : theme.borderRadius)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.alarm_add_rounded, color: theme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurar Alarme',
                      style: theme.fontStyleBase(const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      )).copyWith(color: theme.textPrimary)
                    ),
                    Text(
                      widget.task.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.fontStyleBase(const TextStyle(fontSize: 12)).copyWith(color: theme.textSecondary),
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
                  child: Icon(Icons.close_rounded,
                      size: 18, color: theme.textMuted),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Seletor de horário (tap para abrir TimePicker)
          GestureDetector(
            onTap: () => _pickTime(theme),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(theme.borderRadius > 16 ? 16 : theme.borderRadius),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_rounded,
                      color: theme.primary, size: 28),
                  const SizedBox(width: 16),
                  Text(
                    _selectedTime.format(context),
                    style: theme.fontStyleMono(const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                    )).copyWith(color: theme.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.edit_rounded,
                          color: theme.textMuted, size: 14),
                      const SizedBox(height: 4),
                      Text(
                        'Toque\npara editar',
                        style: theme.fontStyleBase(TextStyle(
                          color: theme.textMuted,
                          fontSize: 9,
                          height: 1.3,
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Toggle "Repetir 3x a cada 5 min"
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _repeat = !_repeat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _repeat
                    ? theme.secondary.withValues(alpha: 0.08)
                    : theme.surfaceVariant,
                borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius),
                border: Border.all(
                  color: _repeat
                      ? theme.secondary.withValues(alpha: 0.35)
                      : theme.border,
                  width: _repeat ? 1 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    color: _repeat ? theme.secondary : theme.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Repetir 3x a cada 5 minutos',
                          style: theme.fontStyleBase(TextStyle(
                            fontSize: 14,
                            fontWeight: _repeat
                                ? FontWeight.w600
                                : FontWeight.normal,
                          )).copyWith(
                            color: _repeat
                                ? theme.textPrimary
                                : theme.textSecondary,
                          ),
                        ),
                        if (_repeat)
                          Text(
                            'Alarme dispara às ${_selectedTime.format(context)}, +5min e +10min',
                            style: theme.fontStyleBase(TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                            )),
                          ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _repeat
                          ? theme.secondary
                          : theme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _repeat
                              ? theme.secondary
                              : theme.border),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: _repeat
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botões de ação
          Row(children: [
            if (hasAlarm) ...[
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.taskRed,
                    side: BorderSide(
                        color: theme.taskRed.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius)),
                  ),
                  icon: const Icon(Icons.alarm_off_rounded, size: 18),
                  label: Text('Remover', style: theme.fontStyleBase(const TextStyle(fontWeight: FontWeight.bold))),
                  onPressed: _saving ? null : _clearAlarm,
                ),
              ),
              const SizedBox(width: 12),
            ],

            Expanded(
              flex: hasAlarm ? 2 : 1,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                icon: _saving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: theme.background, strokeWidth: 2),
                      )
                    : const Icon(Icons.alarm_on_rounded, size: 18),
                label: Text(
                  hasAlarm ? 'Atualizar Alarme' : 'Ativar Alarme',
                  style: theme.fontStyleBase(const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                onPressed: _saving ? null : () => _saveAlarm(theme),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
