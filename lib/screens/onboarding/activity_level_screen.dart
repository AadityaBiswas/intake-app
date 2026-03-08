import 'package:flutter/material.dart';
import 'onboarding_data.dart';
import 'calculating_screen.dart';
import '../../widgets/layered_page_route.dart';

class ActivityLevelScreen extends StatefulWidget {
  final OnboardingData data;
  const ActivityLevelScreen({super.key, required this.data});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _levels = [
    {
      'label': 'Sedentary',
      'desc': 'Little or no exercise',
      'icon': Icons.weekend_rounded,
    },
    {
      'label': 'Lightly Active',
      'desc': 'Light exercise 1-3 days/week',
      'icon': Icons.directions_walk_rounded,
    },
    {
      'label': 'Moderately Active',
      'desc': 'Moderate exercise 3-5 days/week',
      'icon': Icons.directions_run_rounded,
    },
    {
      'label': 'Very Active',
      'desc': 'Hard exercise 6-7 days/week',
      'icon': Icons.fitness_center_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.activityLevel.isNotEmpty) {
      _selected = widget.data.activityLevel;
    }
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
    widget.data.activityLevel = _selected!;
    Navigator.push(context, layeredRoute(CalculatingScreen(data: widget.data)));
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left_rounded,
                          size: 28, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _StepIndicator(current: 6, total: 8)),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Activity level',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'How active are you on a typical week?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _levels.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final level = _levels[i];
                      final label = level['label'] as String;
                      final desc = level['desc'] as String;
                      final icon = level['icon'] as IconData;
                      final isSelected = _selected == label;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
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
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF22C55E)
                                          .withValues(alpha: 0.12)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon,
                                    size: 22,
                                    color: isSelected
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF94A3B8)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF22C55E), size: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
