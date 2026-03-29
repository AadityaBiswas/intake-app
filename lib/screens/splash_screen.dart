import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'onboarding/onboarding_login_screen.dart';
import 'onboarding/onboarding_coordinator.dart';
import '../services/user_service.dart';
import '../widgets/onboarding_page_route.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _navigate();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    Widget nextScreen;

    if (user == null) {
      nextScreen = const OnboardingLoginScreen();
    } else {
      // Check if onboarding is complete
      final profile = await UserService.getUserProfile(user.uid);
      if (profile != null && profile.isOnboardingComplete) {
        nextScreen = const HomeScreen();
      } else {
        // Incomplete onboarding → new coordinator flow
        nextScreen = const OnboardingCoordinator();
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(onboardingRoute(nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: const Text(
            'Intake',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Color(0xFF22C55E),
              letterSpacing: -1.5,
            ),
          ),
        ),
      ),
    );
  }
}
