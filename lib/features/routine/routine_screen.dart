import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../core/providers/core_providers.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/routine.dart';
import '../../shared/widgets/xp_bar.dart';
import 'widgets/division_section.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  final Routine routine;
  /// Se informado, a tela fará scroll até o card da task com esse ID após carregar.
  final int? scrollToTaskId;

  const RoutineScreen({super.key, required this.routine, this.scrollToTaskId});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _taskKeys = {};
  bool _hasScrolled = false; // A17: flag para scroll único

  bool get _isToday {
    final now = DateTime.now();
    return widget.routine.date.year == now.year &&
        widget.routine.date.month == now.month &&
        widget.routine.date.day == now.day;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTask(int taskId) {
    if (_hasScrolled) return; // A17: só executa uma vez
    _hasScrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _taskKeys[taskId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = ref.watch(currentThemeProvider);
    final daysAsync = ref.watch(routineDaysProvider(widget.routine.id));
    final dateStr = DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(widget.routine.date);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(children: [
          // ── AppBar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: theme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.routine.name, style: theme.fontStyleBase(AppTextStyles.titleLarge)),
                  Text(dateStr,
                      style: theme.fontStyleBase(AppTextStyles.labelSmall)
                          .copyWith(color: theme.textMuted)),
                ]),
              ),
              if (!_isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.secondary.withValues(alpha: 0.25)),
                  ),
                  child: Text('Histórico',
                      style: theme.fontStyleBase(TextStyle(
                          color: theme.secondary, fontSize: 11))),
                ),
            ]),
          ),

          // ── XP Bar ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: XpBar(),
          ),

          // ── Content ─────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: daysAsync.when(
                    loading: () => Center(
                        child: CircularProgressIndicator(color: theme.secondary)),
                    error: (e, _) => Center(
                        child: Text('Erro: $e',
                            style: theme.fontStyleBase(TextStyle(color: theme.taskRed)))),
                    data: (days) {
                      // A18: remover keys obsoletas de tasks que não existem mais
                      final currentTaskIds = days.expand((d) => d.tasks.map((t) => t.id)).toSet();
                      _taskKeys.removeWhere((id, _) => !currentTaskIds.contains(id));

                      // A17: scroll automático apenas na primeira carga
                      if (widget.scrollToTaskId != null) {
                        _scrollToTask(widget.scrollToTaskId!);
                      }
                      return ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: days.map((day) => DivisionSection(
                          routine: widget.routine,
                          day: day,
                          isToday: _isToday,
                          taskKeys: _taskKeys,
                        )).toList(),
                      );
                    },
                  ),
                ),
                
                // Efeito Glass para Histórico (rotinas antigas)
                if (!_isToday)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.02),
                                  Colors.black.withValues(alpha: 0.02),
                                  Colors.black.withValues(alpha: 0.12),
                                ],
                                stops: const [0.0, 0.35, 0.65, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
