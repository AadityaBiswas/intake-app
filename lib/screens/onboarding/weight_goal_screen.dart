import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_data.dart';
import 'all_set_screen.dart';
import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../widgets/layered_page_route.dart';

class WeightGoalScreen extends StatefulWidget {
  final OnboardingData data;
  const WeightGoalScreen({super.key, required this.data});

  @override
  State<WeightGoalScreen> createState() => _WeightGoalScreenState();
}

class _WeightGoalScreenState extends State<WeightGoalScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;
  bool _isLoading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _goals = [
    {
      'label': 'Lose Weight',
      'desc': 'Caloric deficit for gradual weight loss',
      'icon': Icons.trending_down_rounded,
    },
    {
      'label': 'Maintain Weight',
      'desc': 'Keep your current weight steady',
      'icon': Icons.horizontal_rule_rounded,
    },
    {
      'label': 'Gain Weight',
      'desc': 'Caloric surplus for healthy weight gain',
      'icon': Icons.trending_up_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.weightGoal.isNotEmpty) _selected = widget.data.weightGoal;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_selected == null) return;
    widget.data.weightGoal = _selected!;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final heightM = widget.data.height / 100;
      final bmi = widget.data.weight / (heightM * heightM);

      // Update display name
      await user.updateDisplayName(widget.data.name);

      final profile = UserProfile(
        uid: user.uid,
        name: widget.data.name,
        gender: widget.data.gender,
        age: widget.data.age,
        weight: widget.data.weight,
        height: widget.data.height,
        activityLevel: widget.data.activityLevel,
        bmi: bmi,
        weightGoal: widget.data.weightGoal,
      );
      await UserService.saveUserProfile(profile);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        layeredRoute(const AllSetScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
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
                    Expanded(child: _StepIndicator(current: 8, total: 8)),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  "What's your goal?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We'll tailor your daily nutrition targets accordingly.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ..._goals.map((goal) {
                  final label = goal['label'] as String;
                  final desc = goal['desc'] as String;
                  final icon = goal['icon'] as IconData;
                  final isSelected = _selected == label;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 18),
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
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
                    ),
                  );
                }),
                const Spacer(),
                GestureDetector(
                  onTap: _isLoading ? null : _finish,
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
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            "Let's Go!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
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
