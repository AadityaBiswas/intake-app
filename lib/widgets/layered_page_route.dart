import 'package:flutter/material.dart';

/// Cupertino-style navigation transition.
///
/// Forward: Incoming page slides in from the right (100% → 0%),
/// outgoing page pushes left by 33% with slight dim.
///
/// Back: Reverses naturally.
class LayeredPageRoute<T> extends PageRouteBuilder<T> {
  LayeredPageRoute({required Widget page})
      : super(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, _, _) => page,
          transitionsBuilder: _buildTransition,
        );

  static const _curve = Cubic(0.36, 0.66, 0.04, 1.0); // iOS spring-like

  static Widget _buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Incoming: slide in from right edge
    final inSlide = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: _curve));

    // When THIS page gets covered by another page, push left 33%
    final outSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.33, 0.0),
    ).animate(CurvedAnimation(parent: secondaryAnimation, curve: _curve));

    final outDim = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: secondaryAnimation, curve: _curve));

    // Layer: secondary (push-back) on bottom, primary (slide-in) on top
    return SlideTransition(
      position: outSlide,
      child: FadeTransition(
        opacity: outDim,
        child: SlideTransition(
          position: inSlide,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.15 * animation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(-4, 0),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Convenience helper.
Route<T> layeredRoute<T>(Widget page) => LayeredPageRoute<T>(page: page);
