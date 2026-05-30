import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/routine.dart';
import '../../shared/models/xp_event.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/user_profile.dart';

class WeeklySummaryData {
  final DateTime startDate;
  final DateTime endDate;
  final int totalTasks;
  final int completedTasks;
  final double successRate;
  final int xpEarned;
  final int currentStreak;
  final Map<DateTime, int> tasksPerDay;
  final Map<DateTime, int> completedPerDay;
  final DivisionType bestDivision;
  final String mostCompletedTask;
  final double successRateDifference;
  final String mascotMessage;

  WeeklySummaryData({
    required this.startDate,
    required this.endDate,
    required this.totalTasks,
    required this.completedTasks,
    required this.successRate,
    required this.xpEarned,
    required this.currentStreak,
    required this.tasksPerDay,
    required this.completedPerDay,
    required this.bestDivision,
    required this.mostCompletedTask,
    required this.successRateDifference,
    required this.mascotMessage,
  });
}

class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  ConsumerState<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  bool _showPreviousWeek = false;
  late Future<WeeklySummaryData> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final now = DateTime.now();
    final targetDate = _showPreviousWeek ? now.subtract(const Duration(days: 7)) : now;
    _summaryFuture = _loadWeeklyData(targetDate);
  }

  DateTime getMonday(DateTime date) {
    final offset = date.weekday - 1;
    final monday = DateTime(date.year, date.month, date.day).subtract(Duration(days: offset));
    return monday;
  }

  Future<WeeklySummaryData> _loadWeeklyData(DateTime targetDate) async {
    final isar = ref.read(isarProvider);
    final monday = getMonday(targetDate);
    final sunday = monday.add(const Duration(days: 6));

    final startDate = DateTime(monday.year, monday.month, monday.day);
    final endDate = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

    final routines = await isar.routines
        .filter()
        .dateBetween(startDate, endDate)
        .findAll();

    int totalTasks = 0;
    int completedTasks = 0;

    final Map<DateTime, int> tasksPerDay = {};
    final Map<DateTime, int> completedPerDay = {};

    final Map<DivisionType, int> divisionTotal = {};
    final Map<DivisionType, int> divisionCompleted = {};

    final Map<String, int> completedTaskCounts = {};

    for (int i = 0; i < 7; i++) {
      final d = startDate.add(Duration(days: i));
      tasksPerDay[d] = 0;
      completedPerDay[d] = 0;
    }

    for (final r in routines) {
      final rDate = DateTime(r.date.year, r.date.month, r.date.day);
      await r.days.load();
      for (final day in r.days) {
        await day.tasks.load();
        for (final t in day.tasks) {
          totalTasks++;
          tasksPerDay[rDate] = (tasksPerDay[rDate] ?? 0) + 1;
          divisionTotal[day.division] = (divisionTotal[day.division] ?? 0) + 1;

          if (t.status == TaskStatus.completed) {
            completedTasks++;
            completedPerDay[rDate] = (completedPerDay[rDate] ?? 0) + 1;
            divisionCompleted[day.division] = (divisionCompleted[day.division] ?? 0) + 1;

            final text = t.text.trim();
            completedTaskCounts[text] = (completedTaskCounts[text] ?? 0) + 1;
          }
        }
      }
    }

    final successRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

    DivisionType bestDivision = DivisionType.morning;
    double bestRate = -1.0;
    for (final div in DivisionType.values) {
      final tot = divisionTotal[div] ?? 0;
      final comp = divisionCompleted[div] ?? 0;
      if (tot > 0) {
        final rate = comp / tot;
        if (rate > bestRate) {
          bestRate = rate;
          bestDivision = div;
        }
      }
    }

    String mostCompletedTask = 'Nenhuma';
    int maxCompleted = 0;
    for (final entry in completedTaskCounts.entries) {
      if (entry.value > maxCompleted) {
        maxCompleted = entry.value;
        mostCompletedTask = entry.key;
      }
    }

    final xpEvents = await isar.xPEvents
        .filter()
        .earnedAtBetween(startDate, endDate)
        .findAll();
    final xpEarned = xpEvents.fold(0, (sum, e) => sum + e.amount);

    final profile = await isar.userProfiles.get(1);
    final currentStreak = profile?.streakDays ?? 0;

    final prevMonday = startDate.subtract(const Duration(days: 7));
    final prevSunday = prevMonday.add(const Duration(days: 6));
    final prevStartDate = DateTime(prevMonday.year, prevMonday.month, prevMonday.day);
    final prevEndDate = DateTime(prevSunday.year, prevSunday.month, prevSunday.day, 23, 59, 59);

    final prevRoutines = await isar.routines
        .filter()
        .dateBetween(prevStartDate, prevEndDate)
        .findAll();

    int prevTotalTasks = 0;
    int prevCompletedTasks = 0;
    for (final r in prevRoutines) {
      await r.days.load();
      for (final day in r.days) {
        await day.tasks.load();
        for (final t in day.tasks) {
          prevTotalTasks++;
          if (t.status == TaskStatus.completed) {
            prevCompletedTasks++;
          }
        }
      }
    }
    final prevSuccessRate = prevTotalTasks > 0 ? (prevCompletedTasks / prevTotalTasks * 100) : 0.0;
    final successRateDifference = successRate - prevSuccessRate;

    String mascotMessage;
    if (totalTasks == 0) {
      mascotMessage = "Nenhuma tarefa registrada nesta semana. Vamos começar adicionando algumas tarefas na sua rotina? 🐸🌱";
    } else if (successRate >= 80) {
      mascotMessage = "Incrível! Você dominou a semana como um verdadeiro mestre! Continue assim! 🐸✨";
    } else if (successRate >= 50) {
      mascotMessage = "Bom trabalho! Você está progredindo muito bem. Vamos tentar bater 80% na próxima semana? 🐸💪";
    } else if (successRate > 0) {
      mascotMessage = "Toda pequena vitória conta. Não desanime, cada dia é uma nova oportunidade de foco! 🐸🌱";
    } else {
      mascotMessage = "Uma semana de descanso. Que tal começar a próxima semana definindo pequenas tarefas fáceis? 🐸💤";
    }

    return WeeklySummaryData(
      startDate: startDate,
      endDate: endDate,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      successRate: successRate,
      xpEarned: xpEarned,
      currentStreak: currentStreak,
      tasksPerDay: tasksPerDay,
      completedPerDay: completedPerDay,
      bestDivision: bestDivision,
      mostCompletedTask: mostCompletedTask,
      successRateDifference: successRateDifference,
      mascotMessage: mascotMessage,
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
          'Resumo Semanal',
          style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Week Selector Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_showPreviousWeek) {
                            setState(() {
                              _showPreviousWeek = false;
                              _loadData();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_showPreviousWeek ? theme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Esta Semana',
                            style: theme.fontStyleBase(TextStyle(
                              color: !_showPreviousWeek ? Colors.white : theme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            )),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!_showPreviousWeek) {
                            setState(() {
                              _showPreviousWeek = true;
                              _loadData();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showPreviousWeek ? theme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Semana Passada',
                            style: theme.fontStyleBase(TextStyle(
                              color: _showPreviousWeek ? Colors.white : theme.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: FutureBuilder<WeeklySummaryData>(
                future: _summaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: theme.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Erro ao carregar dados: ${snapshot.error}',
                          style: theme.fontStyleBase(TextStyle(color: theme.taskRed)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(child: Text('Nenhum dado encontrado.', style: theme.fontStyleBase(TextStyle(color: theme.textSecondary))));
                  }

                  final data = snapshot.data!;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Week Date Banner
                        _buildDateHeader(theme, data),
                        const SizedBox(height: 20),

                        // Mascot Message Ballon
                        _buildMascotBalloon(theme, data.mascotMessage),
                        const SizedBox(height: 24),

                        // Metrics Cards Row/Grid
                        _buildMetricsGrid(theme, data),
                        const SizedBox(height: 24),

                        // Success Rate Trend Comparison
                        _buildTrendComparisonCard(theme, data),
                        const SizedBox(height: 24),

                        // Weekly fl_chart
                        Text(
                          'Progresso Diário',
                          style: theme.fontStyleBase(TextStyle(
                            color: theme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                        ),
                        const SizedBox(height: 12),
                        _buildDailyChart(theme, data),
                        const SizedBox(height: 24),

                        // Extra insights (Best Division & Most Completed Task)
                        _buildInsightsCard(theme, data),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(AppThemeData theme, WeeklySummaryData data) {
    final startStr = DateFormat('dd/MM').format(data.startDate);
    final endStr = DateFormat('dd/MM').format(data.endDate);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Período da Semana',
            style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
          ),
          Text(
            '$startStr a $endStr',
            style: theme.fontStyleMono(TextStyle(color: theme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotBalloon(AppThemeData theme, String message) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Sapo Mascot Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🐸', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: theme.fontStyleBase(TextStyle(
                color: theme.textPrimary,
                fontSize: 13,
                height: 1.4,
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(AppThemeData theme, WeeklySummaryData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMetricCard(
          theme: theme,
          title: 'Taxa de Sucesso',
          value: '${data.successRate.toStringAsFixed(0)}%',
          icon: Icons.emoji_events_rounded,
          color: theme.primary,
        ),
        _buildMetricCard(
          theme: theme,
          title: 'XP Ganho',
          value: '+${data.xpEarned} XP',
          icon: Icons.star_rounded,
          color: theme.accent,
        ),
        _buildMetricCard(
          theme: theme,
          title: 'Streak Atual',
          value: '${data.currentStreak} dias',
          icon: Icons.local_fire_department_rounded,
          color: Colors.orange,
        ),
        _buildMetricCard(
          theme: theme,
          title: 'Total Concluído',
          value: '${data.completedTasks}/${data.totalTasks}',
          icon: Icons.task_alt_rounded,
          color: theme.taskYellow,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendComparisonCard(AppThemeData theme, WeeklySummaryData data) {
    final diff = data.successRateDifference;
    final isBetter = diff >= 0;
    final absDiff = diff.abs().toStringAsFixed(0);
    final trendColor = isBetter ? theme.accent : theme.taskRed;
    final trendIcon = isBetter ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparação Semanal',
                  style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 11)),
                ),
                const SizedBox(height: 4),
                Text(
                  isBetter 
                      ? 'Desempenho subiu em $absDiff%!' 
                      : 'Desempenho caiu em $absDiff% em relação à anterior.',
                  style: theme.fontStyleBase(TextStyle(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart(AppThemeData theme, WeeklySummaryData data) {
    // Obter dados ordenados por dia da semana
    final List<DateTime> sortedDays = data.tasksPerDay.keys.toList()..sort();
    final List<BarChartGroupData> barGroups = [];

    int maxCount = 1;
    for (int i = 0; i < sortedDays.length; i++) {
      final day = sortedDays[i];
      final total = data.tasksPerDay[day] ?? 0;
      final completed = data.completedPerDay[day] ?? 0;

      if (total > maxCount) maxCount = total;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total.toDouble(),
              color: theme.primary.withValues(alpha: 0.3),
              width: 12,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxCount.toDouble(),
                color: theme.background.withValues(alpha: 0.5),
              ),
            ),
            BarChartRodData(
              toY: completed.toDouble(),
              color: theme.accent,
              width: 12,
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
          maxY: maxCount.toDouble(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.surfaceVariant,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = sortedDays[groupIndex];
                final dateStr = DateFormat('dd/MM').format(day);
                final label = rodIndex == 0 ? 'Total' : 'Concluídas';
                return BarTooltipItem(
                  '$dateStr\n$label: ${rod.toY.toInt()}',
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
                  if (idx < 0 || idx >= sortedDays.length) return const SizedBox.shrink();
                  final day = sortedDays[idx];
                  final weekdayStr = switch (day.weekday) {
                    1 => 'Seg',
                    2 => 'Ter',
                    3 => 'Qua',
                    4 => 'Qui',
                    5 => 'Sex',
                    6 => 'Sáb',
                    _ => 'Dom',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      weekdayStr,
                      style: theme.fontStyleBase(TextStyle(
                        color: theme.textSecondary,
                        fontSize: 10,
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

  Widget _buildInsightsCard(AppThemeData theme, WeeklySummaryData data) {
    String getDivisionLabel(DivisionType type) {
      return switch (type) {
        DivisionType.morning => 'Manhã',
        DivisionType.afternoon => 'Tarde',
        DivisionType.night => 'Noite',
        DivisionType.tomorrow => 'Amanhã',
      };
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: theme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'INSIGHTS DA SEMANA',
                style: theme.fontStyleMono(TextStyle(
                  color: theme.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Período Mais Produtivo:',
                style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
              ),
              Text(
                getDivisionLabel(data.bestDivision),
                style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Mais Concluída:',
                style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  data.mostCompletedTask,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.fontStyleBase(TextStyle(color: theme.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
