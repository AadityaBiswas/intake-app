import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_07_goal.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 6 — Activity Level (uses existing option structure)
class Screen06Activity extends StatefulWidget {
  final OnboardingData data;
  const Screen06Activity({super.key, required this.data});

  @override
  State<Screen06Activity> createState() => _Screen06ActivityState();
}

class _Screen06ActivityState extends State<Screen06Activity> {
  String? _selected;

  static const _levels = [
    {
      'label': 'Sedentary',
      'desc': 'Little or no exercise',
      'icon': Icons.weekend_rounded,
    },
    {
      'label': 'Lightly Active',
      'desc': 'Light exercise 1–3 days/week',
      'icon': Icons.directions_walk_rounded,
    },
    {
      'label': 'Moderately Active',
      'desc': 'Moderate exercise 3–5 days/week',
      'icon': Icons.directions_run_rounded,
    },
    {
      'label': 'Very Active',
      'desc': 'Hard exercise 6–7 days/week',
      'icon': Icons.fitness_center_rounded,
    },
    {
      'label': 'Athlete',
      'desc': 'Intense training, twice per day',
      'icon': Icons.sports_gymnastics_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.activityLevel.isNotEmpty) {
      _selected = widget.data.activityLevel;
    }
  }

  void _next() {
    if (_selected == null) return;
    widget.data.activityLevel = _selected!;
    // Start BMI timer now that we have enough data (height, weight, activity)
    if (widget.data.bmiCalculationStartTime == null) {
      widget.data.bmiCalculationStartTime = DateTime.now();
      widget.data.bmiCalculationStarted = true;
    }
    Navigator.push(context, onboardingRoute(Screen07Goal(data: widget.data)));
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 6,
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
              'Activity level',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How active are you on a typical week?',
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _levels.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final level = _levels[i];
                  final label = level['label'] as String;
                  return SelectionCard(
                    label: label,
                    description: level['desc'] as String,
                    icon: level['icon'] as IconData,
                    isSelected: _selected == label,
                    onTap: () => setState(() => _selected = label),
                  );
                },
              ),
            ),
            OnboardingContinueButton(onTap: _next, enabled: _selected != null),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
