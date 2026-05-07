import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class RadarScreen extends ConsumerWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                 const Icon(Icons.radar_rounded, color: AppColors.taskYellow),
                 const SizedBox(width: 8),
                 Text('RADAR', style: AppTextStyles.displayMedium),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📡', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  const Text('Radar vazio no momento.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Você não possui tasks pendentes!', style: AppTextStyles.monoSmall.copyWith(color: AppColors.primaryDim)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
