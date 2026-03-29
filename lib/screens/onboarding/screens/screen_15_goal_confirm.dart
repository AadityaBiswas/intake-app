import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_16_final.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 15 — Goal Confirmation (psychological commitment moment)
/// Shows a summary of the user's selected goal, current weight, target weight,
/// estimated timeline, and daily calories BEFORE revealing the full plan.
/// This increases commitment and retention.
class Screen15GoalConfirm extends StatelessWidget {
  final OnboardingData data;
  const Screen15GoalConfirm({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final stepNum = data.showIntensityScreen ? 15 : 14;

    return OnboardingScaffold(
      currentStep: stepNum,
      totalSteps: data.totalSteps,
      showBackButton: true,
      banners: [
        CalculationBanner(
          label: 'Calculating your BMI…',
          completeLabel: 'BMI calculated',
          durationSeconds: 30,
          startTime: data.bmiCalculationStartTime,
          onComplete: () => data.bmiCalculationComplete = true,
        ),
        CalculationBanner(
          label: 'Personalizing macros…',
          completeLabel: 'Macros personalized',
          durationSeconds: 30,
          startTime: data.macroCalculationStartTime,
          onComplete: () => data.macroCalculationComplete = true,
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),

            // Trophy icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: OColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: OColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Goal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Here's what we've built for you, ${data.firstName}.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // ── Goal summary card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: OColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: OColors.borderMedium),
                boxShadow: [
                  BoxShadow(
                    color: OColors.textPrimary.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InfoRow(
                    label: 'Current Weight',
                    value: data.displayWeight(data.weight),
                  ),
                  const Divider(height: 1, color: OColors.border),
                  if (data.primaryGoal != 'Maintenance') ...[
                    InfoRow(
                      label: 'Target Weight',
                      value: data.displayWeight(data.targetWeight),
                      valueColor: OColors.primary,
                    ),
                    const Divider(height: 1, color: OColors.border),
                  ],
                  InfoRow(label: 'Goal', value: data.primaryGoal),
                  if (data.goalIntensity.isNotEmpty) ...[
                    const Divider(height: 1, color: OColors.border),
                    InfoRow(label: 'Intensity', value: data.goalIntensity),
                  ],
                  if (data.estimatedDaysToGoal != null &&
                      data.primaryGoal != 'Maintenance') ...[
                    const Divider(height: 1, color: OColors.border),
                    InfoRow(
                      label: 'Estimated Time',
                      value: _formatDays(data.estimatedDaysToGoal!),
                      valueColor: OColors.primary,
                    ),
                  ],
                  const Divider(height: 1, color: OColors.border),
                  InfoRow(
                    label: 'Daily Calories',
                    value: '${data.targetCalories ?? '—'} kcal',
                    valueColor: OColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BMI badge
            if (data.bmi != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: OColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'BMI: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: OColors.textSecondary,
                      ),
                    ),
                    Text(
                      data.bmi!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: OColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: OColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _bmiCategory(data.bmi!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: OColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),
            OnboardingContinueButton(
              onTap: () => Navigator.push(
                context,
                onboardingRoute(Screen16Final(data: data)),
              ),
              label: 'See My Plan',
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  String _formatDays(int days) {
    if (days < 30) return '$days days';
    final months = (days / 30).round();
    if (months == 1) return '~1 month';
    return '~$months months';
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}
