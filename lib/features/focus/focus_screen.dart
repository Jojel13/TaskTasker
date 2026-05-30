import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/task.dart';
import '../../core/services/notification_service.dart';

class FocusScreen extends ConsumerStatefulWidget {
  final Task task;

  const FocusScreen({super.key, required this.task});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  static const List<int> _presetMinutes = [15, 25, 45, 60];
  int _selectedMinutes = 25;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _selectedMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _timer = null;
        setState(() => _isRunning = false);
        _onFocusCompleted();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _secondsRemaining = _selectedMinutes * 60;
    });
  }

  void _selectPreset(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _secondsRemaining = minutes * 60;
    });
  }

  Future<void> _onFocusCompleted() async {
    final isar = ref.read(isarProvider);
    final xpService = ref.read(xpServiceProvider);

    // 1. Incrementar focusCount
    widget.task.focusCount++;
    await isar.writeTxn(() async {
      await isar.tasks.put(widget.task);
    });

    // 2. Dar XP bonus
    await xpService.addXp(8, 'Sessão de foco concluída 🎯 (${widget.task.text})');

    // 3. Feedback e Notificação
    HapticFeedback.vibrate();
    await NotificationService.instance.showNotification(
      id: widget.task.id,
      title: '🎯 Foco Concluído!',
      body: 'Sessão de foco completada para: ${widget.task.text}. +8 XP!',
    );

    // 4. Diálogo de Conclusão de Tarefa
    if (mounted) {
      final theme = ref.read(currentThemeProvider);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.surface,
          title: Text(
            'Sessão Concluída!',
            style: theme.fontStyleBase(TextStyle(color: theme.accent, fontWeight: FontWeight.bold)),
          ),
          content: Text(
            'Você completou a sessão de foco! Deseja marcar a tarefa "${widget.task.text}" como concluída agora?',
            style: theme.fontStyleBase(TextStyle(color: theme.textPrimary)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _secondsRemaining = _selectedMinutes * 60;
                });
              },
              child: Text('Não', style: theme.fontStyleBase(TextStyle(color: theme.textMuted))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final routineService = ref.read(routineServiceProvider);
                await routineService.toggleTask(widget.task);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tarefa concluída!', style: theme.fontStyleBase(const TextStyle(color: Colors.white))),
                      backgroundColor: theme.accent,
                    ),
                  );
                  Navigator.pop(context); // Fecha a tela de foco
                }
              },
              child: Text(
                'Sim, Concluir',
                style: theme.fontStyleBase(TextStyle(color: theme.accent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final int totalSeconds = _selectedMinutes * 60;
    final double progress = totalSeconds > 0 ? _secondsRemaining / totalSeconds : 0.0;

    final minStr = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secStr = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Foco Ativo',
          style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primary, size: 20),
          onPressed: () {
            if (_isRunning) {
              _showExitConfirmation(theme);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Task Info
              _buildTaskCard(theme),
              const SizedBox(height: 32),

              // Timer Circular Progress
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: theme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                        ),
                      ),
                      // Time Text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$minStr:$secStr',
                            style: theme.fontStyleMono(TextStyle(
                              color: theme.textPrimary,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            )),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded, color: theme.accent, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Focos: ${widget.task.focusCount}',
                                style: theme.fontStyleBase(TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Preset Selection Chips
              if (!_isRunning) ...[
                Center(
                  child: Wrap(
                    spacing: 12,
                    children: _presetMinutes.map((minutes) {
                      final isSelected = _selectedMinutes == minutes;
                      return ChoiceChip(
                        label: Text(
                          '$minutes min',
                          style: theme.fontStyleBase(TextStyle(
                            color: isSelected ? Colors.white : theme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          )),
                        ),
                        selected: isSelected,
                        selectedColor: theme.primary,
                        backgroundColor: theme.surface,
                        side: BorderSide(color: isSelected ? theme.primary : theme.border),
                        onSelected: (_) => _selectPreset(minutes),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Suggestion Tip Box
              _buildDndTip(theme),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRunning) ...[
                    // Pause Button
                    _buildActionButton(
                      theme: theme,
                      label: 'Pausar',
                      icon: Icons.pause_rounded,
                      color: theme.primary,
                      onTap: _pauseTimer,
                    ),
                    const SizedBox(width: 16),
                    // Reset Button
                    _buildActionButton(
                      theme: theme,
                      label: 'Resetar',
                      icon: Icons.replay_rounded,
                      color: theme.textMuted,
                      onTap: _resetTimer,
                    ),
                  ] else ...[
                    // Start Button
                    _buildActionButton(
                      theme: theme,
                      label: 'Iniciar',
                      icon: Icons.play_arrow_rounded,
                      color: theme.accent,
                      onTap: _startTimer,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.center_focus_strong_rounded, color: theme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'FOCO DA SESSÃO',
                style: theme.fontStyleMono(TextStyle(
                  color: theme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.text,
            style: theme.fontStyleBase(TextStyle(
              color: theme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDndTip(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Text('🐸', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Silencie notificações externas para se concentrar no que importa.',
              style: theme.fontStyleBase(TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                height: 1.3,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required AppThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: theme.fontStyleBase(const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        )),
      ),
    );
  }

  void _showExitConfirmation(AppThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text(
          'Abandonar Sessão?',
          style: theme.fontStyleBase(TextStyle(color: theme.taskRed, fontWeight: FontWeight.bold)),
        ),
        content: Text(
          'Se você sair agora, o progresso da sessão atual será perdido.',
          style: theme.fontStyleBase(TextStyle(color: theme.textPrimary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Continuar Foco', style: theme.fontStyleBase(TextStyle(color: theme.textSecondary))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Exit FocusScreen
            },
            child: Text('Sair', style: theme.fontStyleBase(TextStyle(color: theme.taskRed, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}
