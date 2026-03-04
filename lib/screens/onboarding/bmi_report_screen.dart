import 'package:flutter/material.dart';
import 'onboarding_data.dart';
import 'weight_goal_screen.dart';
import '../../widgets/layered_page_route.dart';

class BmiReportScreen extends StatefulWidget {
  final OnboardingData data;
  const BmiReportScreen({super.key, required this.data});

  @override
  State<BmiReportScreen> createState() => _BmiReportScreenState();
}

class _BmiReportScreenState extends State<BmiReportScreen>
    with SingleTickerProviderStateMixin {
  late double _bmi;
  late String _category;
  late Color _categoryColor;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _calculateBmi();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );
    _animCtrl.forward();
  }

  void _calculateBmi() {
    final heightM = widget.data.height / 100;
    _bmi = widget.data.weight / (heightM * heightM);
    if (_bmi < 18.5) {
      _category = 'Underweight';
      _categoryColor = const Color(0xFF3B82F6);
    } else if (_bmi < 25) {
      _category = 'Normal';
      _categoryColor = const Color(0xFF22C55E);
    } else if (_bmi < 30) {
      _category = 'Overweight';
      _categoryColor = const Color(0xFFF59E0B);
    } else {
      _category = 'Obese';
      _categoryColor = const Color(0xFFEF4444);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    Navigator.push(context, layeredRoute(WeightGoalScreen(data: widget.data)));
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
                    Expanded(child: _StepIndicator(current: 7, total: 8)),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Your BMI Report',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Based on your height and weight.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const Spacer(),

                // BMI Card
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _bmi.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: _categoryColor,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: _categoryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _category,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Scale bar
                        _BmiScale(bmi: _bmi),
                        const SizedBox(height: 20),

                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(
                                label: 'Weight',
                                value: '${widget.data.weight.round()} kg'),
                            Container(
                                width: 1,
                                height: 32,
                                color: const Color(0xFFE2E8F0)),
                            _StatItem(
                                label: 'Height',
                                value: '${widget.data.height.round()} cm'),
                            Container(
                                width: 1,
                                height: 32,
                                color: const Color(0xFFE2E8F0)),
                            _StatItem(
                                label: 'Age',
                                value: '${widget.data.age}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

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

class _BmiScale extends StatelessWidget {
  final double bmi;
  const _BmiScale({required this.bmi});

  @override
  Widget build(BuildContext context) {
    // Map BMI to position (15-40 range => 0.0-1.0)
    final position = ((bmi - 15) / 25).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          height: 12,
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF22C55E),
                        Color(0xFFF59E0B),
                        Color(0xFFEF4444),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (constraints.maxWidth * position) - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0F172A), width: 2.5),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('15',
                style: TextStyle(fontSize: 11, color: Color(0xFFB0B8C4))),
            Text('18.5',
                style: TextStyle(fontSize: 11, color: Color(0xFFB0B8C4))),
            Text('25',
                style: TextStyle(fontSize: 11, color: Color(0xFFB0B8C4))),
            Text('30',
                style: TextStyle(fontSize: 11, color: Color(0xFFB0B8C4))),
            Text('40',
                style: TextStyle(fontSize: 11, color: Color(0xFFB0B8C4))),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF94A3B8))),
      ],
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
