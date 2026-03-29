import 'package:flutter/material.dart';
import 'onboarding_data.dart';
import 'screens/screen_01_intro.dart';
import '../../widgets/onboarding_page_route.dart';

/// Entry-point for the new onboarding flow.
///
/// Creates a fresh [OnboardingData] and pushes into the sequential flow
/// starting at Screen 1 (Introduction).
///
/// All inter-screen navigation is handled by individual screens calling
/// [onboardingRoute] with the next screen, passing [OnboardingData] forward.
class OnboardingCoordinator extends StatelessWidget {
  const OnboardingCoordinator({super.key});

  @override
  Widget build(BuildContext context) {
    final data = OnboardingData();
    return Screen01Intro(data: data);
  }
}
