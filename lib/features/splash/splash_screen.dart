import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/particles_background.dart';
import '../home/main_wrapper.dart'; // We'll create this next

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  void _simulateLoading() async {
    // Phase 1: Boot
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _progress = 0.3);
    
    // Phase 2: Init ISAR (already done in main, but we simulate visual delay)
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _progress = 0.7);
    
    // Phase 3: Launch
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _progress = 1.0);
    
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (c, a1, a2) => const MainWrapper(),
          transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Intense Particles
          const Positioned.fill(
            child: ParticlesBackground(intensive: true),
          ),
          
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo placeholder (Double checkmark with glow)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      AppColors.glowShadow(AppColors.primary, intensity: 0.8),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.done_all_rounded, color: AppColors.primary, size: 40),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 32),
                
                // Typing text
                DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: 'Share Tech Mono',
                    fontSize: 24,
                    color: AppColors.textPrimary,
                    letterSpacing: 3,
                  ),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText('TASK.TASKER', speed: const Duration(milliseconds: 100)),
                    ],
                    isRepeatingAnimation: false,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Progress Bar
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2,
                        width: 200 * _progress,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          boxShadow: [AppColors.glowShadow(AppColors.primary, intensity: 1.0)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicializando núcleo...',
                        style: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 10, fontFamily: 'Share Tech Mono'),
                      ),
                    ],
                  ),
                ).animate().fade(delay: 500.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
