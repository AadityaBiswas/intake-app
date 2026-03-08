import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/macro_calculator.dart';

class MacroGoalsSheet extends StatefulWidget {
  const MacroGoalsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
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
  // Store percentages as the primary source (0–100)
  int _proteinPct = 30;
  int _carbsPct = 45;
  int _fatPct = 25;

  // Derived gram values
  int get _protein => (_calories * _proteinPct / 100 / 4).round();
  int get _carbs => (_calories * _carbsPct / 100 / 4).round();
  int get _fat => (_calories * _fatPct / 100 / 9).round();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data() ?? {};

    if (mounted) {
      final cal = (data['goal_calories'] as num?)?.toInt() ?? 2100;
      final p = (data['goal_protein'] as num?)?.toInt() ?? 0;
      final c = (data['goal_carbs'] as num?)?.toInt() ?? 0;
      final f = (data['goal_fat'] as num?)?.toInt() ?? 0;

      // Derive percentages from stored gram values
      final totalMacroCal = (p * 4) + (c * 4) + (f * 9);
      final base = totalMacroCal > 0 ? totalMacroCal : cal;

      setState(() {
        _calories = cal;
        _proteinPct = base > 0 ? ((p * 4) / base * 100).round() : 30;
        _carbsPct = base > 0 ? ((c * 4) / base * 100).round() : 45;
        _fatPct = base > 0 ? ((f * 9) / base * 100).round() : 25;
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

  void _adjustPct(String macro, int delta) {
    setState(() {
      switch (macro) {
        case 'protein':
          _proteinPct = (_proteinPct + delta).clamp(5, 60);
        case 'carbs':
          _carbsPct = (_carbsPct + delta).clamp(5, 70);
        case 'fat':
          _fatPct = (_fatPct + delta).clamp(5, 60);
      }
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
        final cal = result.targetCalories;
        final totalMacroCal =
            (result.proteinGrams * 4) +
            (result.carbGrams * 4) +
            (result.fatGrams * 9);
        final base = totalMacroCal > 0 ? totalMacroCal : cal;

        setState(() {
          _calories = cal;
          _proteinPct = base > 0
              ? ((result.proteinGrams * 4) / base * 100).round()
              : 30;
          _carbsPct = base > 0
              ? ((result.carbGrams * 4) / base * 100).round()
              : 45;
          _fatPct = base > 0
              ? ((result.fatGrams * 9) / base * 100).round()
              : 25;
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
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title + close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Macro Goals',
                      style: TextStyle(
                        fontSize: 20,
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
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Macros card (protein, carbs, fat)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      _MacroRow(
                        label: 'Protein',
                        grams: _protein,
                        percent: _proteinPct,
                        icon: Icons.fitness_center_rounded,
                        onIncrement: () => _adjustPct('protein', 1),
                        onDecrement: () => _adjustPct('protein', -1),
                      ),
                      const Divider(
                        height: 1,
                        indent: 52,
                        color: Color(0xFFF1F5F9),
                      ),
                      _MacroRow(
                        label: 'Carbs',
                        grams: _carbs,
                        percent: _carbsPct,
                        icon: Icons.grain_rounded,
                        onIncrement: () => _adjustPct('carbs', 1),
                        onDecrement: () => _adjustPct('carbs', -1),
                      ),
                      const Divider(
                        height: 1,
                        indent: 52,
                        color: Color(0xFFF1F5F9),
                      ),
                      _MacroRow(
                        label: 'Fat',
                        grams: _fat,
                        percent: _fatPct,
                        icon: Icons.water_drop_outlined,
                        onIncrement: () => _adjustPct('fat', 1),
                        onDecrement: () => _adjustPct('fat', -1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Calories card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: _MacroRow(
                    label: 'Calories',
                    grams: _calories,
                    percent: null,
                    icon: Icons.local_fire_department_rounded,
                    unit: 'kcal',
                    onIncrement: () => _adjustCalories(50),
                    onDecrement: () => _adjustCalories(-50),
                  ),
                ),
                const SizedBox(height: 12),

                // Auto-calculate button
                GestureDetector(
                  onTap: _recalculating ? null : _recalculateFromProfile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _recalculating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFF22C55E),
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: Color(0xFF22C55E),
                              ),
                        const SizedBox(width: 8),
                        const Text(
                          'Auto-calculate from profile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Save button
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    decoration: BoxDecoration(
                      color: _saving
                          ? const Color(0xFF22C55E).withValues(alpha: 0.6)
                          : const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
  final int? percent;
  final IconData icon;
  final String unit;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.percent,
    required this.icon,
    this.unit = 'g',
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  '$grams $unit',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Percentage badge (if applicable)
          if (percent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
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
              child: const Icon(
                Icons.remove,
                size: 16,
                color: Color(0xFF64748B),
              ),
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
              child: const Icon(Icons.add, size: 16, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }
}
