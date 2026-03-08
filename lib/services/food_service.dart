import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import '../models/food.dart';
import '../models/scaled_nutrition.dart';
import 'ai_food_service.dart';
import 'input_parser.dart';
import 'scaling_engine.dart';

/// Result of the bidirectional relevance check.
enum _RelevanceResult { match, reject, ambiguous }

/// Result from the resolution pipeline.
class ResolvedFood {
  final Food food;
  final ScaledNutrition nutrition;
  final String source; // "firestore" | "usda" | "ai"
  final String userTypedName;
  final String? thoughtProcess;
  final List<String>? sources;

  const ResolvedFood({
    required this.food,
    required this.nutrition,
    required this.source,
    required this.userTypedName,
    this.thoughtProcess,
    this.sources,
  });
}

/// Core food service handling suggestions, resolution, and scaling.
///
/// Replaces the old `FoodRepository` with clean separation:
/// - [suggestFoods]: lightweight prefix search (typing stage)
/// - [resolveFood]: full pipeline with USDA fallback (Enter stage)
class FoodService {
  final FirebaseFirestore _firestore;
  final AiFoodService _aiService;

  static const String _usdaApiKey = '0qznubAbkFgohJaDwIp55QMPTNQDaX9jLKVeEtdn';
  static const String _usdaBaseUrl =
      'https://api.nal.usda.gov/fdc/v1/foods/search';

  /// Callback to report resolution progress to the UI.
  final void Function(String stage)? onProgressUpdate;

