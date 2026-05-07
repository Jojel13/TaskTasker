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
  late List<_Particle> _particles;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(() => setState(() {}))
      ..repeat();
      
    // Generates particles on the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      final count = widget.intensive ? 80 : 30;
      _particles = List.generate(count, (_) => _generateParticle(size));
    });
  }

  _Particle _generateParticle(Size size) {
    return _Particle(
      x: _rnd.nextDouble() * size.width,
      y: _rnd.nextDouble() * size.height,
      vx: (_rnd.nextDouble() - 0.5) * (widget.intensive ? 4 : 1.5),
      vy: (_rnd.nextDouble() - 0.5) * (widget.intensive ? 4 : 1.5) - (widget.intensive ? 2 : 0.5), // Tendency to go up
      radius: _rnd.nextDouble() * 2 + 1,
      color: _rnd.nextBool() ? AppColors.primary : AppColors.secondary,
      opacity: _rnd.nextDouble() * 0.5 + 0.1,
    );
  }

  void _updateParticles(Size size) {
    if (_particles.isEmpty) return;
    for (var p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      
      // Wrap around edges
      if (p.x < 0) p.x = size.width;
      if (p.x > size.width) p.x = 0;
      if (p.y < 0) p.y = size.height;
      if (p.y > size.height) p.y = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (_particles.isNotEmpty) _updateParticles(size);
    
    return CustomPaint(
      size: size,
      painter: _ParticlesPainter(_particles, widget.intensive),
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

  _ParticlesPainter(this.particles, this.intensive);

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw connections (only if close enough, and less in non-intensive to save perf)
    final connectionPaint = Paint()..strokeWidth = 0.5;
    final threshold = intensive ? 80.0 : 60.0;
    
    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      
      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final dist = sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
        
        if (dist < threshold) {
          final opacity = (1 - (dist / threshold)) * 0.3;
          connectionPaint.color = p1.color.withValues(alpha: opacity);
          canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), connectionPaint);
        }
      }
      
      // Draw particle
      paint.color = p1.color.withValues(alpha: p1.opacity);
      canvas.drawCircle(Offset(p1.x, p1.y), p1.radius, paint);
      
      // Add glow
      paint.color = p1.color.withValues(alpha: p1.opacity * 0.5);
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(p1.x, p1.y), p1.radius * 2, paint);
      paint.maskFilter = null;
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}
