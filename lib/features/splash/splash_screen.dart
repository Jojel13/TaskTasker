import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/particles_background.dart';
import '../home/main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with RestorationMixin {
  double _progress = 0.0;
  String _loadingText = "Inicializando núcleo...";
  bool _isRestoring = false;

  @override
  String? get restorationId => 'splash_screen_state';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (initialRestore && oldBucket != null) {
      _isRestoring = true;
    }
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      if (_isRestoring) {
        _goToHome(animated: false);
      } else {
        _simulateLoading();
      }
    });
  }

  void _simulateLoading() async {
    // Phase 1: Boot
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() { _progress = 0.3; _loadingText = "Conectando aos servidores neurais..."; });
    
    // Phase 2: Init ISAR (already done in main, but we simulate visual delay)
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() { _progress = 0.7; _loadingText = "Sincronizando rotinas e hábitos..."; });
    
    // Phase 3: Launch
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() { _progress = 1.0; _loadingText = "Sistema operacional pronto."; });
    
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (mounted) {
      _goToHome(animated: true);
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      ...AppColors.glowShadow(AppColors.primary, intensity: 0.8),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/saposapinho.gif',
                      fit: BoxFit.cover,
                    ),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 16),
                
                // Tagline sutil abaixo do Sapinho
                Text(
                  'SAPO SAPINHO',
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontFamily: 'Share Tech Mono',
                    letterSpacing: 3,
                  ),
                ).animate().fade(delay: 600.ms),
                
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
                          boxShadow: [...AppColors.glowShadow(AppColors.primary, intensity: 1.0)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loadingText,
                        style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'Share Tech Mono'),
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
