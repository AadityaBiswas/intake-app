import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home_screen.dart';
import '../../services/macro_calculator.dart';
import '../../widgets/layered_page_route.dart';

/// Displays the user's calculated daily macro targets after onboarding.
/// Uses the evidence-based MacroCalculator (Mifflin-St Jeor → TDEE → macros).
/// Users can tweak values before proceeding.
class MacroTargetsScreen extends StatefulWidget {
  const MacroTargetsScreen({super.key});

  @override
  State<MacroTargetsScreen> createState() => _MacroTargetsScreenState();
}

class _MacroTargetsScreenState extends State<MacroTargetsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  int _calories = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fat = 0;
  bool _loading = true;
  bool _saving = false;
  MacroResult? _result;

  // For "How We Calculated This"
  String _gender = '';
  int _age = 25;
  double _weight = 65;
  double _height = 170;
  String _activity = '';
  String _goal = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _calculateAndSave();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculateAndSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data() ?? {};

    _gender = (data['gender'] as String? ?? '').toLowerCase();
    _age = (data['age'] as num?)?.toInt() ?? 25;
    _weight = (data['weight'] as num?)?.toDouble() ?? 65.0;
    _height = (data['height'] as num?)?.toDouble() ?? 170.0;
    _activity = data['activity_level'] as String? ?? 'Sedentary';
    _goal = data['weight_goal'] as String? ?? 'Maintain Weight';

    final result = MacroCalculator.calculate(
      gender: _gender,
      age: _age,
      weightKg: _weight,
      heightCm: _height,
      activityLevel: _activity,
      weightGoal: _goal,
    );

    // Save to Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'goal_calories': result.targetCalories,
      'goal_protein': result.proteinGrams,
      'goal_carbs': result.carbGrams,
      'goal_fat': result.fatGrams,
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() {
        _result = result;
        _calories = result.targetCalories;
        _protein = result.proteinGrams;
        _carbs = result.carbGrams;
        _fat = result.fatGrams;
        _loading = false;
      });
      _animCtrl.forward();
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'goal_calories': _calories,
          'goal_protein': _protein,
          'goal_carbs': _carbs,
          'goal_fat': _fat,
        }, SetOptions(merge: true));
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        layeredRoute(const HomeScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showBreakdown() {
    if (_result == null) return;
    final r = _result!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _BreakdownSheet(
        result: r,
        gender: _gender,
        age: _age,
        weight: _weight,
        height: _height,
        activity: _activity,
        goal: _goal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)),
              )
            : FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      const Text(
                        'Your Daily\nTargets',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -1,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Calculated based on your body metrics and goals.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Calories card
                      _CalorieCard(calories: _calories),
                      const SizedBox(height: 20),

                      // Macro row
                      Row(
                        children: [
                          Expanded(
                            child: _MacroTile(
                              label: 'Protein',
                              value: _protein,
                              unit: 'g',
                              color: const Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MacroTile(
                              label: 'Carbs',
                              value: _carbs,
                              unit: 'g',
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MacroTile(
                              label: 'Fat',
                              value: _fat,
                              unit: 'g',
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // "How We Calculated This" link
                      GestureDetector(
                        onTap: _showBreakdown,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18, color: Color(0xFF22C55E)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'How we calculated this →',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF166534),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You can adjust these targets anytime from Account → Macro Goals.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Continue button
                      GestureDetector(
                        onTap: _saving ? null : _saveAndContinue,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Let's Go",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Breakdown sheet ─────────────────────────────────────────────────

class _BreakdownSheet extends StatelessWidget {
  final MacroResult result;
  final String gender;
  final int age;
  final double weight;
  final double height;
  final String activity;
  final String goal;

  const _BreakdownSheet({
    required this.result,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.activity,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final r = result;
    final isMale = gender.toLowerCase() != 'female';
    final genderOffset = isMale ? '+ 5' : '- 161';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined,
                    size: 20, color: Color(0xFF22C55E)),
                SizedBox(width: 8),
                Text(
                  'How We Calculated This',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepCard(
                    step: '1',
                    title: 'Basal Metabolic Rate (BMR)',
                    formula:
                        'BMR = (10 × weight) + (6.25 × height) − (5 × age) $genderOffset',
                    calculation:
                        'BMR = (10 × ${weight.round()}) + (6.25 × ${height.round()}) − (5 × $age) $genderOffset\n= ${r.bmr.round()} kcal',
                    note:
                        'This is how many calories your body burns at complete rest.',
                  ),
                  _StepCard(
                    step: '2',
                    title: 'Maintenance Calories',
                    formula: 'Maintenance = BMR × Activity Multiplier',
                    calculation:
                        'Maintenance = ${r.bmr.round()} × ${r.activityMultiplier}\n= ${r.maintenance.round()} kcal',
                    note:
                        'Your activity level ($activity) determines how much more you burn daily.',
                  ),
                  _StepCard(
                    step: '3',
                    title: 'Calorie Target',
                    formula:
                        'Target = Maintenance ${r.calorieAdjustment >= 0 ? '+' : '−'} ${r.calorieAdjustment.abs().round()} kcal',
                    calculation:
                        'Target = ${r.maintenance.round()} ${r.calorieAdjustment >= 0 ? '+' : '−'} ${r.calorieAdjustment.abs().round()}\n= ${r.targetCalories} kcal',
                    note: _goalNote(goal),
                  ),
                  _StepCard(
                    step: '4',
                    title: 'Protein',
                    formula: 'Protein = weight × g/kg multiplier',
                    calculation:
                        'Protein = ${weight.round()} × ${_proteinMultiplier(goal)} g/kg\n= ${r.proteinGrams}g (${r.proteinGrams * 4} kcal)',
                    note:
                        'Higher protein helps preserve muscle and keeps you satiated.',
                  ),
                  _StepCard(
                    step: '5',
                    title: 'Fat',
                    formula:
                        'Fat = ${(_fatPercent(goal) * 100).round()}% of total calories ÷ 9',
                    calculation:
                        'Fat = ${r.targetCalories} × ${(_fatPercent(goal) * 100).round()}% ÷ 9\n= ${r.fatGrams}g',
                    note: 'Essential for hormone production and nutrient absorption.',
                  ),
                  _StepCard(
                    step: '6',
                    title: 'Carbohydrates',
                    formula: 'Carbs = (Total − Protein cal − Fat cal) ÷ 4',
                    calculation:
                        'Carbs = (${r.targetCalories} − ${r.proteinGrams * 4} − ${(r.fatGrams * 9).round()}) ÷ 4\n= ${r.carbGrams}g',
                    note: 'Your primary energy source for workouts and daily tasks.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _goalNote(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('lose')) {
      return 'A gentle 300 kcal deficit supports steady, sustainable weight loss.';
    }
    if (g.contains('gain')) {
      return 'A moderate surplus supports lean muscle gain without excess fat.';
    }
    return 'No adjustment needed — you\'re maintaining your current weight.';
  }

  double _proteinMultiplier(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('lose')) return 2.2;
    if (g.contains('lean') || g.contains('gain')) return 2.0;
    if (g.contains('aggr')) return 1.9;
    return 1.8;
  }

  double _fatPercent(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('lose')) return 0.28;
    if (g.contains('lean') || g.contains('gain')) return 0.25;
    if (g.contains('aggr')) return 0.23;
    return 0.27;
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String formula;
  final String calculation;
  final String note;

  const _StepCard({
    required this.step,
    required this.title,
    required this.formula,
    required this.calculation,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            calculation,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Calories card ───────────────────────────────────────────────────

class _CalorieCard extends StatelessWidget {
  final int calories;
  const _CalorieCard({required this.calories});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'DAILY CALORIES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: calories),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '$value',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -3,
                  height: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'kcal / day',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Macro tile ──────────────────────────────────────────────────────

class _MacroTile extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final Color color;
  const _MacroTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              return Text(
                '$v$unit',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB0B8C4),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
