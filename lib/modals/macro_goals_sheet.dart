import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/macro_calculator.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFEEF2F7);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF64748B);
const _kTextTertiary = Color(0xFFB0BAC6);
const _kHandle = Color(0xFFDDE3ED);
const _kGreen = Color(0xFF22C55E);

class MacroGoalsSheet extends StatefulWidget {
  const MacroGoalsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
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
  bool _hasChanges = false;

  late TextEditingController _calController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  int _calories = 2100;
  int _protein = 160;
  int _carbs = 250;
  int _fat = 65;

  int _origCalories = 2100;
  int _origProtein = 160;
  int _origCarbs = 250;
  int _origFat = 65;

  @override
  void initState() {
    super.initState();
    _calController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _loadGoals();
  }

  @override
  void dispose() {
    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    _calController.text = '$_calories';
    _proteinController.text = '$_protein';
    _carbsController.text = '$_carbs';
    _fatController.text = '$_fat';
  }

  void _checkForChanges() {
    final changed =
        _calories != _origCalories ||
        _protein != _origProtein ||
        _carbs != _origCarbs ||
        _fat != _origFat;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  Future<void> _loadGoals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    if (mounted) {
      setState(() {
        _calories = (data['goal_calories'] as num?)?.toInt() ?? 2100;
        _protein = (data['goal_protein'] as num?)?.toInt() ?? 160;
        _carbs = (data['goal_carbs'] as num?)?.toInt() ?? 250;
        _fat = (data['goal_fat'] as num?)?.toInt() ?? 65;
        _origCalories = _calories;
        _origProtein = _protein;
        _origCarbs = _carbs;
        _origFat = _fat;
        _updateControllers();
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
    HapticFeedback.selectionClick();
    setState(() {
      switch (macro) {
        case 'calories':
          _calories = (_calories + delta).clamp(800, 6000);
          _calController.text = '$_calories';
        case 'protein':
          _protein = (_protein + delta).clamp(0, 500);
          _proteinController.text = '$_protein';
        case 'carbs':
          _carbs = (_carbs + delta).clamp(0, 800);
          _carbsController.text = '$_carbs';
        case 'fat':
          _fat = (_fat + delta).clamp(0, 300);
          _fatController.text = '$_fat';
      }
      _checkForChanges();
    });
  }

  void _onFieldChanged(String macro, String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() {
      switch (macro) {
        case 'calories':
          _calories = parsed.clamp(800, 6000);
        case 'protein':
          _protein = parsed.clamp(0, 500);
        case 'carbs':
          _carbs = parsed.clamp(0, 800);
        case 'fat':
          _fat = parsed.clamp(0, 300);
      }
      _checkForChanges();
    });
  }

  Future<void> _recalculateFromProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _recalculating = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      final result = MacroCalculator.calculate(
        gender: (data['gender'] as String? ?? '').toLowerCase(),
        age: (data['age'] as num?)?.toInt() ?? 25,
        weightKg: (data['weight'] as num?)?.toDouble() ?? 65.0,
        heightCm: (data['height'] as num?)?.toDouble() ?? 170.0,
        activityLevel: data['activity_level'] as String? ?? 'Sedentary',
        weightGoal: data['weight_goal'] as String? ?? 'Maintain Weight',
        goalIntensity: data['goal_intensity'] as String? ?? '',
      );
      if (mounted) {
        setState(() {
          _calories = result.targetCalories;
          _protein = result.proteinGrams;
          _carbs = result.carbGrams;
          _fat = result.fatGrams;
          _updateControllers();
          _recalculating = false;
          _checkForChanges();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _recalculating = false);
    }
  }

  int get _macroCalories => (_protein * 4) + (_carbs * 4) + (_fat * 9);
  int get _calorieDiff => _macroCalories - _calories;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 40,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: _loading
          ? SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  color: _kGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _kHandle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24, 20, 24,
                      24 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title + close
                        Row(
                          children: [
                            const Text(
                              'Macro Goals',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _kTextPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _kBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _kBorder, width: 1),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: _kTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Adjust your daily nutrition targets',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildMacroEditRow(
                          label: 'Daily Calories',
                          value: _calories,
                          unit: 'kcal',
                          color: const Color(0xFFF59E0B),
                          icon: Icons.local_fire_department_rounded,
                          controller: _calController,
                          step: 50,
                          macro: 'calories',
                        ),
                        const SizedBox(height: 10),
                        _buildMacroEditRow(
                          label: 'Protein',
                          value: _protein,
                          unit: 'g',
                          color: _kGreen,
                          icon: Icons.egg_rounded,
                          controller: _proteinController,
                          step: 5,
                          macro: 'protein',
                        ),
                        const SizedBox(height: 10),
                        _buildMacroEditRow(
                          label: 'Carbs',
                          value: _carbs,
                          unit: 'g',
                          color: const Color(0xFF3B82F6),
                          icon: Icons.grain_rounded,
                          controller: _carbsController,
                          step: 5,
                          macro: 'carbs',
                        ),
                        const SizedBox(height: 10),
                        _buildMacroEditRow(
                          label: 'Fat',
                          value: _fat,
                          unit: 'g',
                          color: const Color(0xFFF59E0B),
                          icon: Icons.water_drop_rounded,
                          controller: _fatController,
                          step: 5,
                          macro: 'fat',
                        ),
                        const SizedBox(height: 14),

                        _buildCalorieBalance(),
                        const SizedBox(height: 14),

                        // Auto-calculate
                        GestureDetector(
                          onTap: _recalculating ? null : _recalculateFromProfile,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: _kBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _recalculating
                                    ? const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: _kGreen,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.refresh_rounded,
                                        size: 15,
                                        color: _kGreen,
                                      ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Auto-calculate from profile',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Save button
                        GestureDetector(
                          onTap: (_saving || !_hasChanges) ? null : _save,
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 54,
                            decoration: BoxDecoration(
                              color: _hasChanges
                                  ? (_saving
                                      ? _kGreen.withValues(alpha: 0.6)
                                      : _kGreen)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _hasChanges
                                  ? [
                                      BoxShadow(
                                        color: _kGreen.withValues(alpha: 0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Save Goals',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _hasChanges
                                          ? Colors.white
                                          : _kTextSecondary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMacroEditRow({
    required String label,
    required int value,
    required String unit,
    required Color color,
    required IconData icon,
    required TextEditingController controller,
    required int step,
    required String macro,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (macro != 'calories')
                  Text(
                    '${value * (macro == 'fat' ? 9 : 4)} kcal',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _kTextTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: () => _adjustMacro(macro, -step),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 65,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: unit,
                    suffixStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: color.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: color, width: 1.5),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                  onChanged: (v) => _onFieldChanged(macro, v),
                ),
              ),
              const SizedBox(width: 6),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: () => _adjustMacro(macro, step),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieBalance() {
    final diff = _calorieDiff;
    final isBalanced = diff.abs() <= 50;
    final isOver = diff > 50;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isBalanced
            ? const Color(0xFFECFDF5)
            : isOver
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBalanced
              ? _kGreen.withValues(alpha: 0.3)
              : isOver
                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBalanced ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 16,
            color: isBalanced
                ? _kGreen
                : isOver
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isBalanced
                      ? const Color(0xFF166534)
                      : isOver
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF92400E),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Macro total: $_macroCalories kcal',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (!isBalanced)
                    TextSpan(
                      text: isOver
                          ? ' (+$diff over target)'
                          : ' (${diff.abs()} under target)',
                    ),
                  if (isBalanced) const TextSpan(text: ' — balanced ✓'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: 15, color: _kTextSecondary),
      ),
    );
  }
}
