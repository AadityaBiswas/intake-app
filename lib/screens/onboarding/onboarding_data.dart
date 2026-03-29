/// Mutable data holder passed through the onboarding flow.
/// Each screen reads/writes its field, then passes this object forward.
class OnboardingData {
  // Screen 3 — Name
  String firstName = '';
  String middleName = '';
  String lastName = '';

  /// Legacy compat getter
  String get name {
    final parts = [
      firstName,
      middleName,
      lastName,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(' ');
  }

  // Screen 4 — Gender & Age
  String gender = '';
  int age = 25;

  // Screen 5 — Height & Weight + Unit preference
  double weight = 65.0; // always stored in kg internally
  double height = 170.0; // always stored in cm internally
  bool isMetric = true; // true = Metric, false = Imperial

  // Screen 6 — Activity Level
  String activityLevel = '';

  // Screen 7 — Primary Goal
  String primaryGoal = ''; // 'Weight Loss', 'Weight Gain', 'Maintenance'

  // Screen 8 — Desired Weight
  double targetWeight = 0.0; // always in kg internally

  // Screen 9 — Fitness Experience
  String fitnessExperience = '';

  // Screen 10 — Goal Intensity (conditional)
  String goalIntensity = ''; // 'Mild', 'Moderate', 'Aggressive'

  // Screen 11 — Region
  String region = '';

  // Legacy compat
  String get weightGoal => primaryGoal;
  set weightGoal(String v) => primaryGoal = v;

  /// Whether Screen 10 should be shown (experience != "Just started")
  bool get showIntensityScreen => fitnessExperience != 'Just started';

  /// Dynamic total step count (accounts for conditional Screen 10)
  /// Flow: 1-Intro, 2-Features, 3-Name, 4-Gender/Age, 5-Height/Weight,
  ///       6-Activity, 7-Goal, 8-DesiredWeight, 9-Experience,
  ///       [10-Intensity], 11-Region, 12-Educational, 13-Consistency,
  ///       14-Reinforcement, 15-GoalConfirm, 16-Final
  int get totalSteps => showIntensityScreen ? 16 : 15;

  // ── BMI Calculation ──
  double? bmi;
  bool bmiCalculationStarted = false;
  bool bmiCalculationComplete = false;
  /// Wall-clock time when BMI timer was triggered. Used by CalculationBanner
  /// to resume from the correct progress position across screen navigations.
  DateTime? bmiCalculationStartTime;

  // ── Macro Calculation ──
  bool macroCalculationStarted = false;
  bool macroCalculationComplete = false;
  /// Wall-clock time when macro timer was triggered (Screen 10 or 14).
  DateTime? macroCalculationStartTime;
  int? estimatedDaysToGoal;

  // Macro results
  int? targetCalories;
  int? proteinGrams;
  int? carbGrams;
  int? fatGrams;

  // Detailed calculation breakdown
  double? bmr;
  double? maintenanceCalories;
  double? calorieAdjustment;
  double? activityMultiplier;

  // ── Unit conversion helpers ──

  /// Display weight in user-selected unit
  String displayWeight(double kg) {
    if (isMetric) return '${kg.round()} kg';
    return '${(kg * 2.20462).round()} lbs';
  }

  /// Display height in user-selected unit
  String displayHeight(double cm) {
    if (isMetric) return '${cm.round()} cm';
    final totalInches = cm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return "$feet'$inches\"";
  }

  /// Convert lbs to kg
  static double lbsToKg(double lbs) => lbs / 2.20462;

  /// Convert kg to lbs
  static double kgToLbs(double kg) => kg * 2.20462;

  /// Convert inches to cm
  static double inchesToCm(double inches) => inches * 2.54;

  /// Convert cm to inches
  static double cmToInches(double cm) => cm / 2.54;
}
