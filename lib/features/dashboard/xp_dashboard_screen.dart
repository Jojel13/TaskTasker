import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_config.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/xp_service.dart';
import '../../shared/widgets/sapo_mascot_widget.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class XpDashboardScreen extends ConsumerWidget {
  const XpDashboardScreen({super.key});

  String _getMascotName(int level) {
    if (level <= 2)  return 'Sapo Iniciante';
    if (level <= 5)  return 'Sapo Treinado';
    if (level <= 9)  return 'Sapo Dedicado';
    if (level <= 14) return 'Sapo Expert';
    if (level <= 19) return 'Sapo Mestre';
    if (level <= 29) return 'Sapo Lendário';
    return 'Sapo Imortal';
  }

  String _getMascotSpeech(int level, int streak) {
    if (streak >= 15) return 'Incrível! Você é uma máquina com $streak dias de foco consecutivo!';
    if (streak >= 7) return 'Excelente ritmo! $streak dias seguidos, continue assim!';
    if (streak > 0) return 'O sapinho aprova o seu empenho! Mantendo o streak de $streak dias!';
    if (level <= 2) return 'Olá, novato! Vamos começar a organizar a sua rotina diária hoje?';
    if (level <= 5) return 'Você está progredindo muito bem! Que tal criarmos novas tarefas no Radar?';
    return 'Rumo à maestria! Otimize o seu dia para ganhar mais XP!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    if (profile == null) return Scaffold(backgroundColor: theme.background);

    final totalXp = profile.totalXP;
    final level = profile.currentLevel;
    final accumulatedBeforeCurrent = XpService.xpAccumulatedForLevel(level);
    final xpForCurrentLevel = XpService.xpRequiredForLevel(level);
    
    final xpInCurrentLevel = totalXp - accumulatedBeforeCurrent;
    final progress = (xpForCurrentLevel > 0) ? (xpInCurrentLevel / xpForCurrentLevel).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Dashboard', style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mascot interativo animado
              const SapoMascotWidget(size: 120),
              const SizedBox(height: 8),
              // Setinha apontando para cima (△)
              CustomPaint(
                size: const Size(16, 8),
                painter: _TrianglePainter(color: theme.surfaceVariant.withValues(alpha: 0.8)),
              ),
              // Balão de fala do Sapo Mascot posicionado abaixo do mascote
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.accent.withValues(alpha: 0.35), width: 1.0),
                  boxShadow: theme.useGlowBorder ? theme.glowShadow(theme.accent, intensity: 0.15) : null,
                ),
                child: Text(
                  _getMascotSpeech(level, profile.streakDays),
                  textAlign: TextAlign.center,
                  style: theme.fontStyleBase(TextStyle(
                    color: theme.textPrimary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  )),
                ),
              ),
              const SizedBox(height: 16),
              Text(_getMascotName(level), style: theme.fontStyleBase(AppTextStyles.titleLarge).copyWith(color: theme.textPrimary)),
              Text('Nível $level', style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.primary)),
              const SizedBox(height: 24),
              
              // XP Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('XP TOTAL: $totalXp', style: theme.fontStyleMono(AppTextStyles.labelSmall).copyWith(color: theme.textMuted)),
                      Text('$xpInCurrentLevel / $xpForCurrentLevel XP', style: theme.fontStyleMono(AppTextStyles.labelSmall).copyWith(color: theme.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: constraints.maxWidth * progress,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: theme.useGlowBorder ? theme.glowShadow(theme.primary, intensity: 0.8) : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department_rounded,
                      color: theme.taskYellow,
                      title: 'STREAK ATUAL',
                      value: '${profile.streakDays} dias',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events_rounded,
                      color: theme.taskBlue,
                      title: 'RECORDE',
                      value: '${profile.streakRecord} dias',
                      theme: theme,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Heatmap
              Text('HISTÓRICO DE PRODUTIVIDADE', style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.textMuted)),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final heatmapAsync = ref.watch(heatmapProvider);
                  return heatmapAsync.when(
                    loading: () => Center(child: CircularProgressIndicator(color: theme.primary)),
                    error: (err, _) => Text('Erro: $err', style: theme.fontStyleBase(TextStyle(color: theme.taskRed))),
                    data: (dataset) {
                      if (dataset.isEmpty) {
                        return Center(child: Text('Nenhum dado ainda.', style: theme.fontStyleBase(TextStyle(color: theme.textMuted))));
                      }
                      return HeatMap(
                        datasets: dataset,
                        colorMode: ColorMode.opacity,
                        showText: false,
                        scrollable: true,
                        size: 30,
                        colorsets: {
                          1: theme.taskYellow, // 1-24%
                          2: theme.taskBlue, // 25-49%
                          3: theme.accent, // 50-74%
                          4: theme.primary, // 75-100%
                        },
                        defaultColor: theme.surfaceVariant,
                        textColor: theme.textSecondary,
                        onClick: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Atividade no dia ${value.day}/${value.month}'),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                      );
                    },
                  );
                },
              ),
              // Histórico de Conquistas de XP
              const SizedBox(height: 40),
              Text('CONQUISTAS DE XP RECENTES', style: theme.fontStyleBase(AppTextStyles.labelSmall).copyWith(color: theme.textMuted)),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final xpEventsAsync = ref.watch(recentXpEventsProvider);
                  return xpEventsAsync.when(
                    loading: () => Center(child: CircularProgressIndicator(color: theme.primary)),
                    error: (err, _) => Text('Erro: $err', style: theme.fontStyleBase(TextStyle(color: theme.taskRed))),
                    data: (events) {
                      if (events.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('Nenhum ganho de XP registrado ainda.', style: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 13))),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: events.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final event = events[idx];
                          final timeStr = DateFormat('dd/MM HH:mm').format(event.earnedAt);
                          final isPositive = event.amount >= 0;
                          final accentOrRed = isPositive ? theme.accent : theme.taskRed;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(theme.borderRadius > 12 ? 12 : theme.borderRadius),
                              border: Border.all(color: theme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: accentOrRed.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPositive ? Icons.add_rounded : Icons.remove_rounded,
                                    size: 16,
                                    color: accentOrRed,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.description,
                                        style: theme.fontStyleBase(TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeStr,
                                        style: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isPositive ? "+" : ""}${event.amount} XP',
                                  style: theme.fontStyleMono(TextStyle(
                                    color: accentOrRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  )),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final AppThemeData theme;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.borderRadius > 16 ? 16 : theme.borderRadius),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
          const SizedBox(height: 4),
          Text(value, style: theme.fontStyleBase(AppTextStyles.titleMedium).copyWith(color: theme.textPrimary)),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
