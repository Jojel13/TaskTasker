import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ParticlesBackground extends StatefulWidget {
  final bool intensive;
  
  const ParticlesBackground({super.key, this.intensive = false});

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  final Random _rnd = Random();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(_tick)
      ..repeat();
      
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final count = widget.intensive ? 40 : 15;
      _particles = List.generate(count, (_) => _generateParticle(size));
      _initialized = true;
    });
  }

  void _tick() {
    if (!_initialized || !mounted || _particles.isEmpty) return;
    
    // Fallback if context is somehow unavailable during tick
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(1000, 1000);
    
    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      
      if (p.x < 0) p.x = size.width;
      if (p.x > size.width) p.x = 0;
      if (p.y < 0) p.y = size.height;
      if (p.y > size.height) p.y = 0;
    }
    // No setState needed. The CustomPainter repaints because we pass _controller to it.
  }

  _Particle _generateParticle(Size size) {
    return _Particle(
      x: _rnd.nextDouble() * size.width,
      y: _rnd.nextDouble() * size.height,
      vx: (_rnd.nextDouble() - 0.5) * (widget.intensive ? 2 : 0.8),
      vy: (_rnd.nextDouble() - 0.5) * (widget.intensive ? 2 : 0.8) - (widget.intensive ? 1 : 0.2), 
      radius: _rnd.nextDouble() * 1.5 + 1,
      color: _rnd.nextBool() ? AppColors.primary : AppColors.secondary,
      opacity: _rnd.nextDouble() * 0.3 + 0.1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _ParticlesPainter(
        particles: _particles, 
        intensive: widget.intensive,
        repaint: _controller,
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, radius, opacity;
  Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.radius, required this.color, required this.opacity});
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final bool intensive;

  _ParticlesPainter({
    required this.particles, 
    required this.intensive,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    
    final paint = Paint()..style = PaintingStyle.fill;
    
    final connectionPaint = Paint()..strokeWidth = 0.5;
    final threshold = intensive ? 70.0 : 40.0;
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
          final opacity = (1 - (dist / threshold)) * 0.3;
          connectionPaint.color = p1.color.withValues(alpha: opacity);
          canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), connectionPaint);
        }
      }
      
      paint.color = p1.color.withValues(alpha: p1.opacity);
      canvas.drawCircle(Offset(p1.x, p1.y), p1.radius, paint);
      
      paint.color = p1.color.withValues(alpha: p1.opacity * 0.2);
      canvas.drawCircle(Offset(p1.x, p1.y), p1.radius * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
