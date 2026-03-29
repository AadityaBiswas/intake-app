import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding_data.dart';
import 'screen_11_region.dart';
import '../../../services/macro_calculator.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 10 — Goal Intensity (conditional)
/// Only shown when fitness experience != "Just started".
/// Macro calculation timer starts when user taps Continue (not on card tap).
/// Intensity cards have distinct colour codes: green / amber / red.
class Screen10Intensity extends StatefulWidget {
  final OnboardingData data;
  const Screen10Intensity({super.key, required this.data});

  @override
  State<Screen10Intensity> createState() => _Screen10IntensityState();
}

class _Screen10IntensityState extends State<Screen10Intensity> {
  String? _selected;

  static const _mildColor = Color(0xFF22C55E);
  static const _moderateColor = Color(0xFFF59E0B);
  static const _aggressiveColor = Color(0xFFEF4444);

  Color _colorFor(String label) {
    switch (label) {
      case 'Mild':
        return _mildColor;
      case 'Moderate':
        return _moderateColor;
      case 'Aggressive':
        return _aggressiveColor;
      default:
        return OColors.primary;
    }
  }

  List<_IntensityOption> get _options {
    final isLoss = widget.data.primaryGoal == 'Weight Loss';
    if (isLoss) {
      return const [
        _IntensityOption(
          label: 'Mild',
          pace: '~0.25 kg / week',
          tagline: 'Sustainable & easy',
          icon: Icons.directions_walk_rounded,
        ),
        _IntensityOption(
          label: 'Moderate',
          pace: '~0.5 kg / week',
          tagline: 'Balanced pace',
          icon: Icons.directions_run_rounded,
        ),
        _IntensityOption(
          label: 'Aggressive',
          pace: '~0.75 kg / week',
          tagline: 'Faster, stricter diet',
          icon: Icons.bolt_rounded,
        ),
      ];
    } else {
      return const [
        _IntensityOption(
          label: 'Mild',
          pace: '~0.25 kg / week',
          tagline: 'Lean, quality gains',
          icon: Icons.directions_walk_rounded,
        ),
        _IntensityOption(
          label: 'Moderate',
          pace: '~0.5 kg / week',
          tagline: 'Balanced surplus',
          icon: Icons.directions_run_rounded,
        ),
        _IntensityOption(
          label: 'Aggressive',
          pace: '~0.75 kg / week',
          tagline: 'Maximum caloric surplus',
          icon: Icons.bolt_rounded,
        ),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.data.goalIntensity.isNotEmpty) {
      _selected = widget.data.goalIntensity;
    }
  }

  void _computeMacros() {
    final intensity = _selected ?? widget.data.goalIntensity;
    final result = MacroCalculator.calculate(
      gender: widget.data.gender,
      age: widget.data.age,
      weightKg: widget.data.weight,
      heightCm: widget.data.height,
      activityLevel: widget.data.activityLevel,
      weightGoal: widget.data.primaryGoal,
      goalIntensity: intensity,
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
        intensity: intensity,
      );
    }
  }

  int? _getEstimatedDays() {
    if (_selected == null) return null;
    if (widget.data.primaryGoal == 'Maintenance') return null;
    if (widget.data.targetWeight <= 0) return null;
    return MacroCalculator.estimateDaysWithTarget(
      currentKg: widget.data.weight,
      targetKg: widget.data.targetWeight,
      goal: widget.data.primaryGoal,
      intensity: _selected!,
    );
  }

  void _next() {
    if (_selected == null) return;
    widget.data.goalIntensity = _selected!;

    // Start macro timer on Continue tap
    if (widget.data.macroCalculationStartTime == null) {
      widget.data.macroCalculationStartTime = DateTime.now();
      widget.data.macroCalculationStarted = true;
    }

    // Compute macros immediately so downstream screens have values
    _computeMacros();
    widget.data.macroCalculationComplete = true;

    Navigator.push(
      context,
      onboardingRoute(Screen11Region(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimatedDays = _getEstimatedDays();

    return OnboardingScaffold(
      currentStep: 10,
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
            const SizedBox(height: 24),
            const Text(
              'Goal intensity',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'How aggressively would you like to progress?',
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            ..._options.map((opt) {
              final isSelected = _selected == opt.label;
              final accent = _colorFor(opt.label);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _IntensityCard(
                  option: opt,
                  isSelected: isSelected,
                  accent: accent,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = opt.label);
                  },
                ),
              );
            }),

            if (estimatedDays != null) ...[
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: OColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: OColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: OColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated timeline',
                            style: TextStyle(
                              fontSize: 12,
                              color: OColors.textSecondary,
                            ),
                          ),
                          Text(
                            '~$estimatedDays days to reach ${widget.data.displayWeight(widget.data.targetWeight)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: OColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),
            OnboardingContinueButton(onTap: _next, enabled: _selected != null),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _IntensityOption {
  final String label;
  final String pace;
  final String tagline;
  final IconData icon;

  const _IntensityOption({
    required this.label,
    required this.pace,
    required this.tagline,
    required this.icon,
  });
}

class _IntensityCard extends StatelessWidget {
  final _IntensityOption option;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _IntensityCard({
    required this.option,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.06) : OColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accent : OColors.borderMedium,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.15)
                    : OColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                option.icon,
                size: 24,
                color: isSelected ? accent : OColors.textTertiary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.pace,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accent : OColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    option.tagline,
                    style: const TextStyle(
                      fontSize: 12,
                      color: OColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Icon(Icons.check_circle_rounded, color: accent, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
