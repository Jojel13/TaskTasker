import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/task.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/routine.dart';

class TaskOccurrence {
  final DateTime date;
  final bool isCompleted;
  final DivisionType division;

  TaskOccurrence({
    required this.date,
    required this.isCompleted,
    required this.division,
  });
}

class TaskStatsData {
  final List<TaskOccurrence> occurrences;
  final int totalAppearances;
  final int totalCompleted;
  final double completionRate;
  final DateTime creationDate;
  final DateTime? lastCompletedDate;
  final int currentStreak;

  TaskStatsData({
    required this.occurrences,
    required this.totalAppearances,
    required this.totalCompleted,
    required this.completionRate,
    required this.creationDate,
    this.lastCompletedDate,
    required this.currentStreak,
  });
}

class TaskStatsScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskStatsScreen({super.key, required this.task});

  @override
  ConsumerState<TaskStatsScreen> createState() => _TaskStatsScreenState();
}

class _TaskStatsScreenState extends ConsumerState<TaskStatsScreen> {
  late Future<TaskStatsData> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<TaskStatsData> _loadStats() async {
    final isar = ref.read(isarProvider);
    final routines = await isar.routines.where().sortByDateDesc().findAll();
    final occurrencesList = <TaskOccurrence>[];

    final targetText = widget.task.text.trim().toLowerCase();

    for (final r in routines) {
      await r.days.load();
      for (final d in r.days) {
        await d.tasks.load();
        for (final t in d.tasks) {
          if (t.text.trim().toLowerCase() == targetText) {
            occurrencesList.add(TaskOccurrence(
              date: r.date,
              isCompleted: t.status == TaskStatus.completed,
              division: d.division,
            ));
            // Apenas uma ocorrência por rotina/dia para fins de streak e taxa
            break;
          }
        }
      }
    }

    final totalAppearances = occurrencesList.length;
    final totalCompleted = occurrencesList.where((o) => o.isCompleted).length;
    final completionRate = totalAppearances > 0 
        ? (totalCompleted / totalAppearances * 100) 
        : 0.0;

    final creationDate = widget.task.createdAt;
    
    DateTime? lastCompletedDate;
    for (final o in occurrencesList) {
      if (o.isCompleted) {
        lastCompletedDate = o.date;
        break;
      }
    }

    int currentStreak = 0;
    for (final o in occurrencesList) {
      if (o.isCompleted) {
        currentStreak++;
      } else {
        break;
      }
    }

    return TaskStatsData(
      occurrences: occurrencesList,
      totalAppearances: totalAppearances,
      totalCompleted: totalCompleted,
      completionRate: completionRate,
      creationDate: creationDate,
      lastCompletedDate: lastCompletedDate,
      currentStreak: currentStreak,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Estatísticas da Task',
          style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<TaskStatsData>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: theme.primary));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro ao carregar estatísticas: ${snapshot.error}',
                  style: theme.fontStyleBase(TextStyle(color: theme.taskRed)),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.totalAppearances == 0) {
              return _buildEmptyState(theme);
            }

            final data = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Task Info card
                  _buildTaskHeaderCard(theme, widget.task.text),
                  const SizedBox(height: 24),

                  // Numeric Stats Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard(
                        theme: theme,
                        title: 'Streak Atual',
                        value: '${data.currentStreak} dias',
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        theme: theme,
                        title: 'Sucesso',
                        value: '${data.completionRate.toStringAsFixed(0)}%',
                        icon: Icons.track_changes_rounded,
                        color: theme.accent,
                      ),
                      _buildStatCard(
                        theme: theme,
                        title: 'Aparições',
                        value: '${data.totalAppearances}',
                        icon: Icons.calendar_today_rounded,
                        color: theme.primary,
                      ),
                      _buildStatCard(
                        theme: theme,
                        title: 'Concluídas',
                        value: '${data.totalCompleted}',
                        icon: Icons.check_circle_outline_rounded,
                        color: theme.taskYellow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dates Card
                  _buildDatesCard(theme, data),
                  const SizedBox(height: 24),

                  // Weekly chart
                  Text(
                    'Desempenho nos Últimos 7 Dias',
                    style: theme.fontStyleBase(TextStyle(
                      color: theme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklyBarChart(theme, data.occurrences),
                  const SizedBox(height: 24),

                  // Recent History List
                  Text(
                    'Histórico Recente',
                    style: theme.fontStyleBase(TextStyle(
                      color: theme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentHistoryList(theme, data.occurrences),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskHeaderCard(AppThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.assignment_rounded, color: theme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'TAREFA',
                style: theme.fontStyleMono(TextStyle(
                  color: theme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: theme.fontStyleBase(TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required AppThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.fontStyleBase(TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                )),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            style: theme.fontStyleMono(TextStyle(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesCard(AppThemeData theme, TaskStatsData data) {
    final fmt = DateFormat('dd/MM/yyyy');
    final creationStr = fmt.format(data.creationDate);
    final lastCompletedStr = data.lastCompletedDate != null 
        ? fmt.format(data.lastCompletedDate!) 
        : 'Nunca';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Criada em:',
                style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
              ),
              Text(
                creationStr,
                style: theme.fontStyleMono(TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Última conclusão:',
                style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
              ),
              Text(
                lastCompletedStr,
                style: theme.fontStyleMono(TextStyle(
                  color: data.lastCompletedDate != null ? theme.accent : theme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(AppThemeData theme, List<TaskOccurrence> occurrences) {
    // Obter dados dos últimos 7 dias
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<DateTime> last7Days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < 7; i++) {
      final day = last7Days[i];
      // Encontrar ocorrência para este dia
      final occurrence = occurrences.firstWhere(
        (o) => o.date.year == day.year && o.date.month == day.month && o.date.day == day.day,
        orElse: () => TaskOccurrence(date: day, isCompleted: false, division: DivisionType.morning),
      );

      final appeared = occurrences.any(
        (o) => o.date.year == day.year && o.date.month == day.month && o.date.day == day.day,
      );

      final double appearedVal = appeared ? 1.0 : 0.0;
      final double completedVal = (appeared && occurrence.isCompleted) ? 1.0 : 0.0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: appearedVal,
              color: theme.primary.withValues(alpha: 0.3),
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 1.0,
                color: theme.background.withValues(alpha: 0.5),
              ),
            ),
            BarChartRodData(
              toY: completedVal,
              color: theme.accent,
              width: 10,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1.0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.surfaceVariant,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = last7Days[groupIndex];
                final dateStr = DateFormat('dd/MM').format(day);
                final statusStr = rodIndex == 0 ? 'Agendada' : 'Concluída';
                final active = rod.toY == 1.0 ? 'Sim' : 'Não';
                return BarTooltipItem(
                  '$dateStr\n$statusStr: $active',
                  theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 11)),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= 7) return const SizedBox.shrink();
                  final day = last7Days[idx];
                  final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
                  final weekdayStr = switch (day.weekday) {
                    1 => 'S',
                    2 => 'T',
                    3 => 'Q',
                    4 => 'Q',
                    5 => 'S',
                    6 => 'S',
                    _ => 'D',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      isToday ? 'Hoje' : weekdayStr,
                      style: theme.fontStyleBase(TextStyle(
                        color: isToday ? theme.accent : theme.textSecondary,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      )),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildRecentHistoryList(AppThemeData theme, List<TaskOccurrence> occurrences) {
    final recent = occurrences.take(5).toList();
    final fmt = DateFormat('dd/MM/yyyy');

    String getDivisionLabel(DivisionType type) {
      return switch (type) {
        DivisionType.morning => 'Manhã',
        DivisionType.afternoon => 'Tarde',
        DivisionType.night => 'Noite',
        DivisionType.tomorrow => 'Amanhã',
      };
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (context, index) => Divider(color: theme.border, height: 1),
        itemBuilder: (context, index) {
          final o = recent[index];
          return ListTile(
            dense: true,
            leading: Icon(
              o.isCompleted 
                  ? Icons.check_circle_rounded 
                  : Icons.radio_button_unchecked_rounded,
              color: o.isCompleted ? theme.accent : theme.textMuted,
              size: 20,
            ),
            title: Text(
              fmt.format(o.date),
              style: theme.fontStyleMono(TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
            ),
            subtitle: Text(
              'Divisão: ${getDivisionLabel(o.division)}',
              style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 11)),
            ),
            trailing: Text(
              o.isCompleted ? 'CONCLUÍDO' : 'PENDENTE',
              style: theme.fontStyleMono(TextStyle(
                color: o.isCompleted ? theme.accent : theme.taskRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              'Sem histórico disponível',
              style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta task ainda não apareceu em nenhuma rotina salva.',
              textAlign: TextAlign.center,
              style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
