/// Evidence-based macro calculation engine.
///
/// Uses Mifflin-St Jeor BMR, activity multipliers,
/// goal-based calorie adjustments with intensity support,
/// dynamic protein per kg, percentage-based fat, and remainder carbs.
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
    String goalIntensity = '', // 'Mild', 'Moderate', 'Aggressive'
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
      case 'Athlete':
        activityMultiplier = 1.9;
      default: // Sedentary
        activityMultiplier = 1.2;
    }
    final double maintenance = bmr * activityMultiplier;

    // ── Step 3: Calorie adjustment (now intensity-aware) ──
    final double calorieAdjustment = _getCalorieAdjustment(
      weightGoal,
      goalIntensity,
    );
    final double targetCalories = (maintenance + calorieAdjustment).clamp(
      1200,
      5000,
    );

    // ── Step 4: Dynamic protein (g/kg bodyweight) ──
    final double proteinMultiplier = _getProteinMultiplier(
      weightGoal,
      goalIntensity,
    );
    final double proteinGrams = weightKg * proteinMultiplier;
    final double proteinCalories = proteinGrams * 4;

    // ── Step 5: Fat allocation (% of total calories) ──
    final double fatPercent = _getFatPercent(weightGoal, goalIntensity);
    final double fatCalories = targetCalories * fatPercent;
    final double fatGrams = fatCalories / 9;

    // ── Step 6: Carbohydrates (remainder) ──
    final double carbCalories = targetCalories - proteinCalories - fatCalories;
    final double carbGrams = carbCalories > 0 ? carbCalories / 4 : 0;

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

  /// BMI calculation
  static double calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Calorie adjustment based on goal + intensity
  static double _getCalorieAdjustment(String goal, String intensity) {
    final g = goal.toLowerCase();
    final i = intensity.toLowerCase();

    if (g.contains('loss') || g.contains('lose')) {
      switch (i) {
        case 'mild':
          return -250;
        case 'moderate':
          return -400;
        case 'aggressive':
          return -600;
        default:
          return -300; // default moderate deficit
      }
    } else if (g.contains('gain')) {
      switch (i) {
        case 'mild':
          return 200;
        case 'moderate':
          return 350;
        case 'aggressive':
          return 500;
        default:
          return 250; // default lean bulk
      }
    }
    return 0; // maintenance
  }

  /// Protein multiplier based on goal + intensity
  static double _getProteinMultiplier(String goal, String intensity) {
    final g = goal.toLowerCase();
    final i = intensity.toLowerCase();

    if (g.contains('loss') || g.contains('lose')) {
      switch (i) {
        case 'mild':
          return 2.0;
        case 'moderate':
          return 2.2;
        case 'aggressive':
          return 2.4;
        default:
          return 2.2;
      }
    } else if (g.contains('gain')) {
      switch (i) {
        case 'mild':
          return 1.8;
        case 'moderate':
          return 2.0;
        case 'aggressive':
          return 2.2;
        default:
          return 2.0;
      }
    }
    return 1.8; // maintenance
  }

  /// Fat percentage based on goal + intensity
  static double _getFatPercent(String goal, String intensity) {
    final g = goal.toLowerCase();
    final i = intensity.toLowerCase();

    if (g.contains('loss') || g.contains('lose')) {
      switch (i) {
        case 'mild':
          return 0.30;
        case 'moderate':
          return 0.27;
        case 'aggressive':
          return 0.24;
        default:
          return 0.28;
      }
    } else if (g.contains('gain')) {
      switch (i) {
        case 'mild':
          return 0.27;
        case 'moderate':
          return 0.25;
        case 'aggressive':
          return 0.22;
        default:
          return 0.25;
      }
    }
    return 0.27; // maintenance
  }

  /// Calculate estimated days given current and target weight
  static int estimateDaysWithTarget({
    required double currentKg,
    required double targetKg,
    required String goal,
    required String intensity,
  }) {
    final diff = (currentKg - targetKg).abs();
    if (diff < 0.5) return 7; // already close

    double ratePerWeek;
    switch (intensity.toLowerCase()) {
      case 'mild':
        ratePerWeek = 0.25;
      case 'moderate':
        ratePerWeek = 0.5;
      case 'aggressive':
        ratePerWeek = 0.75;
      default:
        ratePerWeek = 0.5;
    }

    final weeks = diff / ratePerWeek;
    return (weeks * 7).round().clamp(7, 730);
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
  final int? estimatedDays;

  const MacroResult({
    required this.bmr,
    required this.activityMultiplier,
    required this.maintenance,
    required this.calorieAdjustment,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    this.estimatedDays,
  });
}
