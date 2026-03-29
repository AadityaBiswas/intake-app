import 'package:cloud_functions/cloud_functions.dart';
import '../models/food.dart';

/// Minimum confidence score to accept AI-generated nutrition.
/// Below this threshold, the result is rejected and the food falls back
/// to the "custom food" flow.
const double kAiConfidenceThreshold = 0.6;

/// AI-generated food with metadata about reasoning and sources.
class AiFoodResult {
  final Food food;
  final String thoughtProcess;
  final List<String> sources;

  const AiFoodResult({
    required this.food,
    required this.thoughtProcess,
    required this.sources,
  });
}

/// Result of AI refinement when a DB/USDA reference is passed.
class RefinedFoodResult {
  /// If true, the reference food is accurate — use it as-is (verified).
  final bool referenceAccepted;

  /// The food to use (either the original reference or AI-modified version).
  final Food food;

  /// AI thought process explaining the decision.
  final String thoughtProcess;

  /// Sources used by the AI.
  final List<String> sources;

  const RefinedFoodResult({
    required this.referenceAccepted,
    required this.food,
    required this.thoughtProcess,
    required this.sources,
  });
}

/// Client for the `aiInterpretFood` and `aiRefineFood` Cloud Functions.
///
/// Calls Gemini (server-side) to generate canonical nutrition per 100g
/// for foods not found in Firestore or USDA.
///
/// Rules:
/// - Never called during typing (suggestion stage)
/// - Never called for quantity-only changes
/// - Only one call per unique food
/// - Result must pass confidence threshold to be stored
class AiFoodService {
  final FirebaseFunctions _functions;

  AiFoodService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  /// Calls the Cloud Function to generate nutrition for [foodName].
  ///
  /// Returns an [AiFoodResult] if AI succeeds and confidence ≥ [kAiConfidenceThreshold].
  /// Returns `null` if:
  /// - AI call fails
  /// - Response validation fails
  /// - Confidence is below threshold
  Future<AiFoodResult?> generateFood(
    String foodName, {
    String? location,
    bool isRecalculation = false,
  }) async {
    try {
      final callable = _functions.httpsCallable('aiInterpretFood');

      final payload = <String, dynamic>{'name': foodName.trim()};
      if (location != null && location.isNotEmpty) {
        payload['location'] = location;
      }
      if (isRecalculation) {
        payload['isRecalculation'] = true;
      }

      final result = await callable.call<Map<String, dynamic>>(payload);

      return _parseResponse(result.data);
    } catch (e) {
      // print('[AiFoodService] Cloud Function error: $e');
      return null;
    }
  }

  /// Calls the `aiRefineFood` Cloud Function to validate a DB/USDA reference
  /// against the user's typed food name.
  ///
  /// The AI decides whether the reference food is the correct match, or if
  /// the user meant something different (e.g. a restaurant-specific version).
  ///
  /// Returns a [RefinedFoodResult] indicating whether to use the reference as-is
  /// or to use the AI-modified version.
  Future<RefinedFoodResult?> refineWithReference({
    required String userTypedName,
    required Food referenceFood,
    required String referenceSource, // "firestore" | "usda"
    String? location,
  }) async {
    try {
      final callable = _functions.httpsCallable('aiRefineFood');

      final payload = <String, dynamic>{
        'userQuery': userTypedName.trim(),
        'referenceName': referenceFood.name,
        'referenceSource': referenceSource,
        'referenceNutrition': {
          'calories': referenceFood.nutritionPer100g.calories,
          'protein': referenceFood.nutritionPer100g.protein,
          'carbs': referenceFood.nutritionPer100g.carbs,
          'fat': referenceFood.nutritionPer100g.fat,
        },
        'referenceServingGrams': referenceFood.defaultServingGrams,
      };
      if (location != null && location.isNotEmpty) {
        payload['location'] = location;
      }

      final result = await callable.call<Map<String, dynamic>>(payload);
      return _parseRefinedResponse(result.data, referenceFood);
    } catch (e) {
      // On failure, accept the reference as-is — safer fallback
      return RefinedFoodResult(
        referenceAccepted: true,
        food: referenceFood,
        thoughtProcess: 'Reference accepted (AI refinement unavailable).',
        sources: [referenceSource.toUpperCase()],
      );
    }
  }

