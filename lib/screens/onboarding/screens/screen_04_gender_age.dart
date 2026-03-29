import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding_data.dart';
import 'screen_05_height_weight.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 4 — Gender AND Age Selection
/// Premium design: pill-style gender selector, large age display with +/- steppers.
class Screen04GenderAge extends StatefulWidget {
  final OnboardingData data;
  const Screen04GenderAge({super.key, required this.data});

  @override
  State<Screen04GenderAge> createState() => _Screen04GenderAgeState();
}

class _Screen04GenderAgeState extends State<Screen04GenderAge> {
  String? _selectedGender;
  int _selectedAge = 25;

  static const _minAge = 10;
  static const _maxAge = 100;

  static const _genderOptions = [
    {'label': 'Male', 'icon': Icons.male_rounded},
    {'label': 'Female', 'icon': Icons.female_rounded},
    {'label': 'Other', 'icon': Icons.transgender_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.gender.isNotEmpty) _selectedGender = widget.data.gender;
    _selectedAge = widget.data.age > 0 ? widget.data.age : 25;
  }

  bool get _isValid =>
      _selectedGender != null &&
      _selectedAge >= _minAge &&
      _selectedAge <= _maxAge;

  void _stepAge(int delta) {
    final next = _selectedAge + delta;
    if (next >= _minAge && next <= _maxAge) {
      HapticFeedback.selectionClick();
      setState(() => _selectedAge = next);
    }
  }

  void _next() {
    if (!_isValid) return;
    widget.data.gender = _selectedGender!;
    widget.data.age = _selectedAge;
    Navigator.push(
      context,
      onboardingRoute(Screen05HeightWeight(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 4,
      totalSteps: widget.data.totalSteps,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About you',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: OColors.textPrimary,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This helps us personalize your nutrition plan.',
                    style: TextStyle(
                      fontSize: 15,
                      color: OColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Section label ──
                  const _SectionLabel('BIOLOGICAL SEX'),
                  const SizedBox(height: 12),

                  // ── Gender selector ──
                  Row(
                    children: _genderOptions.map((opt) {
                      final label = opt['label'] as String;
                      final icon = opt['icon'] as IconData;
                      final isSelected = _selectedGender == label;
                      final isLast = label == 'Other';
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: isLast ? 0 : 10),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedGender = label);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? OColors.primary
                                    : OColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? OColors.primary
                                      : OColors.borderMedium,
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: OColors.primary.withValues(
                                            alpha: 0.22,
                                          ),
                                          blurRadius: 16,
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
                              child: Column(
                                children: [
                                  Icon(
                                    icon,
                                    size: 26,
                                    color: isSelected
                                        ? Colors.white
                                        : OColors.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : OColors.textSecondary,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // ── Age section ──
                  const _SectionLabel('AGE'),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: OColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: OColors.borderMedium, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Decrease
                        _AgeStepButton(
                          icon: Icons.remove_rounded,
                          onTap: () => _stepAge(-1),
                          enabled: _selectedAge > _minAge,
                        ),

                        // Age display
                        Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(
                                    scale: Tween(begin: 0.85, end: 1.0)
                                        .animate(CurvedAnimation(
                                          parent: anim,
                                          curve: Curves.easeOutBack,
                                        )),
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                              child: Text(
                                '$_selectedAge',
                                key: ValueKey(_selectedAge),
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w800,
                                  color: OColors.primary,
                                  letterSpacing: -2,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'years old',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: OColors.textTertiary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),

                        // Increase
                        _AgeStepButton(
                          icon: Icons.add_rounded,
                          onTap: () => _stepAge(1),
                          enabled: _selectedAge < _maxAge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: OnboardingContinueButton(onTap: _next, enabled: _isValid),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: OColors.textTertiary,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _AgeStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _AgeStepButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? OColors.primaryLight : OColors.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? OColors.primary.withValues(alpha: 0.25) : OColors.borderMedium,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: enabled ? OColors.primary : OColors.textTertiary,
        ),
      ),
    );
  }
}
