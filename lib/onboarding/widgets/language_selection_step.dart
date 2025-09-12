import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/onboarding/providers/onboarding_provider.dart';

class LanguageSelectionStep extends ConsumerStatefulWidget {
  const LanguageSelectionStep({super.key});

  @override
  ConsumerState<LanguageSelectionStep> createState() =>
      _LanguageSelectionStepState();
}

class _LanguageSelectionStepState extends ConsumerState<LanguageSelectionStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animations = List.generate(
      5,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.1 * index,
            0.6 + 0.1 * index,
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleConfig.scale(24)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
                Icons.language,
                color: primaryColor,
                size: scaleConfig.scale(40),
              ),
            ),
          ),
          SizedBox(height: scaleConfig.scale(32)),
          _AnimatedUIElement(
            animation: _animations[1],
            child: Text(
              'onboarding_lang_title'.tr,
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
            animation: _animations[2],
            child: Text(
              'onboarding_lang_subtitle'.tr,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.grey[400],
                fontSize: scaleConfig.scaleText(16),
              ),
            ),
          ),
          SizedBox(height: scaleConfig.scale(48)),
          _AnimatedUIElement(
            animation: _animations[3],
            child: _LanguageCard(
              language: 'onboarding_lang_english'.tr,
              onTap:
                  () => ref
                      .read(onboardingProvider.notifier)
                      .selectLanguage(const Locale('en', 'US')),
            ),
          ),
          SizedBox(height: scaleConfig.scale(20)),
          _AnimatedUIElement(
            animation: _animations[4],
            child: _LanguageCard(
              language: 'onboarding_lang_arabic'.tr,
              onTap:
                  () => ref
                      .read(onboardingProvider.notifier)
                      .selectLanguage(const Locale('ar', 'SA')),
            ),
          ),
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

class _LanguageCard extends StatelessWidget {
  final String language;
  final VoidCallback onTap;

  const _LanguageCard({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scaleConfig = context.scaleConfig;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: scaleConfig.scale(24),
          vertical: scaleConfig.scale(20),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(scaleConfig.scale(16)),
          border: Border.all(color: Colors.grey[800]!, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: TextStyle(
                color: Colors.white,
                fontSize: scaleConfig.scaleText(20),
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: scaleConfig.scale(18),
            ),
          ],
        ),
      ),
    );
  }
}
