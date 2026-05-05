import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/isar_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  int _messageIndex = 0;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  static const List<String> _messages = [
    'INICIALIZANDO SISTEMA...',
    'CARREGANDO BANCO DE DADOS...',
    'SINCRONIZANDO ROTINAS...',
    'CALIBRANDO INTERFACE NEURAL...',
    'CONECTANDO AO NEXUS...',
    'SISTEMA ONLINE.',
  ];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _boot();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    await _step(0.12, 0);
    await IsarService.initialize();
    await _step(0.45, 1);
    await _step(0.65, 2);
    await Future.delayed(const Duration(milliseconds: 300));
    await _step(0.82, 3);
    await Future.delayed(const Duration(milliseconds: 250));
    await _step(0.95, 4);
    await Future.delayed(const Duration(milliseconds: 250));
    await _step(1.0, 5);
    await Future.delayed(const Duration(milliseconds: 700));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _step(double progress, int msgIdx) async {
    setState(() {
      _progress = progress;
      _messageIndex = msgIdx;
    });
    await Future.delayed(const Duration(milliseconds: 380));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Partículas de fundo ───────────────────────────────
          AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleController.value),
              size: Size.infinite,
            ),
          ),

          // ── Conteúdo principal ────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo
                _buildLogo(),
                const SizedBox(height: 24),

                // Nome do App
                _buildAppName(),

                const Spacer(flex: 3),

                // Barra de progresso + mensagem
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      // Mensagem animada
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _messages[_messageIndex],
                          key: ValueKey(_messageIndex),
                          style: AppTextStyles.monoXSmall.copyWith(
                            color: AppColors.primaryDim,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Progress bar
                      _buildProgressBar(),
                      const SizedBox(height: 8),

                      // Percentual
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: AppTextStyles.monoXSmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) {
        final glow = 1.0 + _pulseController.value * 0.5;
        return Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.6),
              width: 1.5,
            ),
            boxShadow: AppColors.glowShadow(AppColors.primary, intensity: glow),
          ),
          child: child,
        );
      },
      child: const Center(
        child: Text(
          '✓✓',
          style: TextStyle(
            fontSize: 40,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms)
        .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut);
  }

  Widget _buildAppName() {
    return Column(
      children: [
        Text(
          'TASK',
          style: AppTextStyles.monoLarge.copyWith(
            fontSize: 48,
            letterSpacing: 16,
            color: AppColors.primary,
            shadows: [
              Shadow(
                color: AppColors.primary.withOpacity(0.7),
                blurRadius: 20,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.4),
        Text(
          'TASKER',
          style: AppTextStyles.monoLarge.copyWith(
            fontSize: 28,
            letterSpacing: 12,
            color: AppColors.secondary,
            shadows: [
              Shadow(
                color: AppColors.secondary.withOpacity(0.7),
                blurRadius: 16,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.4),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedFractionallySizedBox(
        widthFactor: _progress,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: AppColors.glowShadow(AppColors.primary),
          ),
        ),
      ),
    );
  }
}

// ── Painter de partículas ─────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  static const int _count = 70;

  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;

    final List<Offset> positions = [];

    for (int i = 0; i < _count; i++) {
      final seed = i * 137.508; // Ângulo dourado
      final x = (seed % size.width + t * size.width * 0.25) % size.width;
      final y =
          ((seed * 1.618) % size.height + t * size.height * 0.15) % size.height;
      positions.add(Offset(x, y));

      final opacity =
          (0.08 + 0.18 * sin(t * 2 * pi + i * 0.4)).clamp(0.0, 0.35);
      final radius = (i % 4 == 0) ? 1.8 : 1.0;

      paint.color = switch (i % 4) {
        0 => AppColors.primary.withOpacity(opacity),
        1 => AppColors.secondary.withOpacity(opacity * 0.75),
        2 => AppColors.accent.withOpacity(opacity * 0.5),
        _ => AppColors.taskBlue.withOpacity(opacity * 0.4),
      };
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Linhas entre partículas próximas
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < min(i + 5, positions.length); j++) {
        final d = (positions[i] - positions[j]).distance;
        if (d < 90) {
          linePaint.color =
              AppColors.primary.withOpacity(0.06 * (1 - d / 90));
          canvas.drawLine(positions[i], positions[j], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}
