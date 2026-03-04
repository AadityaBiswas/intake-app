import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/macro_calculator.dart';

class MacroGoalsSheet extends StatefulWidget {
  const MacroGoalsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => const MacroGoalsSheet(),
    );
  }

  @override
  State<MacroGoalsSheet> createState() => _MacroGoalsSheetState();
}

class _MacroGoalsSheetState extends State<MacroGoalsSheet> {
  bool _loading = true;
  bool _saving = false;
  bool _recalculating = false;

  int _calories = 2100;
  int _protein = 160;
  int _carbs = 250;
  int _fat = 65;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  int get _macroCalories =>
      (_protein * 4) + (_carbs * 4) + (_fat * 9);

  double get _proteinPct =>
      _macroCalories > 0 ? (_protein * 4) / _macroCalories * 100 : 0;
  double get _carbsPct =>
      _macroCalories > 0 ? (_carbs * 4) / _macroCalories * 100 : 0;
  double get _fatPct =>
      _macroCalories > 0 ? (_fat * 9) / _macroCalories * 100 : 0;

  Future<void> _loadGoals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data() ?? {};

    if (mounted) {
      setState(() {
        _protein = (data['goal_protein'] as num?)?.toInt() ?? 160;
        _carbs = (data['goal_carbs'] as num?)?.toInt() ?? 250;
        _fat = (data['goal_fat'] as num?)?.toInt() ?? 65;
        _calories = (data['goal_calories'] as num?)?.toInt() ?? 2100;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'goal_protein': _protein,
      'goal_carbs': _carbs,
      'goal_fat': _fat,
      'goal_calories': _calories,
    }, SetOptions(merge: true));

    if (mounted) Navigator.pop(context);
  }

  void _adjustMacro(String macro, int delta) {
    setState(() {
      switch (macro) {
        case 'protein':
          _protein = (_protein + delta).clamp(0, 500);
        case 'carbs':
          _carbs = (_carbs + delta).clamp(0, 800);
        case 'fat':
          _fat = (_fat + delta).clamp(0, 300);
      }
      // Sync calories from macros
      _calories = _macroCalories;
    });
  }

  void _adjustCalories(int delta) {
    setState(() {
      _calories = (_calories + delta).clamp(800, 6000);
    });
  }

  Future<void> _recalculateFromProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _recalculating = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};

      final result = MacroCalculator.calculate(
        gender: (data['gender'] as String? ?? '').toLowerCase(),
        age: (data['age'] as num?)?.toInt() ?? 25,
        weightKg: (data['weight'] as num?)?.toDouble() ?? 65.0,
        heightCm: (data['height'] as num?)?.toDouble() ?? 170.0,
        activityLevel: data['activity_level'] as String? ?? 'Sedentary',
        weightGoal: data['weight_goal'] as String? ?? 'Maintain Weight',
      );

      if (mounted) {
        setState(() {
          _calories = result.targetCalories;
          _protein = result.proteinGrams;
          _carbs = result.carbGrams;
          _fat = result.fatGrams;
          _recalculating = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _recalculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 40,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0x80CBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title + close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Macro Goals',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0x99E2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 20, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Adjust your daily targets. Use + / − to fine-tune percentages.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Macro rows
                _MacroRow(
                  label: 'Protein',
                  grams: _protein,
                  percent: _proteinPct,
                  color: Colors.black87,
                  icon: Icons.fitness_center_rounded,
                  onIncrement: () => _adjustMacro('protein', 5),
                  onDecrement: () => _adjustMacro('protein', -5),
                ),
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'Carbs',
                  grams: _carbs,
                  percent: _carbsPct,
                  color: Colors.black87,
                  icon: Icons.grain_rounded,
                  onIncrement: () => _adjustMacro('carbs', 5),
                  onDecrement: () => _adjustMacro('carbs', -5),
                ),
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'Fat',
                  grams: _fat,
                  percent: _fatPct,
                  color: Colors.black87,
                  icon: Icons.water_drop_outlined,
                  onIncrement: () => _adjustMacro('fat', 5),
                  onDecrement: () => _adjustMacro('fat', -5),
                ),
                const SizedBox(height: 16),
                Container(height: 0.5, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 16),

                // Calories row
                _MacroRow(
                  label: 'Calories',
                  grams: _calories,
                  percent: null,
                  color: const Color(0xFF64748B),
                  icon: Icons.local_fire_department_rounded,
                  unit: 'kcal',
                  onIncrement: () => _adjustCalories(50),
                  onDecrement: () => _adjustCalories(-50),
                ),
                const SizedBox(height: 12),

                // Recalculate button
                GestureDetector(
                  onTap: _recalculating ? null : _recalculateFromProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _recalculating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFF22C55E),
                                ),
                              )
                            : const Icon(Icons.calculate_outlined,
                                size: 16, color: Color(0xFF22C55E)),
                        const SizedBox(width: 8),
                        const Text(
                          'Recalculate from profile',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    decoration: BoxDecoration(
                      color: _saving
                          ? const Color(0xFF22C55E).withValues(alpha: 0.6)
                          : const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Goals',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Macro Row Widget ───────────────────────────────────────────────

class _MacroRow extends StatelessWidget {
  final String label;
  final int grams;
  final double? percent; // null for calories
  final Color color;
  final IconData icon;
  final String unit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.percent,
    required this.color,
    required this.icon,
    this.unit = 'g',
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          // Label + grams
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$grams $unit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Percentage badge (if applicable)
          if (percent != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 12),
              child: Text(
                '${percent!.round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          // +/- buttons
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.remove, size: 16,
                  color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, size: 16,
                  color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}
