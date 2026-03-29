import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import 'screen_02_features.dart';
import '../../../widgets/onboarding_widgets.dart';
import '../../../widgets/onboarding_page_route.dart';

/// Screen 1 — Onboarding Introduction
/// Clean, minimal entry screen — no logo, no orb.
class Screen01Intro extends StatefulWidget {
  final OnboardingData data;
  const Screen01Intro({super.key, required this.data});

  @override
  State<Screen01Intro> createState() => _Screen01IntroState();
}

class _Screen01IntroState extends State<Screen01Intro>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return OnboardingScaffold(
      currentStep: 1,
      showBackButton: false,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenH * 0.08),

                const Text(
                  'Your personal\nnutrition\ncompanion',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: OColors.textPrimary,
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Track meals, hit your macros, and reach your goals — in minutes a day.',
                  style: TextStyle(
                    fontSize: 16,
                    color: OColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 44),

                const _ValueProp(
                  icon: Icons.bolt_rounded,
                  text: 'Quick food logging and tracking',
                ),
                const SizedBox(height: 14),
                const _ValueProp(
                  icon: Icons.track_changes_rounded,
                  text: 'Personalized macro and calorie targets',
                ),
                const SizedBox(height: 14),
                const _ValueProp(
                  icon: Icons.insights_rounded,
                  text: 'Daily progress insights toward your goal',
                ),

                const Spacer(),

                OnboardingContinueButton(
                  onTap: () => Navigator.push(
                    context,
                    onboardingRoute(Screen02Features(data: widget.data)),
                  ),
                  label: 'Get Started',
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Takes about 2 minutes',
                    style: TextStyle(
                      fontSize: 13,
                      color: OColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ValueProp({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: OColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: OColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: OColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
