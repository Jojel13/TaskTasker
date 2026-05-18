import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/enums.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Análise', style: AppTextStyles.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: analyticsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Erro ao carregar dados: $err', style: const TextStyle(color: AppColors.taskRed))),
          data: (data) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Painel de Streak
                  _buildStreakPanel(data.streakDays),
                  const SizedBox(height: 32),
                  
                  // Resumo Rápido
                  _buildSummaryStats(data),
                  
                  const SizedBox(height: 32),
                  
                  // Gráfico de Barras: Produtividade nos últimos dias
                  const Text('Desempenho Semanal', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildBarChart(data.dailyStats),
                  
                  // Gráfico Donut: Distribuição por Cor
                  const Text('Distribuição de Cores', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDonutChart(data.tasksByColor),
                  
                  const SizedBox(height: 32),
                  
                  // Heatmap: Atividade
                  const Text('Mapa de Atividades', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHeatmap(data.dailyStats),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDonutChart(Map<TaskColor, int> byColor) {
    int total = byColor.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('Sem tarefas registradas.', style: TextStyle(color: AppColors.textMuted)));
    }

    Color getColor(TaskColor color) {
      switch (color) {
        case TaskColor.red: return AppColors.taskRed;
        case TaskColor.yellow: return AppColors.taskYellow;
        case TaskColor.blue: return AppColors.taskBlue;
        case TaskColor.standard: return AppColors.primary;
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
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                  Text(getLabel(e.key), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(List<DailyStats> dailyStats) {
    if (dailyStats.isEmpty) {
      return const Center(child: Text('Ainda não há dados suficientes.', style: TextStyle(color: AppColors.textMuted)));
    }

    Map<DateTime, int> datasets = {};
    for (var stat in dailyStats) {
      // Remover horas para o HeatmapCalendar funcionar bem
      final d = DateTime(stat.date.year, stat.date.month, stat.date.day);
      datasets[d] = stat.completed;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: HeatMap(
        datasets: datasets,
        colorMode: ColorMode.opacity,
        showText: false,
        scrollable: true,
        colorsets: const {
          1: AppColors.primary,
        },
        onClick: (value) {
          // Placeholder para clicar em um dia específico
        },
        defaultColor: AppColors.background,
        textColor: AppColors.textSecondary,
        margin: const EdgeInsets.all(2),
        borderRadius: 4,
        size: 24,
      ),
    );
  }

  Widget _buildBarChart(List<DailyStats> dailyStats) {
    if (dailyStats.isEmpty) {
      return const Center(child: Text('Ainda não há dados suficientes.', style: TextStyle(color: AppColors.textMuted)));
    }

    // Para exibir corretamente no gráfico (eixo X ordenado do mais antigo pro mais recente)
    final sortedStats = List<DailyStats>.from(dailyStats)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Pegamos os últimos 7 dias no máximo
    final displayStats = sortedStats.length > 7 ? sortedStats.sublist(sortedStats.length - 7) : sortedStats;
    double maxY = 1.0;
    for (var stat in displayStats) {
      final total = (stat.completed + stat.failed).toDouble();
      if (total > maxY) maxY = total;
    }
    
    // Adicionar margem de respiro no topo
    maxY += 2;

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, right: 16, left: 0, bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.background.withValues(alpha: 0.9),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final stat = displayStats[groupIndex];
                return BarTooltipItem(
                  '${stat.date.day}/${stat.date.month}\n',
                  const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '${stat.completed} concluídas\n',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.normal, fontSize: 12),
                    ),
                    TextSpan(
                      text: '${stat.failed} falhas',
                      style: const TextStyle(color: AppColors.taskRed, fontWeight: FontWeight.normal, fontSize: 12),
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
                      style: TextStyle(
                        color: isToday ? AppColors.accent : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Omitimos os números do eixo Y para manter o design limpo
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border.withValues(alpha: 0.2),
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
                    BarChartRodStackItem(0, stat.completed.toDouble(), AppColors.primary),
                    BarChartRodStackItem(stat.completed.toDouble(), (stat.completed + stat.failed).toDouble(), AppColors.taskRed),
                  ],
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: AppColors.background.withValues(alpha: 0.5),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStreakPanel(int streakDays) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.taskYellow.withValues(alpha: 0.3)),
        boxShadow: AppColors.glowShadow(AppColors.taskYellow, intensity: 0.1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.taskYellow, size: 32)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(begin: 1.0, end: 1.2, duration: 800.ms)
                  .tint(color: Colors.orangeAccent, duration: 800.ms),
              const SizedBox(width: 12),
              Text(
                '$streakDays',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'DIAS\nSEGUIDOS',
                style: TextStyle(
                  color: AppColors.taskYellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Mantenha o foco! Cada dia conta.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(AnalyticsData data) {
    final total = data.totalTasksCompleted + data.totalTasksFailed;
    final successRate = total > 0 ? (data.totalTasksCompleted / total * 100).toInt() : 0;
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Taxa de Sucesso',
            value: '$successRate%',
            icon: Icons.track_changes_rounded,
            color: successRate >= 70 ? AppColors.accent : AppColors.taskYellow,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Completadas',
            value: '${data.totalTasksCompleted}',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
