import 'package:flutter_test/flutter_test.dart';
import 'package:intake/models/food.dart';
import 'package:intake/services/scaling_engine.dart';

void main() {
  group('ScalingEngine.scale', () {
    final per100g = NutritionPer100g(
      calories: 200,
      protein: 20,
      carbs: 30,
      fat: 10,
    );

    test('100g returns identity values', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 100,
        unit: 'g',
        defaultServingGrams: 100,
      );
      expect(result.calories, 200);
      expect(result.protein, 20);
      expect(result.carbs, 30);
      expect(result.fat, 10);
      expect(result.gramsUsed, 100);
    });

    test('50g returns half values', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 50,
        unit: 'g',
        defaultServingGrams: 100,
      );
      expect(result.calories, 100);
      expect(result.protein, 10);
      expect(result.carbs, 15);
      expect(result.fat, 5);
      expect(result.gramsUsed, 50);
    });

    test('200g returns double values', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 200,
        unit: 'g',
        defaultServingGrams: 100,
      );
      expect(result.calories, 400);
      expect(result.protein, 40);
      expect(result.carbs, 60);
      expect(result.fat, 20);
      expect(result.gramsUsed, 200);
    });

    test('null quantity uses defaultServingGrams', () {
      final result = ScalingEngine.scale(
        per100g,
        defaultServingGrams: 150,
      );
      expect(result.gramsUsed, 150);
      expect(result.calories, 300); // 200 * 150/100
      expect(result.protein, 30);   // 20 * 150/100
    });

    test('null quantity with 100g default returns identity', () {
      final result = ScalingEngine.scale(
        per100g,
        defaultServingGrams: 100,
      );
      expect(result.calories, 200);
      expect(result.protein, 20);
      expect(result.gramsUsed, 100);
    });

    test('bowl unit converts to 250g', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 1,
        unit: 'bowl',
        defaultServingGrams: 100,
      );
      expect(result.gramsUsed, 250);
      expect(result.calories, 500); // 200 * 250/100
    });

    test('2 cups converts to 480g', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 2,
        unit: 'cup',
        defaultServingGrams: 100,
      );
      expect(result.gramsUsed, 480);
      expect(result.calories, 960); // 200 * 480/100
    });

    test('tbsp converts to 15g', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 1,
        unit: 'tbsp',
        defaultServingGrams: 100,
      );
      expect(result.gramsUsed, 15);
      expect(result.calories, 30); // 200 * 15/100
    });

    test('quantity with no unit uses defaultServingGrams as multiplier', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 2,
        defaultServingGrams: 100,
      );
      // 2 * 100g default = 200g
      expect(result.gramsUsed, 200);
      expect(result.calories, 400);
    });

    test('unknown unit falls back to defaultServingGrams', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 1,
        unit: 'xyz',
        defaultServingGrams: 75,
      );
      expect(result.gramsUsed, 75);
      expect(result.calories, 150); // 200 * 75/100
    });

    test('zero quantity returns zero nutrition', () {
      final result = ScalingEngine.scale(
        per100g,
        quantity: 0,
        unit: 'g',
        defaultServingGrams: 100,
      );
      expect(result.calories, 0);
      expect(result.protein, 0);
      expect(result.gramsUsed, 0);
    });
  });
}
