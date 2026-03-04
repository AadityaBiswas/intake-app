import 'package:cloud_firestore/cloud_firestore.dart';
import 'food.dart';
import 'scaled_nutrition.dart';

/// A logged food entry: the canonical Food + user-requested scaled nutrition.
class LoggedFoodEntry {
  final String? id; // Firestore document ID
  final Food food;
  final ScaledNutrition nutrition;
  final DateTime? createdAt; // When the user logged it
  final String? thoughtProcess; // AI reasoning (if source == 'ai')
  final List<String>? sources; // AI references (if source == 'ai')

  LoggedFoodEntry({
    this.id,
    required this.food,
    required this.nutrition,
    this.createdAt,
    this.thoughtProcess,
    this.sources,
  });

  LoggedFoodEntry copyWithNutrition(ScaledNutrition newNutrition) {
    return LoggedFoodEntry(
      id: id,
      food: food,
      nutrition: newNutrition,
      createdAt: createdAt,
      thoughtProcess: thoughtProcess,
      sources: sources,
    );
  }

  factory LoggedFoodEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return LoggedFoodEntry(
      id: id,
      food: Food.fromFirestore(
        Map<String, dynamic>.from(data['food'] as Map),
        data['food']['id'] ?? '',
      ),
      nutrition: ScaledNutrition.fromMap(
        Map<String, dynamic>.from(data['nutrition'] as Map),
      ),
      createdAt: data['created_at'] is Timestamp
          ? (data['created_at'] as Timestamp).toDate()
          : data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt'].toString())
              : null,
      thoughtProcess: data['thought_process'] as String?,
      sources: data['sources'] is List
          ? List<String>.from(data['sources'] as List)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    final foodMap = food.toFirestore();
    foodMap['id'] = food.id; 

    final map = <String, dynamic>{
      'food': foodMap,
      'nutrition': nutrition.toMap(),
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };

    if (thoughtProcess != null) map['thought_process'] = thoughtProcess;
    if (sources != null && sources!.isNotEmpty) map['sources'] = sources;

    return map;
  }
}
