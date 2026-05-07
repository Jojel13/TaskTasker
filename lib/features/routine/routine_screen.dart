import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/routine.dart';
import '../../shared/widgets/xp_bar.dart';
import 'widgets/division_section.dart';

class RoutineScreen extends ConsumerWidget {
  final Routine routine;
  const RoutineScreen({super.key, required this.routine});

  bool get _isToday {
    final now = DateTime.now();
    return routine.date.year == now.year &&
        routine.date.month == now.month &&
        routine.date.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(routineDaysProvider(routine.id));
    final dateStr = DateFormat('EEEE, dd \'de\' MMMM', 'pt_BR').format(routine.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── AppBar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(routine.name, style: AppTextStyles.titleLarge),
                  Text(dateStr,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primaryDim)),
                ]),
              ),
              if (!_isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.secondary.withOpacity(0.3)),
                  ),
                  child: const Text('Histórico',
                      style: TextStyle(
                          color: AppColors.secondary, fontSize: 11)),
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
            child: daysAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                  child: Text('Erro: $e',
                      style: const TextStyle(color: AppColors.taskRed))),
              data: (days) => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: days
                    .map((day) => DivisionSection(routine: routine, day: day))
                    .toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
