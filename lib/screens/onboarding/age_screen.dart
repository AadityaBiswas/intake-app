import 'package:flutter/material.dart';
import 'onboarding_data.dart';
import 'weight_screen.dart';
import '../../widgets/layered_page_route.dart';

class AgeScreen extends StatefulWidget {
  final OnboardingData data;
  const AgeScreen({super.key, required this.data});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen>
    with SingleTickerProviderStateMixin {
  late FixedExtentScrollController _scrollCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  int _selectedAge = 25;

  static const _minAge = 10;
  static const _maxAge = 80;

  @override
  void initState() {
    super.initState();
    _selectedAge = widget.data.age > 0 ? widget.data.age : 25;
    _scrollCtrl =
        FixedExtentScrollController(initialItem: _selectedAge - _minAge);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    widget.data.age = _selectedAge;
    Navigator.push(context, layeredRoute(WeightScreen(data: widget.data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left_rounded,
                          size: 28, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _StepBar(current: 3, total: 8)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'How old are you?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Your age helps us calculate your\nprotein needs accurately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                ),
              ),
              // Picker
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Highlight band
                    Container(
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    // Wheel with gradual sizing
                    ListWheelScrollView.useDelegate(
                      controller: _scrollCtrl,
                      itemExtent: 60,
                      perspective: 0.003,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) =>
                          setState(() => _selectedAge = _minAge + i),
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: _maxAge - _minAge + 1,
                        builder: (context, index) {
                          final age = _minAge + index;
                          final dist =
                              (age - _selectedAge).abs(); // 0,1,2,3...
                          final scale =
                              (1.0 - dist * 0.18).clamp(0.4, 1.0);
                          final opacity =
                              (1.0 - dist * 0.25).clamp(0.15, 1.0);
                          final isSelected = dist == 0;
                          return Center(
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.scale(
                                scale: scale,
                                child: Text(
                                  '$age',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Continue
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: _ContinueBtn(onTap: _next),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared ──────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int current, total;
  const _StepBar({required this.current, required this.total});
  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < current
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      );
}

class _ContinueBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Continue',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      );
}
