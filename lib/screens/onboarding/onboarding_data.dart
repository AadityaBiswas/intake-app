/// Mutable data holder passed through the onboarding flow.
/// Each screen reads/writes its field, then passes this object forward.
class OnboardingData {
  String name = '';
  String gender = '';
  int age = 25;
  double weight = 65.0; // kg
  double height = 170.0; // cm
  String activityLevel = '';
  String weightGoal = '';
}
