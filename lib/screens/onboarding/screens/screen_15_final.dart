import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../onboarding_data.dart';
import '../../home_screen.dart';
import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 15 — Final Screen: display calculated macros, then go Home.
/// Phase 1 stub: calculates BMI inline and shows placeholder macros.
/// Phase 2 will wire the real async calculation engine.
class Screen15Final extends StatefulWidget {
  final OnboardingData data;
  const Screen15Final({super.key, required this.data});

  @override
  State<Screen15Final> createState() => _Screen15FinalState();
}

class _Screen15FinalState extends State<Screen15Final> {
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Compute BMI inline for Phase 1
    final h = widget.data.height / 100;
    widget.data.bmi = widget.data.weight / (h * h);

    // Placeholder macro values (Phase 2 will use real calculation engine)
    widget.data.targetCalories ??= 2000;
    widget.data.proteinGrams ??= 150;
    widget.data.carbGrams ??= 220;
    widget.data.fatGrams ??= 65;
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
      );
      await UserService.saveUserProfile(profile);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        onboardingRoute(const HomeScreen()),
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
    return OnboardingScaffold(
      currentStep: 15,
      showBackButton: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const SizedBox(height: 40),
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
            Text(
              'Based on your profile, here are your daily targets:',
              style: const TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Macro cards grid
            Row(
              children: [
                _MacroTile(
                  label: 'Calories',
                  value: '${widget.data.targetCalories}',
                  unit: 'kcal',
                  color: OColors.primary,
                ),
                const SizedBox(width: 12),
                _MacroTile(
                  label: 'Protein',
                  value: '${widget.data.proteinGrams}',
                  unit: 'g',
                  color: const Color(0xFF3B82F6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MacroTile(
                  label: 'Carbs',
                  value: '${widget.data.carbGrams}',
                  unit: 'g',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                _MacroTile(
                  label: 'Fats',
                  value: '${widget.data.fatGrams}',
                  unit: 'g',
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),

            const SizedBox(height: 24),
            // BMI card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                          fontSize: 13,
                          color: OColors.textSecondary,
                        ),
                      ),
                      Text(
                        widget.data.bmi!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: OColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: OColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _bmiCategory(widget.data.bmi!),
                      style: const TextStyle(
                        fontSize: 13,
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
              onTap: _finish,
              label: "Let's Go!",
              isLoading: _isSaving,
            ),
            const SizedBox(height: 28),
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
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: OColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 13,
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
