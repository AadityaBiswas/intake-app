import 'package:flutter_test/flutter_test.dart';
import 'package:intake/services/input_parser.dart';

void main() {
  group('InputParser.parse', () {
    test('trailing number+unit: "butter 20g"', () {
      final result = InputParser.parse('butter 20g');
      expect(result.foodName, 'butter');
      expect(result.quantity, 20);
      expect(result.unit, 'g');
    });

    test('trailing number+unit: "milk 200ml"', () {
      final result = InputParser.parse('milk 200ml');
      expect(result.foodName, 'milk');
      expect(result.quantity, 200);
      expect(result.unit, 'ml');
    });

    test('leading number+unit: "200ml milk"', () {
      final result = InputParser.parse('200ml milk');
      expect(result.foodName, 'milk');
      expect(result.quantity, 200);
      expect(result.unit, 'ml');
    });

    test('leading number+unit: "20g butter"', () {
      final result = InputParser.parse('20g butter');
      expect(result.foodName, 'butter');
      expect(result.quantity, 20);
      expect(result.unit, 'g');
    });

    test('word-number + unit: "one bowl chicken curry"', () {
      final result = InputParser.parse('one bowl chicken curry');
      expect(result.foodName, 'chicken curry');
      expect(result.quantity, 1);
      expect(result.unit, 'bowl');
    });

    test('word-number + unit: "half plate biryani"', () {
      final result = InputParser.parse('half plate biryani');
      expect(result.foodName, 'biryani');
      expect(result.quantity, 0.5);
      expect(result.unit, 'plate');
    });

    test('number + unit: "2 bowls dal"', () {
      final result = InputParser.parse('2 bowls dal');
      expect(result.foodName, 'dal');
      expect(result.quantity, 2);
      expect(result.unit, 'bowl');
    });

    test('number + countable food: "2 eggs"', () {
      final result = InputParser.parse('2 eggs');
      expect(result.foodName, 'eggs');
      expect(result.quantity, 2);
      expect(result.unit, 'piece');
    });

    test('number + food (no recognized unit): "2 chicken breast"', () {
      final result = InputParser.parse('2 chicken breast');
      expect(result.foodName, 'chicken breast');
      expect(result.quantity, 2);
      expect(result.unit, 'serving');
    });

    test('word-number + food (no unit): "one banana"', () {
      final result = InputParser.parse('one banana');
      expect(result.foodName, 'banana');
      expect(result.quantity, 1);
      expect(result.unit, 'serving');
    });

    test('trailing number only: "chicken 200"', () {
      final result = InputParser.parse('chicken 200');
      expect(result.foodName, 'chicken');
      expect(result.quantity, 200);
      expect(result.unit, 'g');
    });

    test('plain food name: "rice"', () {
      final result = InputParser.parse('rice');
      expect(result.foodName, 'rice');
      expect(result.quantity, isNull);
      expect(result.unit, isNull);
    });

    test('plain multi-word food: "chicken curry"', () {
      final result = InputParser.parse('chicken curry');
      expect(result.foodName, 'chicken curry');
      expect(result.quantity, isNull);
      expect(result.unit, isNull);
    });

    test('empty input', () {
      final result = InputParser.parse('');
      expect(result.foodName, '');
      expect(result.quantity, isNull);
      expect(result.unit, isNull);
    });

    test('whitespace-only input', () {
      final result = InputParser.parse('   ');
      expect(result.foodName, '');
      expect(result.quantity, isNull);
      expect(result.unit, isNull);
    });

    test('decimal quantity: "1.5 cups oats"', () {
      final result = InputParser.parse('1.5 cups oats');
      expect(result.foodName, 'oats');
      expect(result.quantity, 1.5);
      expect(result.unit, 'cup');
    });

    test('gram alias: "paneer 50gm"', () {
      final result = InputParser.parse('paneer 50gm');
      expect(result.foodName, 'paneer');
      expect(result.quantity, 50);
      expect(result.unit, 'g');
    });
  });

  group('InputParser.extractFoodName', () {
    test('extracts food name ignoring quantity', () {
      expect(InputParser.extractFoodName('butter 20g'), 'butter');
    });

    test('extracts food name from plain input', () {
      expect(InputParser.extractFoodName('chicken curry'), 'chicken curry');
    });

    test('extracts food name from word-number input', () {
      expect(InputParser.extractFoodName('one bowl rice'), 'rice');
    });
  });
}