  /// Parses the response from `aiRefineFood`.
  RefinedFoodResult? _parseRefinedResponse(
    Map<String, dynamic> data,
    Food referenceFood,
  ) {
    try {
      final accepted = data['referenceAccepted'] == true;
      final thoughtProcess =
          data['thoughtProcess'] as String? ??
          'Reference validation completed.';
      final rawSources = data['sources'];
      final sources = rawSources is List
          ? rawSources
                .map((s) => s.toString())
                .where((s) => s.isNotEmpty)
                .toList()
          : <String>['AI validation'];

      if (accepted) {
        // Reference is accurate — use the DB/USDA food as-is
        return RefinedFoodResult(
          referenceAccepted: true,
          food: referenceFood,
          thoughtProcess: thoughtProcess,
          sources: sources,
        );
      }

      // AI suggests a modification — parse the corrected food
      final name = data['name'] as String?;
      final rawNutrition = data['nutrition_per_100g'];
      final nutritionMap = rawNutrition is Map
          ? Map<String, dynamic>.from(rawNutrition)
          : null;
      final confidence = (data['confidence'] as num?)?.toDouble();
      final defaultServing = (data['estimatedDefaultServingGrams'] as num?)
          ?.toDouble();

      if (name == null || name.isEmpty) return null;
      if (nutritionMap == null) return null;
      if (confidence == null || confidence < kAiConfidenceThreshold) {
        return null;
      }

      final calories = (nutritionMap['calories'] as num?)?.toDouble();
      final protein = (nutritionMap['protein'] as num?)?.toDouble();
      final carbs = (nutritionMap['carbs'] as num?)?.toDouble();
      final fat = (nutritionMap['fat'] as num?)?.toDouble();

      if (calories == null || protein == null || carbs == null || fat == null) {
        return null;
      }

      final normalizedName = _normalizeName(name);
      final nameLower = normalizedName.toLowerCase();
      final keywords = nameLower
          .replaceAll(RegExp(r'[,.\-()]+'), ' ')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      // Parse optional unit metadata
      final defaultUnit = data['defaultUnit'] as String?;
      final rawValidUnits = data['validUnits'];
      final validUnits = rawValidUnits is List
          ? rawValidUnits
                .map((u) => u.toString())
                .where((u) => u.isNotEmpty)
                .toList()
          : null;

      final modifiedFood = Food(
        id: '',
        name: normalizedName,
        nameLowercase: nameLower,
        searchKeywords: keywords,
        nutritionPer100g: NutritionPer100g(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        ),
        defaultServingGrams: defaultServing ?? 100,
        source: 'ai',
        credibilityScore: confidence,
        preferredUnit: defaultUnit,
        validUnits: validUnits,
      );

      return RefinedFoodResult(
        referenceAccepted: false,
        food: modifiedFood,
        thoughtProcess: thoughtProcess,
        sources: sources,
      );
    } catch (e) {
      return null;
    }
  }

  /// Parses and validates the Cloud Function response.
  AiFoodResult? _parseResponse(Map<String, dynamic> data) {
    try {
      // Validate required fields
      final name = data['name'] as String?;
      // Cloud Functions returns Map<Object?, Object?> for nested maps
      final rawNutrition = data['nutrition_per_100g'];
      final nutritionMap = rawNutrition is Map
          ? Map<String, dynamic>.from(rawNutrition)
          : null;
      final confidence = (data['confidence'] as num?)?.toDouble();
      final defaultServing = (data['estimatedDefaultServingGrams'] as num?)
          ?.toDouble();

      if (name == null || name.isEmpty) return null;
      if (nutritionMap == null) return null;
      if (confidence == null) return null;

      // Confidence gate
      if (confidence < kAiConfidenceThreshold) {
        return null;
      }

      final calories = (nutritionMap['calories'] as num?)?.toDouble();
      final protein = (nutritionMap['protein'] as num?)?.toDouble();
      final carbs = (nutritionMap['carbs'] as num?)?.toDouble();
      final fat = (nutritionMap['fat'] as num?)?.toDouble();

      if (calories == null || protein == null || carbs == null || fat == null) {
        return null;
      }

      // Normalize name
      final normalizedName = _normalizeName(name);

      final nameLower = normalizedName.toLowerCase();
      final keywords = nameLower
          .replaceAll(RegExp(r'[,.\-()]+'), ' ')
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      // Parse thought process and sources
      final thoughtProcess =
          data['thoughtProcess'] as String? ??
          'Nutritional data estimated based on standard food databases.';
      final rawSources = data['sources'];
      final sources = rawSources is List
          ? rawSources
                .map((s) => s.toString())
                .where((s) => s.isNotEmpty)
                .toList()
          : <String>['AI estimation'];

      // Parse optional unit metadata returned by the Cloud Function
      final defaultUnit = data['defaultUnit'] as String?;
      final rawValidUnits = data['validUnits'];
      final validUnits = rawValidUnits is List
          ? rawValidUnits
                .map((u) => u.toString())
                .where((u) => u.isNotEmpty)
                .toList()
          : null;

      final food = Food(
        id: '',
        name: normalizedName,
        nameLowercase: nameLower,
        searchKeywords: keywords,
        nutritionPer100g: NutritionPer100g(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        ),
        defaultServingGrams: defaultServing ?? 100,
        source: 'ai',
        credibilityScore: confidence,
        preferredUnit: defaultUnit,
        validUnits: validUnits,
      );

      return AiFoodResult(
        food: food,
        thoughtProcess: thoughtProcess,
        sources: sources,
      );
    } catch (e) {
      // print('[AiFoodService] Parse error: $e');
      return null;
    }
  }

  /// Normalizes a food name:
  /// - Lowercase
  /// - Collapse whitespace
  /// - Remove leading/trailing punctuation
  /// - Title-case for display
  String _normalizeName(String raw) {
    var cleaned = raw.trim();
    // Remove leading/trailing quotes and punctuation
    cleaned = cleaned.replaceAll(RegExp(r'^["\s]+|["\s]+$'), '');
    // Collapse multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    // Title case: "paneer butter masala" → "Paneer Butter Masala"
    cleaned = cleaned
        .split(' ')
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
    return cleaned;
  }
}