  FoodService({
    FirebaseFirestore? firestore,
    AiFoodService? aiService,
    this.onProgressUpdate,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _aiService = aiService ?? AiFoodService();

  // ─── Suggestion Engine (Typing Stage) ─────────────────────────────

  /// Returns up to 5 food suggestions matching the prefix.
  ///
  /// - Extracts only foodName (ignores quantity/unit)
  /// - Prefix match on `name_lowercase`
  /// - Read-only: no writes, no USDA, no AI
  Future<List<Food>> suggestFoods(String rawInput) async {
    final foodName = InputParser.extractFoodName(rawInput);
    if (foodName.trim().isEmpty) return [];

    final prefix = foodName.toLowerCase().trim();

    try {
      final verifiedSnap = await _firestore
          .collection('verified_foods')
          .where('name_lowercase', isGreaterThanOrEqualTo: prefix)
          .where('name_lowercase', isLessThan: '$prefix\uf8ff')
          .limit(5)
          .get();

      final verifiedFoods = verifiedSnap.docs
          .map((doc) => Food.fromFirestore(doc.data(), doc.id))
          .toList();

      if (verifiedFoods.length >= 5) return verifiedFoods;

      final unverifiedSnap = await _firestore
          .collection('unverified_foods')
          .where('name_lowercase', isGreaterThanOrEqualTo: prefix)
          .where('name_lowercase', isLessThan: '$prefix\uf8ff')
          .limit(5 - verifiedFoods.length)
          .get();

      final unverifiedFoods = unverifiedSnap.docs
          .map((doc) => Food.fromFirestore(doc.data(), doc.id))
          .toList();

      return [...verifiedFoods, ...unverifiedFoods];
    } catch (e) {
      return [];
    }
  }

  // ─── Resolution Engine (Enter Stage) ──────────────────────────────

  /// Full resolution pipeline. Only called when user presses Enter.
  ///
  /// 1. Parse raw input into structured format
  /// 2. Exact Firestore match on `name_lowercase`
  /// 3. USDA fallback (with re-check guard)
  /// 4. Scale nutrition to requested quantity
  Future<ResolvedFood?> resolveFood(String rawInput) async {
    final parsed = InputParser.parse(rawInput);
    if (parsed.foodName.isEmpty) return null;

    // Step 1: Exact Firestore match
    onProgressUpdate?.call('Searching database...');
    final firestoreFood = await _findExact(parsed.foodName);
    if (firestoreFood != null) {
      _appendAliasToFood(firestoreFood, parsed.foodName);

      final nutrition = ScalingEngine.scale(
        firestoreFood.nutritionPer100g,
        quantity: parsed.quantity,
        unit: _resolveUnit(parsed.unit, firestoreFood),
        defaultServingGrams: firestoreFood.defaultServingGrams,
      );
      return ResolvedFood(
        food: firestoreFood,
        nutrition: nutrition,
        source: 'firestore',
        userTypedName: parsed.foodName,
      );
    }

    // Step 2: USDA fallback
    onProgressUpdate?.call('Searching database...');
    final usdaFood = await _searchAndStoreUSDA(parsed.foodName);
    if (usdaFood != null) {
      _appendAliasToFood(usdaFood, parsed.foodName);

      final nutrition = ScalingEngine.scale(
        usdaFood.nutritionPer100g,
        quantity: parsed.quantity,
        unit: _resolveUnit(parsed.unit, usdaFood),
        defaultServingGrams: usdaFood.defaultServingGrams,
      );
      return ResolvedFood(
        food: usdaFood,
        nutrition: nutrition,
        source: 'usda',
        userTypedName: parsed.foodName,
      );
    }

    // Step 3: AI fallback with web search
    onProgressUpdate?.call('Searching the web...');
    final aiResult = await _aiService.generateFood(parsed.foodName);
    if (aiResult != null) {
      // Race condition guard: re-check Firestore before writing
      final existing = await _findExact(aiResult.food.nameLowercase);
      if (existing != null) {
        _appendAliasToFood(existing, parsed.foodName);

        final nutrition = ScalingEngine.scale(
          existing.nutritionPer100g,
          quantity: parsed.quantity,
          unit: _resolveUnit(parsed.unit, existing),
          defaultServingGrams: existing.defaultServingGrams,
        );
        return ResolvedFood(
          food: existing,
          nutrition: nutrition,
          source: 'firestore',
          userTypedName: parsed.foodName,
        );
      }

      final storedFood = await _storeDeterministic(aiResult.food);
      _appendAliasToFood(storedFood, parsed.foodName);

      final nutrition = ScalingEngine.scale(
        storedFood.nutritionPer100g,
        quantity: parsed.quantity,
        unit: _resolveUnit(parsed.unit, storedFood),
        defaultServingGrams: storedFood.defaultServingGrams,
      );
      return ResolvedFood(
        food: storedFood,
        nutrition: nutrition,
        source: 'ai',
        userTypedName: parsed.foodName,
        thoughtProcess: aiResult.thoughtProcess,
        sources: aiResult.sources,
      );
    }

    return null;
  }

  // ─── Firestore Exact Match ────────────────────────────────────────

  Future<Food?> _findExact(String foodName) async {
    final cleanName = foodName.toLowerCase().trim();
    if (cleanName.isEmpty) return null;

    try {
      // Check verified collection first
      final verifiedSnap = await _firestore
          .collection('verified_foods')
          .where('name_lowercase', isEqualTo: cleanName)
          .limit(1)
          .get();

      if (verifiedSnap.docs.isNotEmpty) {
        final doc = verifiedSnap.docs.first;
        return Food.fromFirestore(doc.data(), doc.id);
      }

      // Check unverified collection next
      final unverifiedSnap = await _firestore
          .collection('unverified_foods')
          .where('name_lowercase', isEqualTo: cleanName)
          .limit(1)
          .get();

      if (unverifiedSnap.docs.isNotEmpty) {
        final doc = unverifiedSnap.docs.first;
        return Food.fromFirestore(doc.data(), doc.id);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── USDA Search + Store ──────────────────────────────────────────

  Future<Food?> _searchAndStoreUSDA(String foodName) async {
    try {
      final uri = Uri.parse(_usdaBaseUrl).replace(queryParameters: {
        'api_key': _usdaApiKey,
        'query': foodName,
        'pageSize': '5',
        'dataType': 'Foundation,SR Legacy',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      final foods = data['foods'] as List?;
      if (foods == null || foods.isEmpty) return null;

      // Find first relevant result
      for (final item in foods) {
        final description = (item['description'] as String? ?? '').trim();
        if (description.isEmpty) continue;

        final relevance = _checkRelevance(foodName, description);
        if (relevance == _RelevanceResult.reject) continue;

        // If ambiguous, ask AI to compare
        if (relevance == _RelevanceResult.ambiguous) {
          final isSame = await _aiCompareFood(foodName, description);
          if (!isSame) continue; // skip this result, try next
        }

        final nutrition = _extractNutrition(item as Map<String, dynamic>);

        final nameLower = description.toLowerCase();
        final keywords = nameLower
            .replaceAll(RegExp(r'[,.\-()]+'), ' ')
            .split(RegExp(r'\s+'))
            .where((t) => t.isNotEmpty)
            .toList();

        final food = Food(
          id: '',
          name: description,
          nameLowercase: nameLower,
          searchKeywords: keywords,
          nutritionPer100g: nutrition,
          defaultServingGrams: 100,
          source: 'usda',
        );

        // Race condition guard: re-check Firestore before writing
        final existing = await _findExact(nameLower);
        if (existing != null) {
          return existing;
        }

        // Write via transaction to prevent duplicates
        return await _storeDeterministic(food);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// USDA descriptor tokens that are never counted as "extra food tokens"
  /// when performing the bidirectional relevance check below.
  static const Set<String> _usdaModifiers = {
    // Cooking methods
    'raw', 'cooked', 'grilled', 'baked', 'boiled', 'steamed', 'roasted',
    'fried', 'smoked', 'dried', 'canned', 'frozen', 'dehydrated', 'pickled',
    'heated', 'breaded', 'seasoned', 'flavored',
    // Quality
    'organic', 'natural', 'pure', 'enriched', 'unenriched', 'fortified',
    'plain', 'regular', 'instant',
    // Fat level
    'lean', 'nonfat', 'light', 'whole', 'skim',
    // Grain / colour
    'white', 'brown', 'wild', 'grain', 'long', 'short', 'medium',
    // Processing
    'ground', 'sliced', 'diced', 'chopped', 'minced', 'pureed', 'mashed',
    'shredded', 'grated', 'peeled', 'skinless', 'boneless', 'trimmed',
    'flaked', 'rolled', 'powdered',
    // Animal qualifiers
    'broiler', 'fryer', 'roaster', 'fryers', 'hen', 'capon',
    // Body-part / portion words
    'meat', 'skin', 'bone', 'flesh', 'only',
    // Texture
    'smooth', 'chunky', 'creamy', 'crispy', 'crunchy', 'thick', 'thin',
    // Filler / function words
    'with', 'without', 'and', 'or', 'of', 'in', 'no', 'not', 'added',
    'salt', 'the', 'a', 'an', 'ns', 'nfs', 'type', 'style', 'form',
    'grade', 'salted', 'unsalted', 'sweetened', 'unsweetened', 'fresh',
    'large', 'small', 'extra', 'mini', 'jumbo',
  };

  /// Bidirectional relevance check for USDA results.
  ///
  /// **Forward**: every query token must appear in the description.
  /// **Reverse**: the description must not contain extra *food-type* tokens
  /// beyond what the query covers. Modifier words (cooking methods, colours,
  /// etc.) are on an allowlist and never count as extra food tokens.
  ///
  /// Tolerance: `maxExtra = (queryTokenLength - 1).clamp(0, 2)` so that
  /// single-word queries allow 0 extra food tokens and multi-word queries
  /// allow a small number of USDA-style qualifiers.
  _RelevanceResult _checkRelevance(String query, String description) {
    final queryTokens = query
        .toLowerCase()
        .split(RegExp(r'[\s,.\-()/]+'))
        .where((t) => t.length > 1)
        .toSet();
    if (queryTokens.isEmpty) return _RelevanceResult.reject;

    final descTokens = description
        .toLowerCase()
        .split(RegExp(r'[\s,.\-()/]+'))
        .where((t) => t.isNotEmpty)
        .toSet();

    // Forward check: every query token must appear in the description
    if (!queryTokens.every((t) => descTokens.contains(t))) {
      return _RelevanceResult.reject;
    }

    // Reverse check: count description tokens that are neither in the query
    // nor in the modifier allowlist — these are genuine "extra food words"
    final extraFoodTokens = descTokens
        .where((t) =>
            t.length > 1 &&
            !queryTokens.contains(t) &&
            !_usdaModifiers.contains(t))
        .toSet();

    if (extraFoodTokens.isEmpty) return _RelevanceResult.match;

    // Any unknown extra tokens → ambiguous, needs AI verification
    return _RelevanceResult.ambiguous;
  }

  /// Calls the `aiCompareFood` Cloud Function to determine if a USDA
  /// food description matches the user's intended food.
  Future<bool> _aiCompareFood(String userQuery, String usdaDescription) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('aiCompareFood');
      final result = await callable.call<Map<String, dynamic>>({
        'userQuery': userQuery.trim(),
        'usdaDescription': usdaDescription.trim(),
      });
      return result.data['isSame'] == true;
    } catch (e) {
      // On failure, default to rejecting (safer)
      return false;
    }
  }

  /// Extracts nutrition per 100g from a USDA food entry.
  NutritionPer100g _extractNutrition(Map<String, dynamic> usdaFood) {
    double calories = 0, protein = 0, carbs = 0, fat = 0;

    for (final n in (usdaFood['foodNutrients'] as List? ?? [])) {
      final name = (n['nutrientName'] as String? ?? '').toLowerCase();
      final value = (n['value'] as num?)?.toDouble() ?? 0;

      if (name.contains('energy') && calories == 0) {
        calories = value;
      } else if (name.contains('protein') && !name.contains('percent')) {
        protein = value;
      } else if (name.contains('carbohydrate')) {
        carbs = value;
      } else if (name.contains('total lipid') ||
          (name.contains('fat') && !name.contains('fatty'))) {
        fat = value;
      }
    }

    return NutritionPer100g(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  /// Stores a food document using a deterministic doc ID derived from
  /// `name_lowercase` to prevent duplicate entries under concurrency.
  ///
  /// Uses `set` with `merge: true` so concurrent writes for the same
  /// food name converge to a single document.
  Future<Food> _storeDeterministic(Food food) async {
    // Deterministic doc ID: replace spaces/special chars for a clean path
    final docId = food.nameLowercase.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    
    // Choose collection based on source
    final collectionName = food.source == 'ai' ? 'unverified_foods' : 'verified_foods';
    final docRef = _firestore.collection(collectionName).doc(docId);

    await docRef.set(food.toFirestore(), SetOptions(merge: true));

    return food.copyWith(id: docId);
  }

  // ─── Unit Resolution ──────────────────────────────────────────────

  /// Returns the effective unit to use when scaling nutrition.
  ///
  /// If the user typed an explicit unit (anything except the 'serving'
  /// fallback), that unit is always honoured. Otherwise the food's own
  /// [Food.preferredUnit] is used so that, e.g., "puri" scales by piece
  /// (50 g) instead of the generic serving (100 g).
  String _resolveUnit(String? parsedUnit, Food food) {
    if (parsedUnit != null && parsedUnit != 'serving') return parsedUnit;
    if (food.preferredUnit != null) return food.preferredUnit!;
    return parsedUnit ?? 'serving';
  }

  // ─── Aliasing System ──────────────────────────────────────────────

  /// Atomically appends a user-typed alias to a canonical food document.
  Future<void> _appendAliasToFood(Food canonicalFood, String userTypedName) async {
    if (canonicalFood.id.isEmpty) return;

    final normalized = userTypedName.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    
    if (normalized.isEmpty || 
        normalized == canonicalFood.nameLowercase ||
        canonicalFood.searchKeywords.contains(normalized) ||
        canonicalFood.aliases.contains(normalized)) {
      return; 
    }

    try {
      final collectionName = canonicalFood.source == 'ai' ? 'unverified_foods' : 'verified_foods';
      final docRef = _firestore.collection(collectionName).doc(canonicalFood.id);
      
      await docRef.update({
        'aliases': FieldValue.arrayUnion([normalized])
      });
    } catch (e) {
      // Silent fail for aliases
    }
  }
}
