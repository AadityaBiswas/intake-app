import 'package:flutter/material.dart';
import 'onboarding_data.dart';
import 'age_screen.dart';
import '../../widgets/layered_page_route.dart';

class GenderScreen extends StatefulWidget {
  final OnboardingData data;
  const GenderScreen({super.key, required this.data});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _options = [
    {'label': 'Male', 'icon': Icons.male_rounded},
    {'label': 'Female', 'icon': Icons.female_rounded},
    {'label': 'Other', 'icon': Icons.transgender_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.gender.isNotEmpty) _selected = widget.data.gender;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_selected == null) return;
    widget.data.gender = _selected!;
    Navigator.push(context, layeredRoute(AgeScreen(data: widget.data)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left_rounded,
                            size: 28, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _StepIndicator(current: 2, total: 8)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Select your gender',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This helps us calculate your nutritional requirements.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                ..._options.map((opt) {
                  final label = opt['label'] as String;
                  final icon = opt['icon'] as IconData;
                  final isSelected = _selected == label;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFECFDF5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF1F5F9),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(icon,
                                size: 28,
                                color: isSelected
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFF94A3B8)),
                            const SizedBox(width: 16),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF22C55E), size: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                _ContinueButton(onTap: _next),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared widgets (duplicated per file for simplicity) ──────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i < current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ContinueButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        child: const Text(
          'Continue',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }
}
