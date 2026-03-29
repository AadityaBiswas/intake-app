import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_15_goal_confirm.dart';
import '../../../services/macro_calculator.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 14 — Reinforcement / Motivational commitment screen
/// Breathing ripple rings animation on the trophy icon.
/// Staggered card reveals + macro-gated "See My Plan" button.
class Screen14Reinforcement extends StatefulWidget {
  final OnboardingData data;
  const Screen14Reinforcement({super.key, required this.data});

  @override
  State<Screen14Reinforcement> createState() => _Screen14ReinforcementState();
}

class _Screen14ReinforcementState extends State<Screen14Reinforcement>
    with TickerProviderStateMixin {
  bool _macroComplete = false;
  late AnimationController _rippleCtrl;
  late AnimationController _contentCtrl;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();
    _macroComplete = widget.data.macroCalculationComplete;

    if (widget.data.macroCalculationStartTime == null) {
      if (widget.data.goalIntensity.isEmpty) {
        widget.data.goalIntensity = 'Moderate';
      }
      widget.data.macroCalculationStartTime = DateTime.now();
      widget.data.macroCalculationStarted = true;
    }

    // Ripple rings — repeating
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // Cards staggered reveal
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _cardFades = List.generate(3, (i) {
      final start = 0.3 + i * 0.15;
      final end = (start + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _contentCtrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _cardSlides = List.generate(3, (i) {
      final start = 0.3 + i * 0.15;
      final end = (start + 0.3).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _contentCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    });

    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _onMacroComplete() {
    _computeMacros();
    widget.data.macroCalculationComplete = true;
    setState(() => _macroComplete = true);
  }

  void _computeMacros() {
    final result = MacroCalculator.calculate(
      gender: widget.data.gender,
      age: widget.data.age,
      weightKg: widget.data.weight,
      heightCm: widget.data.height,
      activityLevel: widget.data.activityLevel,
      weightGoal: widget.data.primaryGoal,
      goalIntensity: widget.data.goalIntensity,
    );

    widget.data.targetCalories = result.targetCalories;
    widget.data.proteinGrams = result.proteinGrams;
    widget.data.carbGrams = result.carbGrams;
    widget.data.fatGrams = result.fatGrams;
    widget.data.bmr = result.bmr;
    widget.data.maintenanceCalories = result.maintenance;
    widget.data.calorieAdjustment = result.calorieAdjustment;
    widget.data.activityMultiplier = result.activityMultiplier;

    if (widget.data.primaryGoal != 'Maintenance' &&
        widget.data.targetWeight > 0) {
      widget.data.estimatedDaysToGoal = MacroCalculator.estimateDaysWithTarget(
        currentKg: widget.data.weight,
        targetKg: widget.data.targetWeight,
        goal: widget.data.primaryGoal,
        intensity: widget.data.goalIntensity,
      );
    }
  }

  void _next() {
    if (!_macroComplete) {
      // Force finish computation
      _computeMacros();
      widget.data.macroCalculationComplete = true;
    }
    Navigator.push(
      context,
      onboardingRoute(Screen15GoalConfirm(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic step number based on whether intensity screen was shown
    final stepNum = widget.data.showIntensityScreen ? 14 : 13;

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
        CalculationBanner(
          label: 'Personalizing macros…',
          completeLabel: 'Macros personalized',
          durationSeconds: 30,
          startTime: widget.data.macroCalculationStartTime,
          onComplete: _onMacroComplete,
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 36),

            // Ripple icon
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(2, (i) {
                    final delay = i * 0.4;
                    return AnimatedBuilder(
                      animation: _rippleCtrl,
                      builder: (_, _) {
                        final rawT = (_rippleCtrl.value - delay) % 1.0;
                        final t = rawT < 0 ? rawT + 1.0 : rawT;
                        final eased = Curves.easeOut.transform(t);
                        return Opacity(
                          opacity: (1.0 - eased) * 0.25,
                          child: Transform.scale(
                            scale: 0.5 + eased * 0.9,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: OColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: OColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: OColors.primary,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              "You're committed,\n${widget.data.firstName}!",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Every journey begins with a single step.\nYou've just taken yours.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Staggered commitment cards
            ...List.generate(3, (i) {
              const cards = [
                (Icons.track_changes_rounded, 'Personalized Plan', 'Tailored to your goals and body'),
                (Icons.restaurant_rounded, 'Quick Food Logging', 'Fast, effortless meal tracking'),
                (Icons.insights_rounded, 'Daily Insights', 'Know exactly what you need'),
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeTransition(
                  opacity: _cardFades[i],
                  child: SlideTransition(
                    position: _cardSlides[i],
                    child: _CommitmentCard(
                      icon: cards[i].$1,
                      title: cards[i].$2,
                      subtitle: cards[i].$3,
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),
            // Gated button: disabled until macro calculation completes
            OnboardingContinueButton(
              onTap: _next,
              label: 'See My Plan',
              enabled: _macroComplete,
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _CommitmentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CommitmentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: OColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: OColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: OColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: OColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: OColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: OColors.primary,
            size: 22,
          ),
        ],
      ),
    );
  }
}
