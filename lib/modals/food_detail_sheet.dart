import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food.dart';
import '../models/scaled_nutrition.dart';
import '../services/scaling_engine.dart';

/// Result returned when the sheet is closed via Save.
class FoodDetailResult {
  final bool deleted;
  final ScaledNutrition nutrition;
  final Food? updatedFood;
  final String? thoughtProcess;

  const FoodDetailResult({
    this.deleted = false,
    required this.nutrition,
    this.updatedFood,
    this.thoughtProcess,
  });
}

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF8FAFC);
const _kSurface = Color(0xFFFFFFFF);
const _kBorder = Color(0xFFEEF2F7);
const _kBorderStrong = Color(0xFFE2E8F0);
const _kTextPrimary = Color(0xFF0D1117);
const _kTextSecondary = Color(0xFF64748B);
const _kTextTertiary = Color(0xFFB0BAC6);
const _kGreen = Color(0xFF22C55E);
const _kBlue = Color(0xFF3B82F6);
const _kAmber = Color(0xFFF59E0B);
const _kOrange = Color(0xFFEA580C);
const _kHandle = Color(0xFFDDE3ED);
const _kDivider = Color(0xFFF1F5F9);

class FoodDetailSheet extends StatefulWidget {
  final Food food;
  final ScaledNutrition nutrition;
  final DateTime? createdAt;
  final String? thoughtProcess;
  final String? location;

  const FoodDetailSheet({
    super.key,
    required this.food,
    required this.nutrition,
    this.createdAt,
    this.thoughtProcess,
    this.location,
  });

