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
  final DateTime? createdAt;

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
    this.createdAt,
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
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
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
      'created_at': FieldValue.serverTimestamp(),
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
