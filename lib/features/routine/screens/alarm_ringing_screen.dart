import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/theme_config.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/alarm_service.dart';
import '../../../shared/models/task.dart';
import '../../../shared/models/enums.dart';

/// Tela de Alarme Despertador em Tela Cheia (Peak UX / Full Screen Alarm)
class AlarmRingingScreen extends ConsumerStatefulWidget {
  final Task task;

  const AlarmRingingScreen({super.key, required this.task});

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen> with SingleTickerProviderStateMixin {
  late Timer _clockTimer;
  late Timer _vibrationTimer;
  late AnimationController _pulseController;
  DateTime _currentTime = DateTime.now();
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    // Manter tela acesa durante o alarme
    WakelockPlus.enable();
    // Tela cheia imersiva (esconde barras do sistema)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    // Padrão contínuo de vibração de despertar
    _triggerVibration();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      _triggerVibration();
    });
  }

  void _triggerVibration() {
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _vibrationTimer.cancel();
    _pulseController.dispose();
    // Liberar wake lock e restaurar UI normal
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Future<void> _completeTask(AppThemeData theme) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    await AlarmService.cancelAlarm(widget.task.id);
    final isar = ref.read(isarProvider);
    final freshTask = await isar.tasks.get(widget.task.id) ?? widget.task;
    if (freshTask.status != TaskStatus.completed) {
      await ref.read(routineServiceProvider).toggleTask(freshTask);
      ref.invalidate(todayRoutineProvider);
      ref.invalidate(routineDaysProvider);
      ref.invalidate(radarProvider);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _snoozeAlarm(AppThemeData theme) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    await AlarmService.cancelAlarm(widget.task.id);
    
    final profile = ref.read(userProfileProvider).value;
    final soundEnabled = profile?.alarmSoundEnabled ?? true;
    await AlarmService.scheduleSnooze(widget.task, 5, soundEnabled: soundEnabled);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Soneca ativada para as ${DateFormat('HH:mm').format(snoozeTime)}',
            style: theme.fontStyleBase(const TextStyle(color: Colors.white)),
          ),
          backgroundColor: theme.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _dismissAlarm() async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    await AlarmService.cancelAlarm(widget.task.id);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final timeStr = DateFormat('HH:mm').format(_currentTime);
    final secondsStr = DateFormat('ss').format(_currentTime);
    final dateStr = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(_currentTime);

    final Color accentColor = switch (widget.task.color) {
      TaskColor.red      => theme.taskRed,
      TaskColor.yellow   => theme.taskYellow,
      TaskColor.blue     => theme.taskBlue,
      TaskColor.standard => theme.primary,
    };

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.background,
        body: SafeArea(
        child: Stack(
          children: [
            // Efeito de pulso de fundo
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.3 + (_pulseController.value * 0.25),
                        colors: [
                          accentColor.withValues(alpha: 0.28 + (_pulseController.value * 0.12)),
                          theme.background,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Data de Hoje
                  Text(
                    dateStr.toUpperCase(),
                    style: theme.fontStyleMono(AppTextStyles.labelSmall).copyWith(
                      color: theme.textSecondary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Relógio Digital Gigante
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        timeStr,
                        style: theme.fontStyleMono(const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        )).copyWith(color: theme.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        secondsStr,
                        style: theme.fontStyleMono(TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        )),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Ícone de Despertador Animado
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.surface,
                          border: Border.all(color: accentColor, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.4 + (_pulseController.value * 0.35)),
                              blurRadius: 30 + (_pulseController.value * 20),
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.alarm_rounded,
                          size: 56,
                          color: accentColor,
                        ),
                      );
                    },
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .shake(hz: 3, curve: Curves.easeInOut),

                  const SizedBox(height: 32),

                  // Badge de Urgência
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '⏰ ALARME EM DISPARO',
                      style: theme.fontStyleMono(TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      )),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Texto da Tarefa
                  Text(
                    widget.task.text,
                    textAlign: TextAlign.center,
                    style: theme.fontStyleBase(const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    )).copyWith(color: theme.textPrimary),
                  ),

                  const Spacer(),

                  // ─── Botões de Ação ──────────────────────────────────────────
                  // 1. Concluir Tarefa (+XP)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _completeTask(theme),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Concluir Tarefa (+XP)',
                            style: theme.fontStyleBase(const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Soneca (5 min) e Desligar
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => _snoozeAlarm(theme),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.secondary,
                              side: BorderSide(color: theme.secondary.withValues(alpha: 0.6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.snooze_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Soneca 5m',
                                  style: theme.fontStyleBase(const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  )),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: TextButton(
                            onPressed: _dismissAlarm,
                            style: TextButton.styleFrom(
                              foregroundColor: theme.textSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.close_rounded, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Desligar',
                                  style: theme.fontStyleBase(const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  )),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