  static Future<FoodDetailResult?> show(
    BuildContext context, {
    required Food food,
    required ScaledNutrition nutrition,
    DateTime? createdAt,
    String? thoughtProcess,
    String? location,
  }) {
    return showModalBottomSheet<FoodDetailResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (context) => FoodDetailSheet(
        food: food,
        nutrition: nutrition,
        createdAt: createdAt,
        thoughtProcess: thoughtProcess,
        location: location,
      ),
    );
  }

  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  late TextEditingController _quantityController;

  late double _gramsUsed;
  String _selectedUnit = 'g';
  String? _recalcThoughtProcess;
  bool _hasChanges = false;

  late double _basePer100gProtein;
  late double _basePer100gCarbs;
  late double _basePer100gFat;
  late double _basePer100gCalories;


  @override
  void initState() {
    super.initState();
    _basePer100gProtein = widget.food.nutritionPer100g.protein;
    _basePer100gCarbs = widget.food.nutritionPer100g.carbs;
    _basePer100gFat = widget.food.nutritionPer100g.fat;
    _basePer100gCalories = widget.food.nutritionPer100g.calories;

    _gramsUsed = widget.nutrition.gramsUsed;

    final preferred = widget.food.preferredUnit;
    final gramsPerPreferred = preferred != null
        ? (ScalingEngine.unitToGrams[preferred] ??
              widget.food.defaultServingGrams)
        : null;

    if (preferred != null &&
        preferred != 'g' &&
        gramsPerPreferred != null &&
        gramsPerPreferred > 0) {
      _selectedUnit = preferred;
      final displayQty = _gramsUsed / gramsPerPreferred;
      _quantityController = TextEditingController(
        text: displayQty.round().toString(),
      );
    } else {
      _selectedUnit = 'g';
      _quantityController = TextEditingController(
        text: _gramsUsed.round().toString(),
      );
    }
    _quantityController.addListener(_onQuantityChanged);

  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    final text = _quantityController.text;
    final quantity = double.tryParse(text) ?? 0;
    final gramsPerUnit = ScalingEngine.unitToGrams[_selectedUnit] ?? 1.0;
    setState(() {
      _gramsUsed = quantity * gramsPerUnit;
      _hasChanges = true;
    });
  }

  void _onUnitChanged(String? newUnit) {
    if (newUnit == null || newUnit == _selectedUnit) return;
    setState(() {
      _selectedUnit = newUnit;
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final gramsPerUnit = ScalingEngine.unitToGrams[_selectedUnit] ?? 1.0;
      _gramsUsed = quantity * gramsPerUnit;
      _hasChanges = true;
    });
  }

  double get _multiplier => _gramsUsed / 100.0;

  ScaledNutrition _computeScaled() {
    final per100g = NutritionPer100g(
      calories: _basePer100gCalories,
      protein: _basePer100gProtein,
      carbs: _basePer100gCarbs,
      fat: _basePer100gFat,
    );
    return ScalingEngine.scale(
      per100g,
      quantity: _gramsUsed,
      unit: 'g',
      defaultServingGrams: widget.food.defaultServingGrams,
    );
  }

  static const Map<String, String> _unitDisplayNames = {
    'g': 'Grams',
    'ml': 'Milliliters',
    'bowl': 'Bowls',
    'cup': 'Cups',
    'plate': 'Plates',
    'piece': 'Pieces',
    'tbsp': 'Tablespoons',
    'tsp': 'Teaspoons',
    'slice': 'Slices',
    'serving': 'Servings',
  };

  void _showUnitPicker() {
    const allUnits = [
      'g',
      'ml',
      'bowl',
      'cup',
      'plate',
      'piece',
      'tbsp',
      'tsp',
      'slice',
      'serving',
    ];
    final curatedUnits = (widget.food.validUnits?.isNotEmpty == true)
        ? widget.food.validUnits!
        : allUnits;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.30),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          0,
          12,
          0,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: _kHandle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    'Unit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${curatedUnits.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kTextTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _kBorder, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: curatedUnits.length,
                      separatorBuilder: (context, index) => Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: _kDivider,
                      ),
                      itemBuilder: (context, index) {
                        final unit = curatedUnits[index];
                        final isSelected = unit == _selectedUnit;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                            _onUnitChanged(unit);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _unitDisplayNames[unit] ?? unit,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? _kTextPrimary
                                        : _kTextSecondary,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: _kGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    Navigator.pop(context, FoodDetailResult(nutrition: _computeScaled()));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final currentProtein = (_basePer100gProtein * _multiplier).round();
    final currentCarbs = (_basePer100gCarbs * _multiplier).round();
    final currentFat = (_basePer100gFat * _multiplier).round();
    final currentCalories = (_basePer100gCalories * _multiplier).round();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 48,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────────────
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
          const SizedBox(height: 18),

          // ── Header: name + close ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                      if (widget.createdAt != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: _kTextTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              TimeOfDay.fromDateTime(
                                widget.createdAt!,
                              ).format(context),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _kTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kBorder, width: 1),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: _kTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Macro hero ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _MacroHeroStrip(
              calories: currentCalories,
              protein: currentProtein,
              carbs: currentCarbs,
              fat: currentFat,
            ),
          ),
          const SizedBox(height: 20),

          // ── Divider ───────────────────────────────────────────────
          Container(height: 1, color: _kDivider),

          // ── Scrollable body ───────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                math.max(24, bottomPad) +
                    MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuantitySection(),

                  if (_activeThoughtProcess != null &&
                      _activeThoughtProcess!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildThoughtProcessSection(),
                  ],


                  if (_hasChanges) ...[
                    const SizedBox(height: 20),
                    _buildSaveButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quantity section ──────────────────────────────────────────────

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('QUANTITY'),
        const SizedBox(height: 10),
        Row(
          children: [
            // Amount input
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder, width: 1.5),
                ),
                child: TextField(
                  controller: _quantityController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                    letterSpacing: -0.5,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Unit picker
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _showUnitPicker,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _unitDisplayNames[_selectedUnit] ?? _selectedUnit,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _kTextTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Getters ───────────────────────────────────────────────────────

  String? get _activeThoughtProcess =>
      _recalcThoughtProcess ?? widget.thoughtProcess;


  // ─── Section builders ──────────────────────────────────────────────

  Widget _buildThoughtProcessSection() {
    return _ThoughtProcessCard(text: _activeThoughtProcess!);
  }

  // ─── Action buttons ────────────────────────────────────────────────



  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: _kGreen,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kGreen.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kTextTertiary,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ─── Macro Hero Strip ─────────────────────────────────────────────────────────

class _MacroHeroStrip extends StatelessWidget {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const _MacroHeroStrip({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Calories — prominent left block
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CALORIES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kTextTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$calories',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: _kTextPrimary,
                  height: 1.0,
                  letterSpacing: -2.5,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextTertiary,
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          width: 1,
          height: 60,
          color: _kDivider,
          margin: const EdgeInsets.symmetric(horizontal: 20),
        ),

        // Macros — tiled right block
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _MacroTile(label: 'Protein', value: protein, color: _kGreen),
              const SizedBox(height: 7),
              _MacroTile(label: 'Carbs', value: carbs, color: _kBlue),
              const SizedBox(height: 7),
              _MacroTile(label: 'Fat', value: fat, color: _kAmber),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MacroTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kTextSecondary,
          ),
        ),
        const Spacer(),
        Text(
          '${value}g',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}


// ─── Thought Process Card ─────────────────────────────────────────────────────

class _ThoughtProcessCard extends StatelessWidget {
  final String text;
  const _ThoughtProcessCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('AI REASONING'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEF2F7), width: 1),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF475569),
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}

