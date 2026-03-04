/// Result of applying the scaling engine to a food's per-100g nutrition.
class ScaledNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double gramsUsed;

  const ScaledNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.gramsUsed,
  });

  factory ScaledNutrition.fromMap(Map<String, dynamic> map) {
    return ScaledNutrition(
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      gramsUsed: (map['gramsUsed'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'gramsUsed': gramsUsed,
      };

  @override
  String toString() =>
      'ScaledNutrition(cal: ${calories.toStringAsFixed(1)}, p: ${protein.toStringAsFixed(1)}, c: ${carbs.toStringAsFixed(1)}, f: ${fat.toStringAsFixed(1)}, ${gramsUsed.toStringAsFixed(0)}g)';
}
