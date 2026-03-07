import '../models/parsed_food_input.dart';

/// Parses raw user input into a structured [ParsedFoodInput].
///
/// Extracts food name, quantity, and unit from free-form strings like:
/// - "butter 20g" → foodName: "butter", quantity: 20, unit: "g"
/// - "one bowl chicken curry" → foodName: "chicken curry", quantity: 1, unit: "bowl"
/// - "200ml milk" → foodName: "milk", quantity: 200, unit: "ml"
/// - "rice" → foodName: "rice", quantity: null, unit: null
class InputParser {
  InputParser._();

  /// Word-to-number mapping for natural language quantities.
  static const Map<String, double> _wordNumbers = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'half': 0.5,
    'quarter': 0.25,
    'a': 1,
  };

  /// Recognized unit strings (normalized to canonical form).
  static const Map<String, String> _unitAliases = {
    'g': 'g',
    'gm': 'g',
    'gms': 'g',
    'gram': 'g',
    'grams': 'g',
    'ml': 'ml',
    'millilitre': 'ml',
    'milliliter': 'ml',
    'bowl': 'bowl',
    'bowls': 'bowl',
    'cup': 'cup',
    'cups': 'cup',
    'plate': 'plate',
    'plates': 'plate',
    'piece': 'piece',
    'pieces': 'piece',
    'pcs': 'piece',
    'pc': 'piece',
    'tbsp': 'tbsp',
    'tablespoon': 'tbsp',
    'tablespoons': 'tbsp',
    'tsp': 'tsp',
    'teaspoon': 'tsp',
    'teaspoons': 'tsp',
    'slice': 'slice',
    'slices': 'slice',
    'serving': 'serving',
    'servings': 'serving',
    'glass': 'glass',
    'glasses': 'glass',
    'katori': 'bowl',
    'spoon': 'tbsp',
    'scoop': 'scoop',
    'scoops': 'scoop',
    'roti': 'piece',
    'rotis': 'piece',
    'chapati': 'piece',
    'chapatis': 'piece',
    'chapatti': 'piece',
    'chapattis': 'piece',
    'puri': 'piece',
    'puris': 'piece',
    'paratha': 'piece',
    'parathas': 'piece',
    'idli': 'piece',
    'idlis': 'piece',
    'dosa': 'piece',
    'dosas': 'piece',
    'uttapam': 'piece',
    'vada': 'piece',
    'samosa': 'piece',
    'samosas': 'piece',
    'egg': 'piece',
    'eggs': 'piece',
    'biscuit': 'piece',
    'biscuits': 'piece',
    'cookie': 'piece',
    'cookies': 'piece',
  };

  /// Parses raw input into structured [ParsedFoodInput].
  static ParsedFoodInput parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const ParsedFoodInput(foodName: '');
    }

    final lower = trimmed.toLowerCase();

    // Pattern 1: Trailing "NUMBERunit" (e.g., "butter 20g", "milk 200ml")
    final trailingPattern = RegExp(
      r'^(.+?)\s+(\d+(?:\.\d+)?)\s*(g|gm|gms|gram|grams|ml|millilitre|milliliter)\s*$',
      caseSensitive: false,
    );
    final trailingMatch = trailingPattern.firstMatch(lower);
    if (trailingMatch != null) {
      final name = _cleanFoodName(trailingMatch.group(1)!);
      final qty = double.tryParse(trailingMatch.group(2)!);
      final unit = _normalizeUnit(trailingMatch.group(3)!);
      if (name.isNotEmpty && qty != null) {
        return ParsedFoodInput(foodName: name, quantity: qty, unit: unit);
      }
    }

    // Pattern 2: Leading "NUMBERunit" (e.g., "200ml milk", "20g butter")
    final leadingPattern = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(g|gm|gms|gram|grams|ml|millilitre|milliliter)\s+(.+)$',
      caseSensitive: false,
    );
    final leadingMatch = leadingPattern.firstMatch(lower);
    if (leadingMatch != null) {
      final qty = double.tryParse(leadingMatch.group(1)!);
      final unit = _normalizeUnit(leadingMatch.group(2)!);
      final name = _cleanFoodName(leadingMatch.group(3)!);
      if (name.isNotEmpty && qty != null) {
        return ParsedFoodInput(foodName: name, quantity: qty, unit: unit);
      }
    }

    // Pattern 3: Word-number + unit + food (e.g., "one bowl chicken curry", "half plate biryani")
    final words = lower.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      // Check first word for word-number
      final firstWordQty = _wordNumbers[words[0]];
      if (firstWordQty != null && words.length >= 3) {
        final possibleUnit = _unitAliases[words[1]];
        if (possibleUnit != null) {
          final name = _cleanFoodName(words.sublist(2).join(' '));
          if (name.isNotEmpty) {
            return ParsedFoodInput(
              foodName: name,
              quantity: firstWordQty,
              unit: possibleUnit,
            );
          }
        }
      }

      // Pattern 4: number + unit + food (e.g., "2 bowls chicken curry", "1 cup rice")
      final leadingNumQty = double.tryParse(words[0]);
      if (leadingNumQty != null && words.length >= 3) {
        final possibleUnit = _unitAliases[words[1]];
        if (possibleUnit != null) {
          final name = _cleanFoodName(words.sublist(2).join(' '));
          if (name.isNotEmpty) {
            return ParsedFoodInput(
              foodName: name,
              quantity: leadingNumQty,
              unit: possibleUnit,
            );
          }
        }
      }

      // Pattern 5: number + food (e.g., "2 eggs", "3 roti")
      // Check if the food word itself implies a unit (egg, roti, etc.)
      if (leadingNumQty != null && words.length >= 2) {
        final restWords = words.sublist(1);
        // Check if first rest-word is a countable food unit
        final impliedUnit = _unitAliases[restWords[0]];
        if (impliedUnit != null && restWords.length == 1) {
          // "2 eggs" → foodName: "eggs", quantity: 2, unit: "piece"
          return ParsedFoodInput(
            foodName: restWords[0],
            quantity: leadingNumQty,
            unit: impliedUnit,
          );
        }
        // "2 chicken breast" — number + food, no unit
        final name = _cleanFoodName(restWords.join(' '));
        if (name.isNotEmpty) {
          return ParsedFoodInput(
            foodName: name,
            quantity: leadingNumQty,
            unit: 'serving',
          );
        }
      }

      // Pattern 6: word-number + food (no unit) (e.g., "one banana")
      if (firstWordQty != null && words.length >= 2) {
        final name = _cleanFoodName(words.sublist(1).join(' '));
        if (name.isNotEmpty) {
          return ParsedFoodInput(
            foodName: name,
            quantity: firstWordQty,
            unit: 'serving',
          );
        }
      }

      // Pattern 7: Trailing number only (e.g., "chicken 200")
      final trailingNum = double.tryParse(words.last);
      if (trailingNum != null && words.length >= 2) {
        final name =
            _cleanFoodName(words.sublist(0, words.length - 1).join(' '));
        if (name.isNotEmpty) {
          return ParsedFoodInput(
            foodName: name,
            quantity: trailingNum,
            unit: 'g',
          );
        }
      }
    }

    // No quantity/unit detected — plain food name
    return ParsedFoodInput(foodName: _cleanFoodName(lower));
  }

  /// Extracts only the food name from raw input (ignores quantity/unit).
  /// Used by the suggestion engine during typing.
  static String extractFoodName(String raw) {
    return parse(raw).foodName;
  }

  static String _normalizeUnit(String unit) {
    return _unitAliases[unit.toLowerCase()] ?? unit.toLowerCase();
  }

  static String _cleanFoodName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
