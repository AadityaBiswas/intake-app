import 'package:flutter/material.dart';

/// Premium onboarding page transition (Apple Health style).
///
/// Forward: Incoming page fades in (0→1) with subtle scale-up (0.97→1.0)
///          and vertical translate (12px→0).
/// Back: Reverses naturally.
class OnboardingPageRoute<T> extends PageRouteBuilder<T> {
  OnboardingPageRoute({required Widget page})
    : super(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: _buildTransition,
      );

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    // Incoming: fade + scale + vertical translate
    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    final scaleIn = Tween<double>(begin: 0.97, end: 1.0).animate(curve);
    final slideIn = Tween<Offset>(
      begin: const Offset(0, 0.015), // ~12px on a 800px screen
      end: Offset.zero,
    ).animate(curve);

    // When this page is being covered by the next page
    final secondaryCurve = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
    );
    final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(secondaryCurve);
    final scaleOut = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(secondaryCurve);

    return FadeTransition(
      opacity: fadeOut,
      child: ScaleTransition(
        scale: scaleOut,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: fadeIn,
            child: ScaleTransition(scale: scaleIn, child: child),
          ),
        ),
      ),
    );
  }
}

/// Convenience helper.
Route<T> onboardingRoute<T>(Widget page) => OnboardingPageRoute<T>(page: page);
