/// Evidence-based macro calculation engine.
///
/// Uses Mifflin-St Jeor BMR, activity multipliers,
/// goal-based calorie adjustments, dynamic protein per kg,
/// percentage-based fat, and remainder carbs.
class MacroCalculator {
  MacroCalculator._();

  /// Full calculation result with intermediate values for transparency.
  static MacroResult calculate({
    required String gender,
    required int age,
    required double weightKg,
    required double heightCm,
    required String activityLevel,
    required String weightGoal,
  }) {
    // ── Step 1: BMR (Mifflin-St Jeor) ──
    final double bmr;
    if (gender.toLowerCase() == 'female') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    } else {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    }

    // ── Step 2: Maintenance calories ──
    final double activityMultiplier;
    switch (activityLevel) {
      case 'Lightly Active':
        activityMultiplier = 1.375;
      case 'Moderately Active':
        activityMultiplier = 1.55;
      case 'Very Active':
        activityMultiplier = 1.725;
      default: // Sedentary
        activityMultiplier = 1.2;
    }
    final double maintenance = bmr * activityMultiplier;

    // ── Step 3: Calorie adjustment ──
    final double calorieAdjustment;
    final String goalNormalized = _normalizeGoal(weightGoal);
    switch (goalNormalized) {
      case 'lose':
        calorieAdjustment = -300;
      case 'lean_bulk':
        calorieAdjustment = 250;
      case 'aggressive_bulk':
        calorieAdjustment = 450;
      default: // maintain
        calorieAdjustment = 0;
    }
    final double targetCalories =
        (maintenance + calorieAdjustment).clamp(1200, 5000);

    // ── Step 4: Dynamic protein (g/kg bodyweight) ──
    final double proteinMultiplier;
    switch (goalNormalized) {
      case 'lose':
        proteinMultiplier = 2.2;
      case 'lean_bulk':
        proteinMultiplier = 2.0;
      case 'aggressive_bulk':
        proteinMultiplier = 1.9;
      default: // maintain
        proteinMultiplier = 1.8;
    }
    final double proteinGrams = weightKg * proteinMultiplier;
    final double proteinCalories = proteinGrams * 4;

    // ── Step 5: Fat allocation (% of total calories) ──
    final double fatPercent;
    switch (goalNormalized) {
      case 'lose':
        fatPercent = 0.28;
      case 'lean_bulk':
        fatPercent = 0.25;
      case 'aggressive_bulk':
        fatPercent = 0.23;
      default: // maintain
        fatPercent = 0.27;
    }
    final double fatCalories = targetCalories * fatPercent;
    final double fatGrams = fatCalories / 9;

    // ── Step 6: Carbohydrates (remainder) ──
    final double carbCalories = targetCalories - proteinCalories - fatCalories;
    final double carbGrams =
        carbCalories > 0 ? carbCalories / 4 : 0;

    return MacroResult(
      bmr: bmr,
      activityMultiplier: activityMultiplier,
      maintenance: maintenance,
      calorieAdjustment: calorieAdjustment,
      targetCalories: targetCalories.round(),
      proteinGrams: proteinGrams.round(),
      carbGrams: carbGrams.round(),
      fatGrams: fatGrams.round(),
    );
  }

  /// Normalize free-form goal strings to internal keys.
  static String _normalizeGoal(String goal) {
    final g = goal.toLowerCase().trim();
    if (g.contains('lose')) return 'lose';
    if (g.contains('aggressive') || g.contains('bulk') && g.contains('aggr')) {
      return 'aggressive_bulk';
    }
    if (g.contains('lean') || g.contains('gain')) return 'lean_bulk';
    return 'maintain';
  }
}

/// Immutable result of a macro calculation.
class MacroResult {
  final double bmr;
  final double activityMultiplier;
  final double maintenance;
  final double calorieAdjustment;
  final int targetCalories;
  final int proteinGrams;
  final int carbGrams;
  final int fatGrams;

  const MacroResult({
    required this.bmr,
    required this.activityMultiplier,
    required this.maintenance,
    required this.calorieAdjustment,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
  });
}
