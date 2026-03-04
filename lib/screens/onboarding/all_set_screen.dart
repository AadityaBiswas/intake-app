import 'package:flutter/material.dart';
import 'macro_targets_screen.dart';
import '../../widgets/layered_page_route.dart';

/// "You're all set!" completion screen shown after onboarding.
/// Auto-navigates to HomeScreen after a brief animated pause.
class AllSetScreen extends StatefulWidget {
  const AllSetScreen({super.key});

  @override
  State<AllSetScreen> createState() => _AllSetScreenState();
}

class _AllSetScreenState extends State<AllSetScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _scaleCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late AnimationController _checkCtrl;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut),
    );

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkAnim = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut);

    // Stagger the animations
    _fadeCtrl.forward();
    _scaleCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _checkCtrl.forward();
    });

    // Auto-navigate after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        layeredRoute(const MacroTargetsScreen()),
      );
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    _checkCtrl.dispose();
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
                // Animated checkmark circle
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: FadeTransition(
                      opacity: _checkAnim,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  "You're all set!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your personalized nutrition plan\nis ready to go.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                    height: 1.5,
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
