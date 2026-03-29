import 'package:cloud_firestore/cloud_firestore.dart';

/// Nutrition values stored as per-100g canonical format.
class NutritionPer100g {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionPer100g({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionPer100g.fromMap(Map<String, dynamic> map) {
    return NutritionPer100g(
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  @override
  String toString() =>
      'NutritionPer100g(cal: $calories, p: $protein, c: $carbs, f: $fat)';
}

/// A food item stored in the `foods` Firestore collection.
///
/// Uses `nutrition_per_100g` as the canonical nutrition format.
/// Supports dual-read from both old schema (flat macros) and new schema.
class Food {
  final String id;
  final String name;
  final String nameLowercase;
  final List<String> searchKeywords;
  final List<String> aliases;
  final NutritionPer100g nutritionPer100g;
  final double defaultServingGrams;
  final String source; // "usda" | "ai" | "manual"
  final double? credibilityScore; // AI-generated foods only (0.0–1.0)
  final DateTime? createdAt;
  final String? preferredUnit; // Natural counting unit: "piece", "g", "ml", etc.
  final List<String>? validUnits; // Units that make sense for this food
  final bool hasBeenRecalculated; // true after AI recalculation (blocks further recalcs)

  const Food({
    required this.id,
    required this.name,
    required this.nameLowercase,
    required this.searchKeywords,
    this.aliases = const [],
    required this.nutritionPer100g,
    this.defaultServingGrams = 100,
    this.source = 'manual',
    this.credibilityScore,
    this.createdAt,
    this.preferredUnit,
    this.validUnits,
    this.hasBeenRecalculated = false,
  });

  /// Dual-read factory: supports both new schema (`nutrition_per_100g` map)
  /// and old schema (flat `calories`, `protein`, `carbs`, `fat` fields).
  factory Food.fromFirestore(Map<String, dynamic> data, String id) {
    NutritionPer100g nutrition;

    if (data['nutrition_per_100g'] is Map) {
      // New schema
      nutrition = NutritionPer100g.fromMap(
        Map<String, dynamic>.from(data['nutrition_per_100g'] as Map),
      );
    } else {
      // Old schema — flat macros treated as per-100g
      nutrition = NutritionPer100g(
        calories: (data['calories'] as num?)?.toDouble() ?? 0,
        protein: (data['protein'] as num?)?.toDouble() ?? 0,
        carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
        fat: (data['fat'] as num?)?.toDouble() ?? 0,
      );
    }

    // Support both old field names and new field names
    final nameLower = data['name_lowercase'] as String? ??
        data['searchName'] as String? ??
        (data['name'] as String? ?? '').toLowerCase();

    final keywords = data['search_keywords'] is List
        ? List<String>.from(data['search_keywords'] as List)
        : data['tokens'] is List
            ? List<String>.from(data['tokens'] as List)
            : <String>[];

    return Food(
      id: id,
      name: data['name'] as String? ?? '',
      nameLowercase: nameLower,
      searchKeywords: keywords,
      aliases: data['aliases'] is List
          ? List<String>.from(data['aliases'] as List)
          : <String>[],
      nutritionPer100g: nutrition,
      defaultServingGrams:
          (data['defaultServingGrams'] as num?)?.toDouble() ?? 100,
      source: data['source'] as String? ?? 'manual',
      credibilityScore: (data['credibilityScore'] as num?)?.toDouble() ??
          (data['confidence'] as num?)?.toDouble(),
      createdAt: data['created_at'] is Timestamp
          ? (data['created_at'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'].toString())
              : null,
      preferredUnit: data['preferredUnit'] as String?,
      validUnits: data['validUnits'] is List
          ? List<String>.from(data['validUnits'] as List)
          : null,
      hasBeenRecalculated: data['hasBeenRecalculated'] == true,
    );
  }

  /// Serializes to the new Firestore schema.
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'name': name,
      'name_lowercase': nameLowercase,
      'search_keywords': searchKeywords,
      'aliases': aliases,
      'nutrition_per_100g': nutritionPer100g.toMap(),
      'defaultServingGrams': defaultServingGrams,
      'source': source,
      'credibilityScore': credibilityScore,
      'created_at': FieldValue.serverTimestamp(),
    };
    if (preferredUnit != null) map['preferredUnit'] = preferredUnit;
    if (validUnits != null && validUnits!.isNotEmpty) map['validUnits'] = validUnits;
    if (hasBeenRecalculated) map['hasBeenRecalculated'] = true;
    return map;
  }

  Food copyWith({
    String? id,
    String? name,
    String? nameLowercase,
    List<String>? searchKeywords,
    List<String>? aliases,
    NutritionPer100g? nutritionPer100g,
    double? defaultServingGrams,
    String? source,
    double? credibilityScore,
    DateTime? createdAt,
    String? preferredUnit,
    List<String>? validUnits,
    bool? hasBeenRecalculated,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLowercase: nameLowercase ?? this.nameLowercase,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      aliases: aliases ?? this.aliases,
      nutritionPer100g: nutritionPer100g ?? this.nutritionPer100g,
      defaultServingGrams: defaultServingGrams ?? this.defaultServingGrams,
      source: source ?? this.source,
      credibilityScore: credibilityScore ?? this.credibilityScore,
      createdAt: createdAt ?? this.createdAt,
      preferredUnit: preferredUnit ?? this.preferredUnit,
      validUnits: validUnits ?? this.validUnits,
      hasBeenRecalculated: hasBeenRecalculated ?? this.hasBeenRecalculated,
    );
  }

  @override
  String toString() =>
      'Food(id: $id, name: "$name", source: $source, $nutritionPer100g)';
}
