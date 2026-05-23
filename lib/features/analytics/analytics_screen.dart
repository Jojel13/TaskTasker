import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/theme_config.dart';
import '../../core/providers/core_providers.dart';
import '../../shared/models/enums.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Análise', style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: analyticsAsync.when(
          loading: () => Center(child: CircularProgressIndicator(color: theme.primary)),
          error: (err, _) => Center(child: Text('Erro ao carregar dados: $err', style: theme.fontStyleBase(TextStyle(color: theme.taskRed)))),
          data: (data) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Painel de Streak
                  _buildStreakPanel(theme, data.streakDays),
                  const SizedBox(height: 32),
                  
                  // Resumo Rápido
                  _buildSummaryStats(theme, data),
                  
                  const SizedBox(height: 32),

                  // Produtividade por Período
                  Text('Produtividade por Período', style: theme.fontStyleBase(TextStyle(color: theme.primary, fontSize: 16, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _buildDivisionStatsPanel(theme, context, data.divisionStats),
                  
                  const SizedBox(height: 32),
                  
                  // Gráfico de Barras: Desempenho Semanal
                  Text('Desempenho Semanal', style: theme.fontStyleBase(TextStyle(color: theme.primary, fontSize: 16, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _buildBarChart(theme, data.dailyStats),
                  
                  const SizedBox(height: 32),
                  
                  // Gráfico Donut: Distribuição por Cor
                  Text('Distribuição de Cores', style: theme.fontStyleBase(TextStyle(color: theme.primary, fontSize: 16, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _buildDonutChart(theme, data.tasksByColor),
                  
                  const SizedBox(height: 32),
                  
                  // Heatmap: Atividade
                  Text('Mapa de Atividades', style: theme.fontStyleBase(TextStyle(color: theme.primary, fontSize: 16, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _buildHeatmap(theme, data.dailyStats),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDonutChart(AppThemeData theme, Map<TaskColor, int> byColor) {
    int total = byColor.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return Center(child: Text('Sem tarefas registradas.', style: theme.fontStyleBase(TextStyle(color: theme.textMuted))));
    }

    Color getColor(TaskColor color) {
      switch (color) {
        case TaskColor.red: return theme.taskRed;
        case TaskColor.yellow: return theme.taskYellow;
        case TaskColor.blue: return theme.taskBlue;
        case TaskColor.standard: return theme.primary;
      }
    }
    
    String getLabel(TaskColor color) {
      switch (color) {
        case TaskColor.red: return 'Urgentes';
        case TaskColor.yellow: return 'Eventuais';
        case TaskColor.blue: return 'Hábitos';
        case TaskColor.standard: return 'Rotina';
      }
    }

    final sections = byColor.entries.where((e) => e.value > 0).map((e) {
      final percentage = (e.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        color: getColor(e.key),
        value: e.value.toDouble(),
        title: '$percentage%',
        radius: 40,
        titleStyle: theme.fontStyleBase(TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.textPrimary)),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius > 16 ? 16 : theme.borderRadius),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 50,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: byColor.entries.where((e) => e.value > 0).map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: getColor(e.key), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(getLabel(e.key), style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13))),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(AppThemeData theme, List<DailyStats> dailyStats) {
    if (dailyStats.isEmpty) {
      return Center(child: Text('Ainda não há dados suficientes.', style: theme.fontStyleBase(TextStyle(color: theme.textMuted))));
    }

    Map<DateTime, int> datasets = {};
    for (var stat in dailyStats) {
      if (stat.completed > 0) {
        final d = DateTime(stat.date.year, stat.date.month, stat.date.day);
        datasets[d] = stat.completed;
      }
    }

    if (datasets.isEmpty) {
      return Center(child: Text('Ainda não há dados suficientes.', style: theme.fontStyleBase(TextStyle(color: theme.textMuted))));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius > 16 ? 16 : theme.borderRadius),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: HeatMap(
        datasets: datasets,
        colorMode: ColorMode.opacity,
        showText: false,
        scrollable: true,
        colorsets: {
          1: theme.primary,
        },
        onClick: (value) {},
        defaultColor: theme.background,
        textColor: theme.textSecondary,
        margin: const EdgeInsets.all(2),
        borderRadius: 4,
        size: 24,
      ),
    );
  }

  Widget _buildBarChart(AppThemeData theme, List<DailyStats> dailyStats) {
    if (dailyStats.isEmpty) {
      return Center(child: Text('Ainda não há dados suficientes.', style: theme.fontStyleBase(TextStyle(color: theme.textMuted))));
    }

    final sortedStats = List<DailyStats>.from(dailyStats)
      ..sort((a, b) => a.date.compareTo(b.date));

    final displayStats = sortedStats.length > 7 ? sortedStats.sublist(sortedStats.length - 7) : sortedStats;
    double maxY = 1.0;
    for (var stat in displayStats) {
      final total = (stat.completed + stat.failed).toDouble();
      if (total > maxY) maxY = total;
    }
    maxY += 2;

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 16, left: 0, bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius > 16 ? 16 : theme.borderRadius),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => theme.background.withValues(alpha: 0.9),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final stat = displayStats[groupIndex];
                return BarTooltipItem(
                  '${stat.date.day}/${stat.date.month}\n',
                  theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
                  children: [
                    TextSpan(
                      text: '${stat.completed} concluídas\n',
                      style: theme.fontStyleBase(TextStyle(color: theme.primary, fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                    TextSpan(
                      text: '${stat.failed} falhas',
                      style: theme.fontStyleBase(TextStyle(color: theme.taskRed, fontWeight: FontWeight.normal, fontSize: 12)),
                    ),
                  ],
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
                  if (value.toInt() < 0 || value.toInt() >= displayStats.length) return const SizedBox.shrink();
                  final stat = displayStats[value.toInt()];
                  final isToday = stat.date.day == DateTime.now().day && stat.date.month == DateTime.now().month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      isToday ? 'Hoje' : '${stat.date.day}/${stat.date.month}',
                      style: theme.fontStyleBase(TextStyle(
                        color: isToday ? theme.accent : theme.textSecondary,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      )),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.border.withValues(alpha: 0.2),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: displayStats.asMap().entries.map((e) {
            final index = e.key;
            final stat = e.value;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (stat.completed + stat.failed).toDouble(),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  rodStackItems: [
                    BarChartRodStackItem(0, stat.completed.toDouble(), theme.primary),
                    BarChartRodStackItem(stat.completed.toDouble(), (stat.completed + stat.failed).toDouble(), theme.taskRed),
                  ],
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: theme.background.withValues(alpha: 0.5),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStreakPanel(AppThemeData theme, int streakDays) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius > 16 ? 16 : theme.borderRadius),
        border: Border.all(color: theme.taskYellow.withValues(alpha: 0.3)),
        boxShadow: theme.useGlowBorder ? theme.glowShadow(theme.taskYellow, intensity: 0.1) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 32)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.2, duration: 800.ms)
                  .tint(color: Colors.orangeAccent, duration: 800.ms),
              const SizedBox(width: 12),
              Text(
                '$streakDays',
                style: theme.fontStyleBase(TextStyle(
                  color: theme.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                )),
              ),
              const SizedBox(width: 8),
              Text(
                'DIAS\nSEGUIDOS',
                style: theme.fontStyleBase(TextStyle(
                  color: theme.taskYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mantenha o foco! Cada dia conta.',
            style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(AppThemeData theme, AnalyticsData data) {
    final total = data.totalTasksCompleted + data.totalTasksFailed;
    final successRate = total > 0 ? (data.totalTasksCompleted / total * 100).toInt() : 0;
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Taxa de Sucesso',
            value: '$successRate%',
            icon: Icons.track_changes_rounded,
            color: successRate >= 70 ? theme.accent : theme.taskYellow,
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Completadas',
            value: '${data.totalTasksCompleted}',
            icon: Icons.check_circle_outline_rounded,
            color: theme.primary,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildDivisionStatsPanel(AppThemeData theme, BuildContext context, Map<DivisionType, DivisionStats> stats) {
    String getLabel(DivisionType type) {
      switch (type) {
        case DivisionType.morning: return 'Manhã';
        case DivisionType.afternoon: return 'Tarde';
        case DivisionType.night: return 'Noite';
        case DivisionType.tomorrow: return 'Amanhã';
      }
    }

    IconData getIcon(DivisionType type) {
      switch (type) {
        case DivisionType.morning: return Icons.wb_sunny_rounded;
        case DivisionType.afternoon: return Icons.wb_cloudy_rounded;
        case DivisionType.night: return Icons.nightlight_round;
        case DivisionType.tomorrow: return Icons.arrow_forward_rounded;
      }
    }

    Color getColor(DivisionType type) {
      switch (type) {
        case DivisionType.morning: return theme.taskYellow;
        case DivisionType.afternoon: return theme.secondary;
        case DivisionType.night: return theme.accent;
        case DivisionType.tomorrow: return theme.textSecondary;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius > 16 ? 16 : theme.borderRadius),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: stats.entries.map((entry) {
          final type = entry.key;
          final stat = entry.value;
          final total = stat.total;
          final completed = stat.completed;
          final double progress = total == 0 ? 0.0 : completed / total;
          final percentage = (progress * 100).toInt();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(getIcon(type), color: getColor(type), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          getLabel(type),
                          style: theme.fontStyleBase(const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    Text(
                      '$completed/$total ($percentage%)',
                      style: theme.fontStyleMono(TextStyle(
                        color: total > 0 && completed == total ? theme.accent : theme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.background,
                    color: getColor(type),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AppThemeData theme;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: theme.fontStyleMono(TextStyle(color: theme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold))),
          const SizedBox(height: 4),
          Text(title, style: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }
}
