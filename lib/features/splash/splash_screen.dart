import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:math' as math;
import '../../shared/widgets/particles_background.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/notification_service.dart';
import '../../shared/models/enums.dart';
import '../home/main_wrapper.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _loadingText = "Inicializando núcleo...";
  late AnimationController _ambientController;

  static const Map<AppThemeType, List<String>> _loadingMessages = {
    AppThemeType.cyberpunkDark: [
      "Inicializando núcleo neural...",
      "Sincronizando implantes cognitivos...",
      "Rede neural operacional.",
    ],
    AppThemeType.sakura: [
      "Despertando o jardim...",
      "As pétalas começam a florescer...",
      "O jardim está pronto.",
    ],
    AppThemeType.steampunk: [
      "Aquecendo as caldeiras...",
      "Calibrando engrenagens e válvulas...",
      "Pressão ideal. Pronto para operar.",
    ],
    AppThemeType.matrix: [
      "Conectando à Matrix...",
      "Compilando protocolos de simulação...",
      "Matriz ativa.",
    ],
    AppThemeType.synthwave: [
      "Sintonizando frequências de rádio...",
      "Carregando o grid de neon...",
      "Frequências operacionais online.",
    ],
    AppThemeType.minimalLight: [
      "Organizando seu dia...",
      "Carregando configurações limpas...",
      "Tudo pronto para começar.",
    ],
    AppThemeType.glassmorphism: [
      "Abrindo o portal de vidro...",
      "Refratando partículas de luz...",
      "Portal estável.",
    ],
    AppThemeType.dracula: [
      "Despertando das sombras...",
      "Invocando rotinas da noite...",
      "As sombras obedecem.",
    ],
    AppThemeType.monochrome: [
      "Inicializando sistema...",
      "Carregando tabelas de dados...",
      "Pronto.",
    ],
    AppThemeType.solarizedOchre: [
      "Acordando sob a luz solar...",
      "Preparando jornada diária...",
      "Pronto para o dia.",
    ],
    AppThemeType.ocean: [
      "Mergulhando no oceano...",
      "Navegando correntes submarinas...",
      "Profundezas acessadas.",
    ],
    AppThemeType.garden: [
      "O jardim acorda...",
      "As raízes se firmam...",
      "Natureza pronta.",
    ],
  };

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      // Solicita permissões de notificação no background logo no startup
      NotificationService.instance.requestPermissions();
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
      FlutterNativeSplash.remove();
      final theme = ref.read(currentThemeProvider);
      final messages = _loadingMessages[theme.type] ?? _loadingMessages[AppThemeType.cyberpunkDark]!;

      // Inicializa com a primeira mensagem
      if (mounted) {
        setState(() { _loadingText = messages[0]; });
      }

      // Phase 1: Boot
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() { _progress = 0.3; _loadingText = messages[0]; });
      
      // Phase 2: Init ISAR and services
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() { _progress = 0.7; _loadingText = messages[1]; });
      
      await Future.delayed(const Duration(milliseconds: 250));
      
      // Phase 3: Launch
      if (!mounted) return;
      setState(() { _progress = 1.0; _loadingText = messages[2]; });
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (mounted) {
        _goToHome(animated: true);
      }
    } catch (e) {
      if (mounted) {
        _goToHome(animated: false);
      }
    }
  }

  void _goToHome({required bool animated}) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => const MainWrapper(),
        transitionsBuilder: (c, anim, a2, child) {
          if (!animated) return child;
          final fadeTransition = FadeTransition(opacity: anim, child: child);
          final scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          );
          return ScaleTransition(scale: scaleAnim, child: fadeTransition);
        },
        transitionDuration: animated ? const Duration(milliseconds: 800) : Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);

    return Scaffold(
      backgroundColor: theme.background,
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
                        theme.primary.withValues(alpha: 0.14),
                        theme.background,
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
                      color: theme.primary.withValues(alpha: 0.8),
                      width: 2.5,
                    ),
                    boxShadow: theme.useGlowBorder
                        ? theme.glowShadow(theme.primary, intensity: 1.0)
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 12,
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
                  style: theme.fontStyleMono(TextStyle(
                    fontSize: 24,
                    color: theme.textPrimary,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  )),
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
                          style: theme.fontStyleMono(TextStyle(
                            color: theme.textPrimary.withValues(alpha: 0.7),
                            fontSize: 11,
                            letterSpacing: 1,
                          )),
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
                            color: theme.primary.withValues(alpha: 0.4),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.15),
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
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.primary,
                                        theme.accent,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.primary.withValues(alpha: 0.6),
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
