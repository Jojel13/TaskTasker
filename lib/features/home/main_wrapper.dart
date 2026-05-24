import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onPlusTap() async {
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
      bottomNavigationBar: FloatingBottomBar(
        currentIndex: _currentIndex,
        onNavTap: _onNavTap,
        onPlusTap: _onPlusTap,
      ),
    );
  }
}
