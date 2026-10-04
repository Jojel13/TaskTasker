import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/alarm_service.dart';
import 'home_screen.dart';
import '../radar/radar_screen.dart';
import 'widgets/floating_bottom_bar.dart';
import '../routine/routine_screen.dart';
import '../routine/screens/alarm_ringing_screen.dart';
import '../../shared/models/task.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/particles_background.dart';

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _isCreatingRoutine = false;
  bool _isAlarmScreenOpen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addObserver(this);

    // P3: Escutar o notifier de navegação via tap na notificação (foreground)
    pendingPayloadNotifier.addListener(_onPendingPayloadChanged);

    // P3: Verificar cold-start via tap em notificação (app estava fechado)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkColdStartNotification();
      _checkActiveAlarm();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    pendingPayloadNotifier.removeListener(_onPendingPayloadChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkActiveAlarm();
    }
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  /// P3: Chamado quando o notifier sinaliza uma task pendente (toque em foreground)
  void _onPendingPayloadChanged() {
    final payload = pendingPayloadNotifier.value;
    if (payload != null) {
      pendingPayloadNotifier.value = null; // Limpa antes de navegar
      _handlePayload(payload);
    }
  }

  /// P3: Verificar se o app foi aberto via toque em notificação (cold start)
  Future<void> _checkColdStartNotification() async {
    final payload = await NotificationService.instance.checkLaunchNotification();
    if (payload != null && mounted) {
      _handlePayload(payload);
    }
  }

  /// Warm start: quando o full-screen intent traz o app para frente,
  /// verifica se há alarme disparando de task não concluída
  Future<void> _checkActiveAlarm() async {
    if (_isAlarmScreenOpen || !mounted) return;
    try {
      final active = await NotificationService.instance.plugin.getActiveNotifications();
      for (final n in active) {
        if (n.channelId == AlarmService.alarmChannelId ||
            n.channelId == AlarmService.alarmSilentChannelId) {
          final payload = n.payload;
          if (payload != null) {
            _handlePayload(payload);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar alarmes ativos no resumed: $e');
    }
  }

  Future<void> _handlePayload(String payload) async {
    if (!mounted) return;
    final svc = ref.read(routineServiceProvider);
    final isar = ref.read(isarProvider);

    Task? task;
    if (payload.startsWith('complete_task_')) {
      final taskId = int.tryParse(payload.replaceFirst('complete_task_', ''));
      if (taskId != null) {
        task = await isar.tasks.get(taskId);
      }
    } else if (payload.startsWith('habit_alarm_')) {
      final habitId = payload.replaceFirst('habit_alarm_', '');
      task = await svc.resolveHabitTaskForToday(habitId, createIfMissing: true);
    }

    if (task == null || !mounted) return;

    // Se alarme em tela cheia e task pendente, abre AlarmRingingScreen
    if (task.alarmFullScreen && task.status != TaskStatus.completed) {
      if (_isAlarmScreenOpen) return;
      _isAlarmScreenOpen = true;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (c, a1, a2) => AlarmRingingScreen(task: task!),
          transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      _isAlarmScreenOpen = false;
      return;
    }

    // Caso contrário, abre a rotina de hoje dando scroll até a task
    final routine = await svc.findTodayRoutine();
    if (routine == null || !mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => RoutineScreen(
          routine: routine,
          scrollToTaskId: task!.id,
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
