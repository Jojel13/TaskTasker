import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/core_providers.dart';
import '../../core/theme/theme_config.dart';
import '../../shared/models/enums.dart';

class ParticlesBackground extends ConsumerStatefulWidget {
  final bool intensive;
  
  const ParticlesBackground({super.key, this.intensive = false});

  @override
  ConsumerState<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends ConsumerState<ParticlesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  final Random _rnd = Random();
  bool _initialized = false;
  AppThemeType? _currentThemeType;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(_tick)
      ..repeat();
      
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initParticles();
    });
  }

  void _initParticles() {
    final size = MediaQuery.of(context).size;
    final theme = ref.read(currentThemeProvider);
    _currentThemeType = theme.type;
    
    final count = widget.intensive ? (theme.particleCount * 2.5).toInt() : theme.particleCount;
    _particles = List.generate(count, (_) => _generateParticle(size, theme));
    _initialized = true;
  }

  void _tick() {
    if (!_initialized || !mounted || _particles.isEmpty) return;
    
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(1000, 1000);
    final theme = ref.read(currentThemeProvider);

    // Se o tema mudou de tipo, ajusta a quantidade de partículas dinamicamente se necessário
    if (_currentThemeType != theme.type) {
      _currentThemeType = theme.type;
      final targetCount = widget.intensive ? (theme.particleCount * 2.5).toInt() : theme.particleCount;
      if (_particles.length < targetCount) {
        final newParticles = List.generate(
          targetCount - _particles.length,
          (_) => _generateParticle(size, theme),
        );
        _particles.addAll(newParticles);
      } else if (_particles.length > targetCount) {
        _particles = _particles.sublist(0, targetCount);
      }
    }
    
    for (var p in _particles) {
      // 1. Interpolador sutil de cores
      final targetColor = theme.particleColors[p.colorIndex % theme.particleColors.length];
      p.color = Color.lerp(p.color, targetColor, 0.05) ?? targetColor;
      
      // 2. Velocidade e direção dependendo do formato de partícula do tema
      double targetVx = p.vx;
      double targetVy = p.vy;
      
      switch (theme.particleShape) {
        case ParticleShape.binary:
          targetVx = 0.0;
          targetVy = (1.2 + p.radiusScale * 0.8) * theme.particleSpeed;
          break;
        case ParticleShape.ember:
          p.angle += p.angleSpeed;
          targetVx = sin(p.angle) * 0.3 * theme.particleSpeed;
          targetVy = -1.2 * theme.particleSpeed * p.radiusScale * 0.7;
          break;
        case ParticleShape.bubble:
          p.angle += p.angleSpeed;
          targetVx = sin(p.angle) * 0.4 * theme.particleSpeed;
          targetVy = -0.7 * theme.particleSpeed * p.radiusScale * 0.6;
          break;
        case ParticleShape.leaf:
        case ParticleShape.sakura:
          p.angle += p.angleSpeed;
          targetVx = (sin(p.angle) * 0.5 - 0.3) * theme.particleSpeed; // vento para esquerda
          targetVy = 0.6 * theme.particleSpeed * p.radiusScale;
          break;
        case ParticleShape.organic:
          p.angle += p.angleSpeed * 0.2;
          targetVx = p.baseVx * theme.particleSpeed;
          targetVy = p.baseVy * theme.particleSpeed;
          break;
        case ParticleShape.cross:
          p.angle += p.angleSpeed;
          targetVx = p.baseVx * theme.particleSpeed;
          targetVy = p.baseVy * theme.particleSpeed;
          break;
        default: // circle, star
          targetVx = p.baseVx * theme.particleSpeed;
          targetVy = p.baseVy * theme.particleSpeed;
      }
      
      p.vx = ui.lerpDouble(p.vx, targetVx, 0.05) ?? targetVx;
      p.vy = ui.lerpDouble(p.vy, targetVy, 0.05) ?? targetVy;
      
      p.x += p.vx;
      p.y += p.vy;
      
      // Reposicionamento suave fora das bordas
      if (p.x < -30) p.x = size.width + 30;
      if (p.x > size.width + 30) p.x = -30;
      
      if (theme.particleShape == ParticleShape.binary) {
        if (p.y > size.height + 30) {
          p.y = -30;
          p.x = _rnd.nextDouble() * size.width;
        }
      } else {
        if (p.y < -30) p.y = size.height + 30;
        if (p.y > size.height + 30) p.y = -30;
      }
      
      // 3. Suavizar raio
      double targetRadius = p.radiusScale;
      if (theme.particleShape == ParticleShape.bubble) {
        targetRadius = p.radiusScale * 2.8;
      } else if (theme.particleShape == ParticleShape.binary) {
        targetRadius = p.radiusScale * 1.8;
      } else if (theme.particleShape == ParticleShape.leaf) {
        targetRadius = p.radiusScale * 2.2;
      } else if (theme.particleShape == ParticleShape.star) {
        targetRadius = p.radiusScale * 2.0;
      }
      p.radius = ui.lerpDouble(p.radius, targetRadius, 0.05) ?? targetRadius;
      
      // 4. Suavizar opacidade
      final targetOpacity = theme.particleOpacity * p.opacityScale;
      p.opacity = ui.lerpDouble(p.opacity, targetOpacity, 0.05) ?? targetOpacity;
    }
  }

  _Particle _generateParticle(Size size, AppThemeData theme) {
    final scale = _rnd.nextDouble() * 2.0 + 1.0;
    final colorIdx = _rnd.nextInt(theme.particleColors.length);
    final baseVx = (_rnd.nextDouble() - 0.5) * (widget.intensive ? 2.2 : 0.8);
    final baseVy = (_rnd.nextDouble() - 0.5) * (widget.intensive ? 2.2 : 0.8) - (widget.intensive ? 1.2 : 0.2);
    
    return _Particle(
      x: _rnd.nextDouble() * size.width,
      y: _rnd.nextDouble() * size.height,
      vx: baseVx * theme.particleSpeed,
      vy: baseVy * theme.particleSpeed,
      baseVx: baseVx,
      baseVy: baseVy,
      radius: scale,
      radiusScale: scale,
      color: theme.particleColors[colorIdx],
      colorIndex: colorIdx,
      opacity: theme.particleOpacity * (_rnd.nextDouble() * 0.4 + 0.6),
      opacityScale: _rnd.nextDouble() * 0.4 + 0.6,
      angle: _rnd.nextDouble() * 2 * pi,
      angleSpeed: (_rnd.nextDouble() - 0.5) * 0.04,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return CustomPaint(
      size: Size.infinite,
      painter: _ParticlesPainter(
        particles: _particles, 
        theme: theme,
        intensive: widget.intensive,
        repaint: _controller,
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, radius, opacity;
  double baseVx, baseVy;
  double radiusScale, opacityScale;
  double angle, angleSpeed;
  Color color;
  int colorIndex;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.baseVx,
    required this.baseVy,
    required this.radius,
    required this.radiusScale,
    required this.color,
    required this.colorIndex,
    required this.opacity,
    required this.opacityScale,
    required this.angle,
    required this.angleSpeed,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final AppThemeData theme;
  final bool intensive;

  _ParticlesPainter({
    required this.particles, 
    required this.theme,
    required this.intensive,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    
    final paint = Paint()..style = PaintingStyle.fill;
    
    // 1. Linhas de conexão (teias) se o tema suportar
    if (theme.connectLines) {
      final connectionPaint = Paint()..strokeWidth = 0.5;
      final threshold = intensive ? 80.0 : 45.0;
      final thresholdSq = threshold * threshold; 
      
      for (int i = 0; i < particles.length; i++) {
        final p1 = particles[i];
        for (int j = i + 1; j < particles.length; j++) {
          final p2 = particles[j];
          
          final dx = p1.x - p2.x;
          final dy = p1.y - p2.y;
          final distSq = dx * dx + dy * dy;
          
          if (distSq < thresholdSq) {
            final dist = sqrt(distSq);
            final opacity = (1 - (dist / threshold)) * 0.25 * ((p1.opacity + p2.opacity) / 2);
            connectionPaint.color = p1.color.withValues(alpha: opacity);
            canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), connectionPaint);
          }
        }
      }
    }
    
    // 2. Desenhar as partículas dependendo da forma especificada no tema
    for (var p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity);

      switch (theme.particleShape) {
        case ParticleShape.star:
          _drawStar(canvas, Offset(p.x, p.y), p.radius, paint);
          break;
          
        case ParticleShape.binary:
          final textPainter = TextPainter(
            text: TextSpan(
              text: p.colorIndex % 2 == 0 ? '0' : '1',
              style: GoogleFonts.shareTechMono(
                color: p.color.withValues(alpha: p.opacity),
                fontSize: p.radius * 5.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(canvas, Offset(p.x - textPainter.width / 2, p.y - textPainter.height / 2));
          break;
          
        case ParticleShape.organic:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.angle);
          canvas.drawOval(
            Rect.fromCenter(center: Offset.zero, width: p.radius * 2.8, height: p.radius * 1.5),
            paint,
          );
          canvas.restore();
          break;
          
        case ParticleShape.cross:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.angle);
          final strokePaint = Paint()
            ..color = p.color.withValues(alpha: p.opacity)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          canvas.drawLine(Offset(-p.radius, 0), Offset(p.radius, 0), strokePaint);
          canvas.drawLine(Offset(0, -p.radius), Offset(0, p.radius), strokePaint);
          canvas.restore();
          break;
          
        case ParticleShape.ember:
          paint.color = p.color.withValues(alpha: p.opacity * (0.6 + 0.4 * sin(p.angle * 10))); // cintilação
          canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
          paint.color = p.color.withValues(alpha: p.opacity * 0.15);
          canvas.drawCircle(Offset(p.x, p.y), p.radius * 3.5, paint);
          break;
          
        case ParticleShape.sakura:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.angle);
          final path = Path();
          path.moveTo(0, -p.radius * 1.4);
          path.quadraticBezierTo(p.radius, -p.radius * 0.8, p.radius * 0.2, p.radius * 1.4);
          path.quadraticBezierTo(-p.radius * 0.8, p.radius * 0.6, 0, -p.radius * 1.4);
          canvas.drawPath(path, paint);
          canvas.restore();
          break;

        case ParticleShape.leaf:
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.angle);
          final path = Path();
          // Desenha formato folha
          path.moveTo(0, -p.radius * 1.6);
          path.quadraticBezierTo(p.radius * 1.1, -p.radius * 0.5, 0, p.radius * 1.6);
          path.quadraticBezierTo(-p.radius * 1.1, -p.radius * 0.5, 0, -p.radius * 1.6);
          canvas.drawPath(path, paint);
          canvas.restore();
          break;

        case ParticleShape.bubble:
          final strokePaint = Paint()
            ..color = p.color.withValues(alpha: p.opacity)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(Offset(p.x, p.y), p.radius, strokePaint);
          // Pequeno reflexo interno
          paint.color = p.color.withValues(alpha: p.opacity * 0.4);
          canvas.drawCircle(Offset(p.x - p.radius * 0.3, p.y - p.radius * 0.3), p.radius * 0.2, paint);
          break;
          
        default: // circle
          canvas.drawCircle(Offset(p.x, p.y), p.radius, paint);
          paint.color = p.color.withValues(alpha: p.opacity * 0.2);
          canvas.drawCircle(Offset(p.x, p.y), p.radius * 2.5, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size * 2.0);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size * 2.0, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size * 2.0);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size * 2.0, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size * 2.0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
