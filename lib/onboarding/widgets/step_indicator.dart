// lib/onboarding/widgets/step_indicator.dart
import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/scale_config.dart';

class StepIndicator extends StatelessWidget {
  final int currentPage;
  final int stepCount;

  const StepIndicator({
    super.key,
    required this.currentPage,
    this.stepCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        stepCount,
        (index) => _buildDot(context, index),
      ),
    );
  }

  Widget _buildDot(BuildContext context, int index) {
    final scaleConfig = context.scaleConfig;
    bool isActive = currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(horizontal: scaleConfig.scale(4)),
      height: scaleConfig.scale(8),
      width: isActive ? scaleConfig.scale(24) : scaleConfig.scale(8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF24C28F) : Colors.grey[800],
        borderRadius: BorderRadius.circular(scaleConfig.scale(12)),
      ),
    );
  }
}