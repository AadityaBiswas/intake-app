import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding_data.dart';
import 'screen_08_desired_weight.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 7 — Primary Goal
/// Large immersive goal cards with BMI-aware soft warning when the
/// selected goal may conflict with the user's current BMI.
class Screen07Goal extends StatefulWidget {
  final OnboardingData data;
  const Screen07Goal({super.key, required this.data});

  @override
  State<Screen07Goal> createState() => _Screen07GoalState();
}

class _Screen07GoalState extends State<Screen07Goal> {
  String? _selected;

  static const _goals = [
    _GoalOption(
      label: 'Weight Loss',
      tagline: 'Burn fat, feel lighter',
      desc: 'Caloric deficit calibrated to your pace',
      icon: Icons.trending_down_rounded,
      accentColor: Color(0xFF22C55E),
    ),
    _GoalOption(
      label: 'Maintenance',
      tagline: 'Stay where you are',
      desc: 'Balance intake to keep your weight steady',
      icon: Icons.horizontal_rule_rounded,
      accentColor: Color(0xFF3B82F6),
    ),
    _GoalOption(
      label: 'Weight Gain',
      tagline: 'Build mass, gain strength',
      desc: 'Caloric surplus to fuel healthy growth',
      icon: Icons.trending_up_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.primaryGoal.isNotEmpty) {
      _selected = widget.data.primaryGoal;
    }
  }

  /// Returns a soft warning message when the chosen goal may conflict
  /// with the user's current BMI. Returns null when no conflict.
  String? _bmiWarning(String? goal, double? bmi) {
    if (goal == null || bmi == null) return null;
    if (goal == 'Weight Loss' && bmi < 18.5) {
      return 'Your BMI (${ bmi.toStringAsFixed(1)}) is already below the healthy range. '
          'Weight loss may not be recommended — but you can still choose this if you feel it suits you.';
    }
    if (goal == 'Weight Gain' && bmi >= 25.0) {
      return 'Your BMI (${bmi.toStringAsFixed(1)}) is above the healthy range. '
          'Weight gain may not be recommended — but you can still choose this if you feel it suits you.';
    }
    return null;
  }

  void _next() {
    if (_selected == null) return;
    widget.data.primaryGoal = _selected!;
    Navigator.push(
      context,
      onboardingRoute(Screen08DesiredWeight(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warning = _bmiWarning(_selected, widget.data.bmi);

    return OnboardingScaffold(
      currentStep: 7,
      totalSteps: widget.data.totalSteps,
      banners: [
        CalculationBanner(
          label: 'Calculating your BMI\u2026',
          completeLabel: 'BMI calculated',
          durationSeconds: 30,
          startTime: widget.data.bmiCalculationStartTime,
          onComplete: () => widget.data.bmiCalculationComplete = true,
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              "What's your\ngoal?",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll build your daily targets around this.",
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            ..._goals.map((goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GoalCard(
                    option: goal,
                    isSelected: _selected == goal.label,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = goal.label);
                    },
                  ),
                )),

            // BMI conflict warning — soft, dismissible
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: warning != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                warning,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF92400E),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const Spacer(),
            OnboardingContinueButton(onTap: _next, enabled: _selected != null),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _GoalOption {
  final String label;
  final String tagline;
  final String desc;
  final IconData icon;
  final Color accentColor;

  const _GoalOption({
    required this.label,
    required this.tagline,
    required this.desc,
    required this.icon,
    required this.accentColor,
  });
}

// ── Goal card ─────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final _GoalOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? option.accentColor.withValues(alpha: 0.06)
              : OColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? option.accentColor : OColors.borderMedium,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.accentColor.withValues(alpha: 0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? option.accentColor.withValues(alpha: 0.14)
                    : OColors.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                option.icon,
                size: 26,
                color: isSelected ? option.accentColor : OColors.textTertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? OColors.textPrimary
                          : const Color(0xFF334155),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.tagline,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? option.accentColor
                          : OColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: OColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Icon(
                Icons.check_circle_rounded,
                color: option.accentColor,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
