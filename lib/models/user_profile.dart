import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String gender;
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final String activityLevel;
  final double bmi;
  final String weightGoal;
  final String goalIntensity; // 'Mild', 'Moderate', 'Aggressive'
  final double targetWeight; // in kg
  final String region; // onboarding region (e.g. 'South Asia')
  final DateTime? createdAt;

  // Computed macro goals saved during onboarding
  final int goalProtein;
  final int goalCarbs;
  final int goalFat;
  final int goalCalories;

  UserProfile({
    required this.uid,
    required this.name,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.activityLevel,
    required this.bmi,
    required this.weightGoal,
    this.goalIntensity = '',
    this.targetWeight = 0.0,
    this.region = '',
    this.createdAt,
    this.goalProtein = 0,
    this.goalCarbs = 0,
    this.goalFat = 0,
    this.goalCalories = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, String uid) {
    return UserProfile(
      uid: uid,
      name: json['name'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      activityLevel: json['activity_level'] as String? ?? '',
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0.0,
      weightGoal: json['weight_goal'] as String? ?? '',
      goalIntensity: json['goal_intensity'] as String? ?? '',
      targetWeight: (json['target_weight'] as num?)?.toDouble() ?? 0.0,
      region: json['region'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
      goalProtein: (json['goal_protein'] as num?)?.toInt() ?? 0,
      goalCarbs: (json['goal_carbs'] as num?)?.toInt() ?? 0,
      goalFat: (json['goal_fat'] as num?)?.toInt() ?? 0,
      goalCalories: (json['goal_calories'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'age': age,
      'weight': weight,
      'height': height,
      'activity_level': activityLevel,
      'bmi': bmi,
      'weight_goal': weightGoal,
      'goal_intensity': goalIntensity,
      'target_weight': targetWeight,
      'region': region,
      'created_at': FieldValue.serverTimestamp(),
      if (goalProtein > 0) 'goal_protein': goalProtein,
      if (goalCarbs > 0) 'goal_carbs': goalCarbs,
      if (goalFat > 0) 'goal_fat': goalFat,
      if (goalCalories > 0) 'goal_calories': goalCalories,
    };
  }

  bool get isOnboardingComplete =>
      name.isNotEmpty &&
      gender.isNotEmpty &&
      age > 0 &&
      weight > 0 &&
      height > 0 &&
      activityLevel.isNotEmpty &&
      weightGoal.isNotEmpty;
}
