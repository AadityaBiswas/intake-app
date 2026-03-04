/// Structured result of parsing raw user input.
///
/// Separates the food name from any quantity/unit information
/// so that search and scaling are independent operations.
class ParsedFoodInput {
  final String foodName;
  final double? quantity;
  final String? unit;

  const ParsedFoodInput({
    required this.foodName,
    this.quantity,
    this.unit,
  });

  @override
  String toString() =>
      'ParsedFoodInput(foodName: "$foodName", quantity: $quantity, unit: $unit)';
}
