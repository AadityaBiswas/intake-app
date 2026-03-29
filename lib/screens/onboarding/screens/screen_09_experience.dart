import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_10_intensity.dart';
import 'screen_11_region.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 9 — Fitness Experience
/// Routes to Screen 10 (intensity) unless "Just started".
class Screen09Experience extends StatefulWidget {
  final OnboardingData data;
  const Screen09Experience({super.key, required this.data});

  @override
  State<Screen09Experience> createState() => _Screen09ExperienceState();
}

class _Screen09ExperienceState extends State<Screen09Experience> {
  String? _selected;

  static const _options = [
    {'label': 'Just started', 'icon': Icons.emoji_nature_rounded},
    {'label': 'A few months', 'icon': Icons.directions_walk_rounded},
    {'label': 'A year', 'icon': Icons.directions_run_rounded},
    {'label': 'Many years', 'icon': Icons.military_tech_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.fitnessExperience.isNotEmpty) {
      _selected = widget.data.fitnessExperience;
    }
  }

  void _next() {
    if (_selected == null) return;
    widget.data.fitnessExperience = _selected!;

    // Conditional routing
    final nextScreen = _selected == 'Just started'
        ? Screen11Region(data: widget.data)
        : Screen10Intensity(data: widget.data);

    Navigator.push(context, onboardingRoute(nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 9,
      totalSteps: widget.data.totalSteps,
      banners: [
        CalculationBanner(
          label: 'Calculating your BMI…',
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
              'Fitness experience',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How long have you been into fitness?',
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ..._options.map((opt) {
              final label = opt['label'] as String;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SelectionCard(
                  label: label,
                  icon: opt['icon'] as IconData,
                  isSelected: _selected == label,
                  onTap: () => setState(() => _selected = label),
                ),
              );
            }),
            const Spacer(),
            OnboardingContinueButton(onTap: _next, enabled: _selected != null),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
