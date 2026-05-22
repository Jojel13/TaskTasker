import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../core/theme/app_colors.dart';
import 'dart:math' as math;
import '../../shared/widgets/particles_background.dart';
import '../../core/database/isar_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/alarm_service.dart';
import '../home/main_wrapper.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _loadingText = "Inicializando núcleo...";
  late AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _simulateLoading();
    });
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _simulateLoading() async {
    try {
      // Phase 1: Boot
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() { _progress = 0.3; _loadingText = "Conectando aos servidores neurais..."; });
      
      // Phase 2: Init ISAR and services
      await IsarService.initialize();
      if (!mounted) return;
      setState(() { _progress = 0.7; _loadingText = "Sincronizando rotinas e hábitos..."; });
      
      await NotificationService.instance.initialize();
      await AlarmService.initialize();
      
      // Phase 3: Launch
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() { _progress = 1.0; _loadingText = "Sistema operacional pronto."; });
      
      await Future.delayed(const Duration(milliseconds: 400));
      
      if (mounted) {
        _goToHome(animated: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loadingText = "Erro: $e"; });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) _goToHome(animated: true);
      }
    }
  }

  void _goToHome({required bool animated}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => const MainWrapper(),
        transitionsBuilder: (c, anim, a2, child) => 
            animated ? FadeTransition(opacity: anim, child: child) : child,
        transitionDuration: animated ? const Duration(milliseconds: 800) : Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Glowing ambient radial background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1 + 0.15 * math.sin(_ambientController.value * 2 * math.pi),
                      colors: [
                        AppColors.primary.withValues(alpha: 0.14),
                        AppColors.background,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Intense Particles
          const Positioned.fill(
            child: ParticlesBackground(intensive: true),
          ),
          
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Launch Icon container with exact rounded corners matching the app icon style (18.4% radius)
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(110 * 0.184),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(110 * 0.184 - 2.5),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                    ),
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
                
                // Upgraded Progress Bar & status text above it
                SizedBox(
                  width: 220,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          _loadingText,
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontFamily: 'Share Tech Mono',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Container(
                        height: 14,
                        width: 220,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: constraints.maxWidth * _progress,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.accent,
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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
