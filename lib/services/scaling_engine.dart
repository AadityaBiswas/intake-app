import '../models/food.dart';
import '../models/scaled_nutrition.dart';

/// Deterministic macro scaling engine.
///
/// All stored foods use `nutrition_per_100g` as canonical format.
/// Formula: `scaledValue = (nutrition_per_100g / 100) * requestedGrams`
class ScalingEngine {
  ScalingEngine._();

  /// Known unit-to-grams approximations.
  static const Map<String, double> unitToGrams = {
    'g': 1.0,
    'gm': 1.0,
    'gram': 1.0,
    'grams': 1.0,
    'ml': 1.0, // approximate 1ml ≈ 1g for most liquids
    'cup': 240.0,
    'glass': 250.0,
    'bowl': 250.0,
    'katori': 150.0,
    'plate': 300.0,
    'tbsp': 15.0,
    'tsp': 5.0,
    'slice': 30.0,
    'piece': 50.0, // generic default; food-specific override preferred
    'serving': 100.0,
    'scoop': 30.0,
  };

  /// Scales nutrition from per-100g values to the requested amount.
  ///
  /// Priority for determining grams:
  /// 1. If [quantity] and [unit] are both provided, use `quantity * unitToGrams[unit]`
  /// 2. If only [quantity] is provided (no unit), use `quantity * defaultServingGrams`
  /// 3. If neither is provided, use [defaultServingGrams]
  static ScaledNutrition scale(
    NutritionPer100g per100g, {
    double? quantity,
    String? unit,
    required double defaultServingGrams,
  }) {
    double grams;

    if (quantity != null && unit != null) {
      final gramsPerUnit =
          unitToGrams[unit.toLowerCase()] ?? defaultServingGrams;
      grams = quantity * gramsPerUnit;
    } else if (quantity != null) {
      grams = quantity * defaultServingGrams;
    } else {
      grams = defaultServingGrams;
    }

    final factor = grams / 100.0;

    return ScaledNutrition(
      calories: per100g.calories * factor,
      protein: per100g.protein * factor,
      carbs: per100g.carbs * factor,
      fat: per100g.fat * factor,
      gramsUsed: grams,
    );
  }
}
