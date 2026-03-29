import 'package:flutter/material.dart';
import '../onboarding_data.dart';
import '../../home_screen.dart';
import '../../../widgets/onboarding_widgets.dart';

/// Screen 17 — You're All Set!
/// Celebration screen with ripple rings + staggered content reveal.
/// Navigates to HomeScreen when user taps "Start Tracking".
class Screen17AllSet extends StatefulWidget {
  final OnboardingData data;
  const Screen17AllSet({super.key, required this.data});

  @override
  State<Screen17AllSet> createState() => _Screen17AllSetState();
}

class _Screen17AllSetState extends State<Screen17AllSet>
    with TickerProviderStateMixin {
  late AnimationController _rippleCtrl;
  late AnimationController _checkCtrl;
  late AnimationController _contentCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkScale = CurvedAnimation(
      parent: _checkCtrl,
      curve: Curves.elasticOut,
    );

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _checkCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _start() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final calories = widget.data.targetCalories ?? 0;
    final protein = widget.data.proteinGrams ?? 0;
    final firstName = widget.data.firstName;

    return Scaffold(
      backgroundColor: OColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Animated checkmark with ripple rings
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (i) {
                      final delay = i / 3.0;
                      return AnimatedBuilder(
                        animation: _rippleCtrl,
                        builder: (_, _) {
                          final rawT = (_rippleCtrl.value - delay) % 1.0;
                          final t = rawT < 0 ? rawT + 1.0 : rawT;
                          final eased = Curves.easeOut.transform(t);
                          return Opacity(
                            opacity: (1.0 - eased) * 0.3,
                            child: Transform.scale(
                              scale: 0.35 + eased * 0.9,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: OColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    ScaleTransition(
                      scale: _checkScale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: OColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: OColors.primary.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: _contentSlide,
                  child: Column(
                    children: [
                      Text(
                        firstName.isNotEmpty
                            ? "You're all set, $firstName!"
                            : "You're all set!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: OColors.textPrimary,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your personalized nutrition plan is ready.\nTime to make it happen.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: OColors.textSecondary,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 36),

                      if (calories > 0) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Daily Calories',
                                value: '$calories',
                                unit: 'kcal',
                                color: OColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Protein',
                                value: '$protein',
                                unit: 'g / day',
                                color: OColors.proteinColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      const _FeatureRow(
                        icon: Icons.camera_alt_rounded,
                        text: 'Log meals by photo, search, or description',
                      ),
                      const SizedBox(height: 12),
                      const _FeatureRow(
                        icon: Icons.insights_rounded,
                        text: 'Track your progress toward your goal daily',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    OnboardingContinueButton(
                      onTap: _start,
                      label: 'Start Tracking',
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: OColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OColors.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: OColors.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  color: OColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: OColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
