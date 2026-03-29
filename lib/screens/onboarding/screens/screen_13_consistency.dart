import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_14_reinforcement.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 13 — Consistency Screen
/// Immersive stat card + animated streak visualization.
class Screen13Consistency extends StatelessWidget {
  final OnboardingData data;
  const Screen13Consistency({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final stepNum = data.showIntensityScreen ? 13 : 12;
    return OnboardingScaffold(
      currentStep: stepNum,
      totalSteps: data.totalSteps,
      banners: [
        CalculationBanner(
          label: 'Calculating your BMI\u2026',
          completeLabel: 'BMI calculated',
          durationSeconds: 30,
          startTime: data.bmiCalculationStartTime,
          onComplete: () => data.bmiCalculationComplete = true,
        ),
        if (data.macroCalculationStartTime != null)
          CalculationBanner(
            label: 'Personalizing macros\u2026',
            completeLabel: 'Macros personalized',
            durationSeconds: 30,
            startTime: data.macroCalculationStartTime,
            onComplete: () => data.macroCalculationComplete = true,
          ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 36),

            const Text(
              'Consistency\nis everything.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Small daily actions compound into lasting change.',
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Big stat card — horizontal layout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              decoration: BoxDecoration(
                color: OColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: OColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '83%',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w800,
                      color: OColors.primary,
                      letterSpacing: -2,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'of daily trackers reach their goal within 3 months',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: OColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const _WeekStreak(),

            const Spacer(),
            OnboardingContinueButton(
              onTap: () => Navigator.push(
                context,
                onboardingRoute(Screen14Reinforcement(data: data)),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ── Animated week streak ──────────────────────────────────────────────────────

class _WeekStreak extends StatefulWidget {
  const _WeekStreak();

  @override
  State<_WeekStreak> createState() => _WeekStreakState();
}

class _WeekStreakState extends State<_WeekStreak>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _scaleAnims;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _active = [true, true, true, true, true, false, false];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnims = List.generate(7, (i) {
      final start = i * 0.08;
      final end = (start + 0.3).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR STREAK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: OColors.textTertiary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            return AnimatedBuilder(
              animation: _scaleAnims[i],
              builder: (_, _) => Transform.scale(
                scale: _scaleAnims[i].value,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _active[i] ? OColors.primary : OColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _active[i]
                              ? OColors.primary
                              : OColors.borderMedium,
                          width: 1.5,
                        ),
                        boxShadow: _active[i]
                            ? [
                                BoxShadow(
                                  color: OColors.primary.withValues(alpha: 0.22),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        _active[i] ? Icons.check_rounded : null,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _days[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _active[i]
                            ? OColors.textPrimary
                            : OColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
