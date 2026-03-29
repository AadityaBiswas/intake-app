import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_03_name.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 2 — Features Overview
/// Staggered fade+slide reveal for each feature item.
class Screen02Features extends StatefulWidget {
  final OnboardingData data;
  const Screen02Features({super.key, required this.data});

  @override
  State<Screen02Features> createState() => _Screen02FeaturesState();
}

class _Screen02FeaturesState extends State<Screen02Features>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const _features = [
    {
      'icon': Icons.bolt_rounded,
      'title': 'Quick Food Logging',
      'desc': 'Log meals instantly — search, scan, or describe.',
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': 'Macro Insights',
      'desc': 'Personalized protein, carb, and fat targets.',
    },
    {
      'icon': Icons.track_changes_rounded,
      'title': 'Goal-Driven Plans',
      'desc': 'Custom plans for weight loss, gain, or maintenance.',
    },
    {
      'icon': Icons.public_rounded,
      'title': 'Region-Aware',
      'desc': 'Localized food tracking based on your region.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnims = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _ctrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(4, (i) {
      final start = i * 0.15;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
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
    return OnboardingScaffold(
      currentStep: 2,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'What you get',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Everything you need to reach your fitness goals.',
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ...List.generate(_features.length, (i) {
              final f = _features[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FadeTransition(
                  opacity: _fadeAnims[i],
                  child: SlideTransition(
                    position: _slideAnims[i],
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: OColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            f['icon'] as IconData,
                            color: OColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                f['title'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: OColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                f['desc'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: OColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            OnboardingContinueButton(
              onTap: () => Navigator.push(
                context,
                onboardingRoute(Screen03Name(data: widget.data)),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
