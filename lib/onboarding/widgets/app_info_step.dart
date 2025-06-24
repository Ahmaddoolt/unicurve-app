import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/onboarding/widgets/feature_card.dart';

class AppInfoStep extends StatefulWidget {
  const AppInfoStep({super.key});

  @override
  State<AppInfoStep> createState() => _AppInfoStepState();
}

class _AppInfoStepState extends State<AppInfoStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _animations = List.generate(
      6,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 * index,
            0.5 + 0.1 * index,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    final textTheme = Theme.of(context).textTheme;
    const primaryColor = Color(0xFF24C28F);

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: scaleConfig.heightPercentage(0.08)),
      child: Column(
        children: [
          _AnimatedUIElement(
            animation: _animations[0],
            child: Container(
              padding: EdgeInsets.all(scaleConfig.scale(20)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1A),
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: primaryColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.school_outlined,
                color: primaryColor,
                size: scaleConfig.scale(40),
              ),
            ),
          ),
          SizedBox(height: scaleConfig.scale(24)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AnimatedUIElement(
                  animation: _animations[1],
                  child: Text(
                    'onboarding_welcome_title'.tr,
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: scaleConfig.scaleText(34),
                    ),
                  ),
                ),
                SizedBox(height: scaleConfig.scale(12)),
                _AnimatedUIElement(
                  animation: _animations[1],
                  child: Text(
                    'onboarding_welcome_subtitle'.tr,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.grey[400],
                      fontSize: scaleConfig.scaleText(16),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: scaleConfig.scale(40)),
          _AnimatedUIElement(
            animation: _animations[2],
            child: FeatureCard(
              icon: Icons.account_tree_outlined,
              title: 'onboarding_feature1_title'.tr,
              subtitle: 'onboarding_feature1_subtitle'.tr,
            ),
          ),
          SizedBox(height: scaleConfig.scale(20)),
          _AnimatedUIElement(
            animation: _animations[3],
            child: FeatureCard(
              icon: Icons.auto_awesome_outlined,
              title: 'onboarding_feature2_title'.tr,
              subtitle: 'onboarding_feature2_subtitle'.tr,
            ),
          ),
          SizedBox(height: scaleConfig.scale(20)),
          _AnimatedUIElement(
            animation: _animations[4],
            child: FeatureCard(
              icon: Icons.trending_up_outlined,
              title: 'onboarding_feature3_title'.tr,
              subtitle: 'onboarding_feature3_subtitle'.tr,
            ),
          ),
          SizedBox(height: scaleConfig.scale(20)),
          _AnimatedUIElement(
            animation: _animations[5],
            child: FeatureCard(
              icon: Icons.pie_chart_outline,
              title: 'onboarding_feature4_title'.tr,
              subtitle: 'onboarding_feature4_subtitle'.tr,
            ),
          ),
          SizedBox(height: scaleConfig.scale(120)),
        ],
      ),
    );
  }
}

class _AnimatedUIElement extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedUIElement({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
