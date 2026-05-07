import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/routine.dart';
import 'widgets/routine_card.dart';
import '../routine/routine_screen.dart';
import 'settings_screen.dart';
import '../../shared/widgets/xp_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(allRoutinesProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return SafeArea(
        child: Column(children: [
          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TASKTASKER',
                      style: AppTextStyles.monoSmall
                          .copyWith(color: AppColors.primaryDim)),
                  Text(profile?.routineName ?? 'Minha Rotina',
                      style: AppTextStyles.displayMedium),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('${profile?.streakDays ?? 0}d',
                      style: AppTextStyles.monoSmall),
                ]),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ]),
          ),
          
          // ── XP Bar ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: XpBar(),
          ),

          // ── Lista de rotinas ────────────────────────────────
          Expanded(
            child: routinesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                  child: Text('Erro: $e',
                      style: const TextStyle(color: AppColors.taskRed))),
              data: (routines) {
                if (routines.isEmpty) {
                  return _EmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: routines.length,
                  itemBuilder: (context, i) {
                    return _RoutineCardLoader(
                      routine: routines[i],
                      isToday: _isToday(routines[i]),
                      onTap: () => _openRoutine(context, ref, routines[i]),
                      onDelete: () => _deleteRoutine(ref, routines[i]),
                    );
                  },
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

// ── Carrega os days de cada rotina para o card ────────────────────────────────
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
      loading: () => const SizedBox(height: 80,
          child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
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

// ── Estado vazio ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('⚡', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        const Text('Nenhuma rotina ainda',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Toque em + para começar',
            style: AppTextStyles.monoSmall.copyWith(color: AppColors.primaryDim)),
      ]),
    );
  }
}
