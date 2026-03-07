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

/// Client for the `aiInterpretFood` Cloud Function.
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
  Future<AiFoodResult?> generateFood(String foodName) async {
    try {
      final callable = _functions.httpsCallable('aiInterpretFood');
      final result = await callable.call<Map<String, dynamic>>(
        {'name': foodName.trim()},
      );

      return _parseResponse(result.data);
    } catch (e) {
      // print('[AiFoodService] Cloud Function error: $e');
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
      final defaultServing =
          (data['estimatedDefaultServingGrams'] as num?)?.toDouble();

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
      final thoughtProcess = data['thoughtProcess'] as String? ??
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
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
    return cleaned;
  }
}
