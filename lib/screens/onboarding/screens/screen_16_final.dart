import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../onboarding_data.dart';
import 'screen_17_all_set.dart';
import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 16 — Final Plan Reveal
/// Shows maintenance cal → adjustment → final target, macro breakdown,
/// detailed calculation expandable, and AI validation before saving.
class Screen16Final extends StatefulWidget {
  final OnboardingData data;
  const Screen16Final({super.key, required this.data});

  @override
  State<Screen16Final> createState() => _Screen16FinalState();
}

class _Screen16FinalState extends State<Screen16Final> {
  bool _isSaving = false;
  bool _showDetails = false;
  String? _sanityNote;

  @override
  void initState() {
    super.initState();
    // Ensure BMI is computed
    if (widget.data.bmi == null) {
      final h = widget.data.height / 100;
      widget.data.bmi = widget.data.weight / (h * h);
    }
    // Run local sanity checks immediately — no async, no spinner
    _localSanityCheck();
  }

  void _localSanityCheck() {
    final cal = widget.data.targetCalories ?? 2000;
    if (cal < 1200) {
      widget.data.targetCalories = 1200;
      _sanityNote = 'Adjusted to safe minimum (1200 kcal).';
    } else if (cal > 4500) {
      widget.data.targetCalories = 4500;
      _sanityNote = 'Capped at 4500 kcal for safety.';
    }
    final maxProtein = (widget.data.weight * 3).round();
    if ((widget.data.proteinGrams ?? 0) > maxProtein) {
      widget.data.proteinGrams = maxProtein;
      _sanityNote = 'Protein adjusted to ${maxProtein}g (safe ceiling).';
    }
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.updateDisplayName(widget.data.name);

      final profile = UserProfile(
        uid: user.uid,
        name: widget.data.name,
        gender: widget.data.gender,
        age: widget.data.age,
        weight: widget.data.weight,
        height: widget.data.height,
        activityLevel: widget.data.activityLevel,
        bmi: widget.data.bmi!,
        weightGoal: widget.data.primaryGoal,
        goalIntensity: widget.data.goalIntensity,
        targetWeight: widget.data.targetWeight,
        region: widget.data.region,
        goalProtein: widget.data.proteinGrams ?? 0,
        goalCarbs: widget.data.carbGrams ?? 0,
        goalFat: widget.data.fatGrams ?? 0,
        goalCalories: widget.data.targetCalories ?? 0,
      );
      await UserService.saveUserProfile(profile);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        onboardingRoute(Screen17AllSet(data: widget.data)),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: OColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepNum = widget.data.totalSteps;
    final maintenance = widget.data.maintenanceCalories?.round() ?? 0;
    final adjustment = widget.data.calorieAdjustment?.round() ?? 0;
    final target = widget.data.targetCalories ?? 0;
    final isDeficit = adjustment < 0;
    final isSurplus = adjustment > 0;

    return OnboardingScaffold(
      currentStep: stepNum,
      totalSteps: stepNum,
      showBackButton: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            const Text(
              'Your personalized plan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Based on your profile, here are your daily targets:',
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // ── Calorie breakdown card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
                  // Maintenance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Maintenance',
                        style: TextStyle(
                          fontSize: 14,
                          color: OColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$maintenance kcal',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Adjustment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDeficit
                            ? 'Deficit'
                            : (isSurplus ? 'Surplus' : 'No change'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: OColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${adjustment >= 0 ? '+' : ''}$adjustment kcal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDeficit
                              ? OColors.fatColor
                              : (isSurplus
                                    ? OColors.primary
                                    : OColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: OColors.border),
                  ),
                  // Target
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily Target',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: OColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$target kcal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: OColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Macro cards grid ──
            Row(
              children: [
                _MacroTile(
                  label: 'Protein',
                  value: '${widget.data.proteinGrams}',
                  unit: 'g',
                  color: OColors.proteinColor,
                ),
                const SizedBox(width: 10),
                _MacroTile(
                  label: 'Carbs',
                  value: '${widget.data.carbGrams}',
                  unit: 'g',
                  color: OColors.carbColor,
                ),
                const SizedBox(width: 10),
                _MacroTile(
                  label: 'Fats',
                  value: '${widget.data.fatGrams}',
                  unit: 'g',
                  color: OColors.fatColor,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── BMI card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: OColors.border),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your BMI',
                        style: TextStyle(
                          fontSize: 12,
                          color: OColors.textSecondary,
                        ),
                      ),
                      Text(
                        widget.data.bmi!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: OColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: OColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _bmiCategory(widget.data.bmi!),
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

            const SizedBox(height: 12),

            // ── Sanity note (only shown when an adjustment was made) ──
            if (_sanityNote != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: OColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: OColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _sanityNote!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: OColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── Detailed calculation (expandable) ──
            GestureDetector(
              onTap: () => setState(() => _showDetails = !_showDetails),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: OColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OColors.borderMedium),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calculate_rounded,
                      color: OColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Detailed Calculation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: OColors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _showDetails ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: OColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _showDetails
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: OColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(
                            'BMR (Mifflin-St Jeor)',
                            '${widget.data.bmr?.round() ?? '—'} kcal',
                          ),
                          _DetailRow(
                            'Activity Multiplier',
                            'x${widget.data.activityMultiplier?.toStringAsFixed(2) ?? '—'}',
                          ),
                          _DetailRow(
                            'Maintenance Calories',
                            '$maintenance kcal',
                          ),
                          _DetailRow(
                            'Goal Adjustment',
                            '${adjustment >= 0 ? '+' : ''}$adjustment kcal',
                          ),
                          const Divider(height: 16, color: OColors.border),
                          _DetailRow(
                            'Target Calories',
                            '$target kcal',
                            isBold: true,
                          ),
                          const SizedBox(height: 8),
                          _DetailRow(
                            'Protein',
                            '${widget.data.proteinGrams}g × 4 = ${(widget.data.proteinGrams ?? 0) * 4} kcal',
                          ),
                          _DetailRow(
                            'Fats',
                            '${widget.data.fatGrams}g × 9 = ${(widget.data.fatGrams ?? 0) * 9} kcal',
                          ),
                          _DetailRow(
                            'Carbs',
                            '${widget.data.carbGrams}g × 4 = ${(widget.data.carbGrams ?? 0) * 4} kcal',
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),
            OnboardingContinueButton(
              onTap: _finish,
              label: "Let's Go!",
              isLoading: _isSaving,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MacroTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: OColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: OColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: OColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? OColors.textPrimary : OColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? OColors.primary : OColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
