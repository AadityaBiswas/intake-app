import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static final _usersCol = _firestore.collection('users');

  static Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromJson(doc.data()!, uid);
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    await _usersCol.doc(profile.uid).set(
      profile.toJson(),
      SetOptions(merge: true),
    );
  }
}
