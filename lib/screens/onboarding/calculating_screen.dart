import 'package:flutter/material.dart';
import 'onboarding_data.dart';
import 'bmi_report_screen.dart';
import '../../widgets/layered_page_route.dart';

/// Calming interstitial shown while "calculating" BMR/BMI.
/// Auto-navigates to BmiReportScreen after a short animated pause.
class CalculatingScreen extends StatefulWidget {
  final OnboardingData data;
  const CalculatingScreen({super.key, required this.data});

  @override
  State<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Auto-navigate after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        layeredRoute(BmiReportScreen(data: widget.data)),
      );
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _pulseAnim.value,
                      child: Transform.scale(
                        scale: 0.9 + (_pulseAnim.value * 0.1),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      size: 36,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Calculating your BMR',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Analyzing your body metrics\nto personalize your plan...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Progress dots
                SizedBox(
                  width: 60,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (i) {
                          final delay = i * 0.3;
                          final v = ((_pulseAnim.value + delay) % 1.0);
                          final opacity = (v > 0.5 ? 1.0 - v : v) * 2.0;
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E)
                                  .withValues(alpha: 0.3 + opacity * 0.7),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
