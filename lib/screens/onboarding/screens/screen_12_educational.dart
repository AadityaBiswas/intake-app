import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_13_consistency.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 12 — Educational Screen
/// Explains how the app uses region to personalize recommendations.
/// Animated icon pulse + staggered bullet reveals.
class Screen12Educational extends StatefulWidget {
  final OnboardingData data;
  const Screen12Educational({super.key, required this.data});

  @override
  State<Screen12Educational> createState() => _Screen12EducationalState();
}

class _Screen12EducationalState extends State<Screen12Educational>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _contentCtrl;
  late List<Animation<double>> _bulletFades;

  @override
  void initState() {
    super.initState();

    // Gentle pulse on icon (repeating)
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Staggered bullet reveals
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bulletFades = List.generate(4, (i) {
      final start = 0.2 + i * 0.15;
      final end = (start + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _contentCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepNum = widget.data.showIntensityScreen ? 12 : 11;
    return OnboardingScaffold(
      currentStep: stepNum,
      totalSteps: widget.data.totalSteps,
      banners: [
        CalculationBanner(
          label: 'Calculating your BMI…',
          completeLabel: 'BMI calculated',
          durationSeconds: 30,
          startTime: widget.data.bmiCalculationStartTime,
          onComplete: () => widget.data.bmiCalculationComplete = true,
        ),
        if (widget.data.macroCalculationStartTime != null)
          CalculationBanner(
            label: 'Personalizing macros…',
            completeLabel: 'Macros personalized',
            durationSeconds: 30,
            startTime: widget.data.macroCalculationStartTime,
            onComplete: () => widget.data.macroCalculationComplete = true,
          ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Pulsing icon
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) {
                final t = Curves.easeInOutSine.transform(_pulseCtrl.value);
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: OColors.primary
                        .withValues(alpha: 0.08 + t * 0.08),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: OColors.primary.withValues(alpha: 0.05 + t * 0.12),
                        blurRadius: 12 + t * 8,
                        spreadRadius: t * 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: OColors.primary,
                    size: 28,
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text(
              'Smart personalization',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Based on your region (${widget.data.region}), Intake will:',
              style: const TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Staggered bullet points
            ..._buildBullets(),

            const Spacer(),
            OnboardingContinueButton(
              onTap: () => Navigator.push(
                context,
                onboardingRoute(Screen13Consistency(data: widget.data)),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  static const _bullets = [
    'Recognize local dishes and ingredients',
    'Suggest culturally relevant meals',
    'Provide accurate nutrition data for regional foods',
    'Adapt food suggestions to your area',
  ];

  List<Widget> _buildBullets() {
    return List.generate(_bullets.length, (i) {
      return FadeTransition(
        opacity: _bulletFades[i],
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: OColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _bullets[i],
                  style: const TextStyle(
                    fontSize: 15,
                    color: OColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
