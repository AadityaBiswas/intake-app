import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../onboarding_data.dart';
import 'screen_12_educational.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 11 — Home Region Selection
/// 2-column grid with monochrome icon logos (no emoji).
class Screen11Region extends StatefulWidget {
  final OnboardingData data;
  const Screen11Region({super.key, required this.data});

  @override
  State<Screen11Region> createState() => _Screen11RegionState();
}

class _Screen11RegionState extends State<Screen11Region> {
  String? _selected;

  static const _regions = [
    _Region('South Asia', Icons.temple_hindu_rounded),
    _Region('East Asia', Icons.temple_buddhist_rounded),
    _Region('Middle East', Icons.mosque_rounded),
    _Region('Europe', Icons.account_balance_rounded),
    _Region('North America', Icons.location_city_rounded),
    _Region('South America', Icons.forest_rounded),
    _Region('Africa', Icons.wb_sunny_rounded),
    _Region('Oceania', Icons.waves_rounded),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.region.isNotEmpty) _selected = widget.data.region;
  }

  void _next() {
    if (_selected == null) return;
    widget.data.region = _selected!;
    Navigator.push(
      context,
      onboardingRoute(Screen12Educational(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepNum = widget.data.showIntensityScreen ? 11 : 10;
    return OnboardingScaffold(
      currentStep: stepNum,
      totalSteps: widget.data.totalSteps,
      banners: [
        CalculationBanner(
          label: 'Calculating your BMI\u2026',
          completeLabel: 'BMI calculated',
          durationSeconds: 30,
          startTime: widget.data.bmiCalculationStartTime,
          onComplete: () => widget.data.bmiCalculationComplete = true,
        ),
        if (widget.data.macroCalculationStartTime != null)
          CalculationBanner(
            label: 'Personalizing macros\u2026',
            completeLabel: 'Macros personalized',
            durationSeconds: 30,
            startTime: widget.data.macroCalculationStartTime,
            onComplete: () => widget.data.macroCalculationComplete = true,
          ),
      ],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text(
              'Your region',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: OColors.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Helps us suggest foods familiar to your cuisine.',
              style: TextStyle(
                fontSize: 15,
                color: OColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                itemCount: _regions.length,
                itemBuilder: (context, i) {
                  final region = _regions[i];
                  final isSelected = _selected == region.label;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = region.label);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? OColors.textPrimary
                            : OColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? OColors.textPrimary
                              : OColors.borderMedium,
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: OColors.textPrimary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            region.icon,
                            size: 28,
                            color: isSelected
                                ? Colors.white
                                : OColors.textPrimary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            region.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : OColors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            OnboardingContinueButton(onTap: _next, enabled: _selected != null),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _Region {
  final String label;
  final IconData icon;
  const _Region(this.label, this.icon);
}
