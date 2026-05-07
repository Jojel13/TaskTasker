import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
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
  final PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

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
         MaterialPageRoute(builder: (_) => RoutineScreen(routine: routine)),
       );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
             child: ParticlesBackground(intensive: false),
          ),
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
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
