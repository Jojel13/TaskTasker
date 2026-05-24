import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/core_providers.dart';

class SapoMascotWidget extends ConsumerStatefulWidget {
  final double size;
  final bool isHeader;
  
  const SapoMascotWidget({
    super.key,
    this.size = 90,
    this.isHeader = false,
  });

  @override
  ConsumerState<SapoMascotWidget> createState() => _SapoMascotWidgetState();
}

class _SapoMascotWidgetState extends ConsumerState<SapoMascotWidget> {
  int _currentFrame = 1; // 1: dormindo, 2: abrindo olho, 3: feliz/acordado
  Timer? _cycleTimer;
  bool _isInteracting = false;
  final List<_FloatingHeart> _hearts = [];

  @override
  void initState() {
    super.initState();
    _startIdleCycle();
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  void _startIdleCycle() {
    _cycleTimer?.cancel();
    _cycleTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_isInteracting || !mounted) return;
      
      // Sequência de acordar suave e olhar pros lados
      setState(() => _currentFrame = 2);
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isInteracting || !mounted) return;
      
      setState(() => _currentFrame = 4); // Olha para um lado
      await Future.delayed(const Duration(milliseconds: 600));
      if (_isInteracting || !mounted) return;
      
      setState(() => _currentFrame = 5); // Olha para o outro
      await Future.delayed(const Duration(milliseconds: 600));
      if (_isInteracting || !mounted) return;
      
      setState(() => _currentFrame = 2);
      await Future.delayed(const Duration(milliseconds: 300));
      if (_isInteracting || !mounted) return;
      
      setState(() => _currentFrame = 1);
    });
  }

  void _onTap() async {
    if (_isInteracting) return;
    
    setState(() {
      _isInteracting = true;
      _currentFrame = 3; // Acorda feliz na hora
      _addHearts();
    });
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _currentFrame = 6);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _currentFrame = 7);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _currentFrame = 8);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _currentFrame = 9);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _currentFrame = 10);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _currentFrame = 11);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isInteracting = false;
        _currentFrame = 1;
      });
    }
  }

  void _addHearts() {
    final rand = math.Random();
    _hearts.clear();
    for (int i = 0; i < 3; i++) {
      _hearts.add(
        _FloatingHeart(
          id: DateTime.now().microsecondsSinceEpoch + i,
          dx: (rand.nextDouble() - 0.5) * 40,
          dy: -15.0 - (rand.nextDouble() * 20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    final framePath = 'assets/images/sapo_frame_$_currentFrame.png';

    Widget sapo = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.surface,
        border: Border.all(color: theme.primary, width: 2),
        boxShadow: [
          ...theme.glowShadow(theme.primary, intensity: _currentFrame == 3 ? 0.8 : 0.4),
        ],
      ),
      child: ClipOval(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: Image.asset(
            framePath,
            key: ValueKey<int>(_currentFrame),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      ),
    );

    if (_isInteracting) {
      sapo = sapo
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 400.ms, curve: Curves.easeInOut);
    }

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          sapo,
          // Corações flutuantes ao interagir
          ..._hearts.map((h) => Positioned(
            top: h.dy,
            left: (widget.size / 2) + h.dx - 10,
            child: const Icon(
              Icons.favorite,
              color: Color(0xFFFF2E93),
              size: 20,
            )
            .animate()
            .fade(duration: 300.ms)
            .scale(begin: Offset.zero, end: const Offset(1, 1), duration: 300.ms)
            .moveY(begin: 0, end: -25, duration: 1200.ms, curve: Curves.easeOut)
            .fadeOut(delay: 800.ms, duration: 400.ms),
          )),
        ],
      ),
    );
  }
}

class _FloatingHeart {
  final int id;
  final double dx;
  final double dy;
  _FloatingHeart({required this.id, required this.dx, required this.dy});
}
