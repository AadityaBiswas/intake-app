import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/scaled_nutrition.dart';
import '../services/scaling_engine.dart';

/// Result returned when the sheet is closed via Save.
class FoodDetailResult {
  final bool deleted;
  final ScaledNutrition nutrition;

  const FoodDetailResult({
    this.deleted = false,
    required this.nutrition,
  });
}

class FoodDetailSheet extends StatefulWidget {
  final Food food;
  final ScaledNutrition nutrition;
  final DateTime? createdAt;
  final String? thoughtProcess;
  final List<String>? sources;

  const FoodDetailSheet({
    super.key,
    required this.food,
    required this.nutrition,
    this.createdAt,
    this.thoughtProcess,
    this.sources,
  });

  static Future<FoodDetailResult?> show(
    BuildContext context, {
    required Food food,
    required ScaledNutrition nutrition,
    DateTime? createdAt,
    String? thoughtProcess,
    List<String>? sources,
  }) {
    return showModalBottomSheet<FoodDetailResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => FoodDetailSheet(
        food: food,
        nutrition: nutrition,
        createdAt: createdAt,
        thoughtProcess: thoughtProcess,
        sources: sources,
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

    // Smart initialisation: when the food has a preferred unit (e.g. "piece"),
    // display the quantity in that unit rather than raw grams.
    final preferred = widget.food.preferredUnit;
    final gramsPerPreferred = preferred != null
        ? (ScalingEngine.unitToGrams[preferred] ?? widget.food.defaultServingGrams)
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
    const allUnits = ['g', 'ml', 'bowl', 'cup', 'plate', 'piece', 'tbsp', 'tsp', 'slice', 'serving'];
    final curatedUnits = (widget.food.validUnits?.isNotEmpty == true)
        ? widget.food.validUnits!
        : allUnits;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Unit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: curatedUnits.length,
                itemBuilder: (context, index) {
                  final unit = curatedUnits[index];
                  final isSelected = unit == _selectedUnit;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _onUnitChanged(unit);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      color: isSelected ? const Color(0xFFF8FAFC) : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _unitDisplayNames[unit] ?? unit,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: Color(0xFF22C55E), size: 20),
                        ],
                      ),
                    ),
                  );
                },
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle + header (non-scrollable)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 20),
                // Title row — food name + close button
                Row(
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          if (widget.createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              TimeOfDay.fromDateTime(widget.createdAt!)
                                  .format(context),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ],
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
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Macros card
                  _buildMacrosBox(),
                  const SizedBox(height: 16),

                  // Quantity section
                  _buildQuantitySection(),
                  const SizedBox(height: 16),

                  // AI Thought Process
                  if (widget.thoughtProcess != null &&
                      widget.thoughtProcess!.isNotEmpty)
                    _buildThoughtProcessSection(),

                  // Sources
                  if (widget.sources != null && widget.sources!.isNotEmpty)
                    _buildSourcesSection(),

                  // Save button
                  if (_hasChanges) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
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
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Macros Box ───────────────────────────────────────────────────

  Widget _buildMacrosBox() {
    final currentProtein = (_basePer100gProtein * _multiplier).round();
    final currentCarbs = (_basePer100gCarbs * _multiplier).round();
    final currentFat = (_basePer100gFat * _multiplier).round();
    final currentCalories = (_basePer100gCalories * _multiplier).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Protein — big number on left
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PROTEIN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22C55E),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${currentProtein}g',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22C55E),
                  height: 1.1,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Other macros — right aligned
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSmallMacro('Carbs', '${currentCarbs}g'),
              const SizedBox(height: 6),
              _buildSmallMacro('Fats', '${currentFat}g'),
              const SizedBox(height: 6),
              _buildSmallMacro('Calories', '$currentCalories'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMacro(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Quantity Section ─────────────────────────────────────────────

  Widget _buildQuantitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUANTITY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Quantity field
              Expanded(
                flex: 2,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _quantityController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Unit picker
              Expanded(
                flex: 2,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: GestureDetector(
                    onTap: _showUnitPicker,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _unitDisplayNames[_selectedUnit] ?? _selectedUnit,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Icon(Icons.expand_more,
                            color: Color(0xFF94A3B8), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── AI Thought Process ───────────────────────────────────────────

  Widget _buildThoughtProcessSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _ThoughtProcessCard(text: widget.thoughtProcess!),
    );
  }

  // ─── Sources ──────────────────────────────────────────────────────

  Widget _buildSourcesSection() {
    final sources = widget.sources!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SOURCES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sources.length} reference${sources.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB0B8C4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Source list
            ...sources.asMap().entries.map((entry) {
              final isLast = entry.key == sources.length - 1;
              return Column(
                children: [
                  _SourceRow(source: entry.value),
                  if (!isLast)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Thought Process Card (collapsible) ──────────────────────────

class _ThoughtProcessCard extends StatefulWidget {
  final String text;
  const _ThoughtProcessCard({required this.text});

  @override
  State<_ThoughtProcessCard> createState() => _ThoughtProcessCardState();
}

class _ThoughtProcessCardState extends State<_ThoughtProcessCard> {
  bool _expanded = false;

  // Only show collapse toggle if the text is long enough to need it
  static const int _threshold = 160;
  bool get _isLong => widget.text.length > _threshold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI REASONING',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Body text (collapsible)
          AnimatedCrossFade(
            firstChild: Text(
              widget.text,
              maxLines: 4,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                height: 1.55,
              ),
            ),
            secondChild: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                height: 1.55,
              ),
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
          // Toggle button (only when text is long)
          if (_isLong) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded ? 'Show less' : 'Read more',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Source Row ───────────────────────────────────────────────────

class _SourceRow extends StatelessWidget {
  final String source;
  const _SourceRow({required this.source});

  String get _faviconUrl {
    String domain = source.toLowerCase();
    if (domain.contains('usda') || domain.contains('fooddata')) {
      domain = 'fdc.nal.usda.gov';
    } else if (domain.contains('calorieking')) {
      domain = 'calorieking.com';
    } else if (domain.contains('myfitnesspal')) {
      domain = 'myfitnesspal.com';
    } else if (domain.contains('fatsecret')) {
      domain = 'fatsecret.com';
    } else if (domain.contains('nin') || domain.contains('indian food composition')) {
      domain = 'nin.res.in';
    } else {
      final match = RegExp(r'[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').firstMatch(domain);
      domain = match != null ? match.group(0)! : 'example.com';
    }
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              _faviconUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.language_rounded,
                size: 15,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              source,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
