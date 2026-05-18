import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/enums.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/routine_card.dart';
import '../routine/routine_screen.dart';
import 'settings_screen.dart';
import '../dashboard/xp_dashboard_screen.dart';
import '../analytics/analytics_screen.dart';
import '../../shared/widgets/xp_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(allRoutinesProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return SafeArea(
      child: Column(children: [
        // ── Header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
          child: Row(children: [
            // Título
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'TASKTASKER',
                  style: AppTextStyles.monoSmall.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 2.5,
                  ),
                ),
                Text(
                  profile?.routineName ?? 'Minha Rotina',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ]),
            ),

            // Streak badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant, // Cor sólida Peak
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent, // Borda brilhante
                  width: 1.0,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '${profile?.streakDays ?? 0}',
                  style: AppTextStyles.monoSmall.copyWith(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 4),

            // XP Dashboard
            _HeaderIconButton(
              icon: Icons.star_rounded,
              color: AppColors.accent,
              tooltip: 'XP',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const XpDashboardScreen()),
              ),
            ),

            // Análise
            _HeaderIconButton(
              icon: Icons.bar_chart_rounded,
              color: AppColors.secondary,
              tooltip: 'Análise',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              ),

            ),

            // Settings
            _HeaderIconButton(
              icon: Icons.settings_outlined,
              color: AppColors.textSecondary,
              tooltip: 'Configurações',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ]),
        ),

        // ── XP Bar ──────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: XpBar(),
        ),

        // ── Lista de rotinas ─────────────────────────────────────
        Expanded(
          child: routinesAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
                child: Text('Erro: $e',
                    style: const TextStyle(color: AppColors.taskRed))),
            data: (routines) {
              if (routines.isEmpty) return const _EmptyState();
              
              final idx = routines.indexWhere((r) => _isToday(r));
              final todayRoutine = idx != -1 ? routines[idx] : null;

              return Column(
                children: [
                  if (todayRoutine != null)
                    _TodayProgressBanner(routine: todayRoutine),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 120),
                      itemCount: routines.length,
                      itemBuilder: (context, i) {
                        return _RoutineCardLoader(
                          routine: routines[i],
                          isToday: i == idx,
                          onTap: () => _openRoutine(context, ref, routines[i]),
                          onDelete: () => _deleteRoutine(ref, routines[i]),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  bool _isToday(Routine r) {
    final now = DateTime.now();
    return r.date.year == now.year &&
        r.date.month == now.month &&
        r.date.day == now.day;
  }

  void _openRoutine(BuildContext context, WidgetRef ref, Routine routine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoutineScreen(routine: routine)),
    );
  }

  Future<void> _deleteRoutine(WidgetRef ref, Routine routine) async {
    await ref.read(routineServiceProvider).deleteRoutine(routine.id);
  }
}

// ── Botão de ícone do header ─────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          splashColor: color.withValues(alpha: 0.2),
          highlightColor: color.withValues(alpha: 0.1),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Carrega os days de cada rotina para o card ───────────────────────────────
class _RoutineCardLoader extends ConsumerWidget {
  final Routine routine;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RoutineCardLoader({
    required this.routine,
    required this.isToday,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(routineDaysProvider(routine.id));
    return daysAsync.when(
      loading: () => const SizedBox(
          height: 80,
          child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))),
      error: (_, _) => const SizedBox.shrink(),
      data: (days) => RoutineCard(
        routine: routine,
        days: days,
        isToday: isToday,
        onTap: onTap,
        onDelete: onDelete,
      ),
    );
  }
}

// ── Estado vazio ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.08),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 36),
        ),
        const SizedBox(height: 20),
        const Text(
          'Nenhuma rotina ainda',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Toque em + para começar',
          style: AppTextStyles.monoSmall.copyWith(
            color: AppColors.primaryDim,
            fontSize: 11,
          ),
        ),
      ]),
    );
  }
}

// ── Banner de Progresso para a rotina de hoje ────────────────────────────
class _TodayProgressBanner extends ConsumerWidget {
  final Routine routine;
  const _TodayProgressBanner({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(routineDaysProvider(routine.id));
    
    return daysAsync.when(
      data: (days) {
         final tasks = days.where((d) => d.division != DivisionType.tomorrow).expand((d) => d.tasks).toList();
         final total = tasks.length;
         if (total == 0) return const SizedBox.shrink();
         
         final done = tasks.where((t) => t.status == TaskStatus.completed).length;
         final percent = (done / total * 100).toInt();
         final left = total - done;

         final isPerfect = left == 0;

         return Container(
           margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
           decoration: BoxDecoration(
             color: AppColors.surfaceVariant, // Cor sólida Peak
             borderRadius: BorderRadius.circular(12),
             border: Border.all(
               color: isPerfect ? AppColors.accent : AppColors.primary,
               width: 1.5,
             ),
             boxShadow: isPerfect ? AppColors.glowShadow(AppColors.accent, intensity: 0.3) : null,
           ),
           child: Row(
             children: [
               Icon(
                 isPerfect ? Icons.star_rounded : Icons.track_changes_rounded,
                 color: isPerfect ? AppColors.taskYellow : AppColors.primary,
                 size: isPerfect ? 24 : 20,
               )
                   .animate(target: isPerfect ? 1 : 0)
                   .scaleXY(end: 1.2, duration: 600.ms, curve: Curves.easeOutBack)
                   .shimmer(delay: 1000.ms, duration: 1500.ms),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   isPerfect ? '100% CONCLUÍDO! OTIMIZAÇÃO MÁXIMA!' : '$left tasks restantes hoje',
                   style: TextStyle(
                     color: isPerfect ? AppColors.accent : AppColors.textPrimary, 
                     fontWeight: FontWeight.bold, 
                     fontSize: isPerfect ? 14 : 13,
                     letterSpacing: isPerfect ? 0.5 : 0,
                   ),
                 )
                     .animate(target: isPerfect ? 1 : 0)
                     .fade(duration: 400.ms),
               ),
               if (!isPerfect)
                 Text(
                   '$percent%',
                   style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                 ),
             ],
           ),
         ).animate(target: isPerfect ? 1 : 0).shimmer(duration: 2000.ms, color: AppColors.accent.withValues(alpha: 0.2));
      },
      loading: () => const SizedBox.shrink(),
      error: (e, stack) => const SizedBox.shrink(),
    );
  }
}
