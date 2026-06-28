import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/notification_service.dart';
import 'home_screen.dart';
import '../radar/radar_screen.dart';
import 'widgets/floating_bottom_bar.dart';
import '../routine/routine_screen.dart';
import '../../shared/widgets/particles_background.dart';

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _isCreatingRoutine = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // P3: Escutar o notifier de navegação via tap na notificação (foreground)
    pendingTaskIdNotifier.addListener(_onPendingTaskIdChanged);

    // P3: Verificar cold-start via tap em notificação (app estava fechado)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkColdStartNotification();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    pendingTaskIdNotifier.removeListener(_onPendingTaskIdChanged);
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  /// P3: Chamado quando o notifier sinaliza uma task pendente (toque em foreground)
  void _onPendingTaskIdChanged() {
    final taskId = pendingTaskIdNotifier.value;
    if (taskId != null) {
      pendingTaskIdNotifier.value = null; // Limpa antes de navegar
      _navigateToTask(taskId);
    }
  }

  /// P3: Verificar se o app foi aberto via toque em notificação (cold start)
  Future<void> _checkColdStartNotification() async {
    final taskId = await NotificationService.instance.checkLaunchNotification();
    if (taskId != null && mounted) {
      _navigateToTask(taskId);
    }
  }

  /// P3: Localiza a rotina de hoje e abre o [RoutineScreen] com scroll até a task.
  Future<void> _navigateToTask(int taskId) async {
    if (!mounted) return;
    final svc = ref.read(routineServiceProvider);
    final routine = await svc.findTodayRoutine();
    if (routine == null || !mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => RoutineScreen(
          routine: routine,
          scrollToTaskId: taskId,
        ),
        transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onPlusTap() async {
    if (_isCreatingRoutine) return;
    setState(() => _isCreatingRoutine = true);
    try {
      final svc = ref.read(routineServiceProvider);
      final routine = await svc.createRoutine();
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (c, a1, a2) => RoutineScreen(routine: routine),
            transitionsBuilder: (c, anim, a2, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 350),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingRoutine = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(currentThemeProvider);
    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentIndex == 0
                  ? const ParticlesBackground(intensive: false)
                  : const SizedBox.shrink(),
            ),
          ),
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              HomeScreen(),
              RadarScreen(),
            ],
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Opacity(
        opacity: _isCreatingRoutine ? 0.5 : 1.0,
        child: FloatingBottomBar(
          currentIndex: _currentIndex,
          onNavTap: _onNavTap,
          onPlusTap: _isCreatingRoutine ? () {} : _onPlusTap,
        ),
      ),
    );
  }
}
