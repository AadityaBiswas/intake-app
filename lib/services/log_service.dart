import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/logged_food_entry.dart';

class LogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');
    return uid;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  CollectionReference _logsRef(DateTime date) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('daily_logs')
        .doc(_dateKey(date))
        .collection('foods');
  }

  Stream<List<LoggedFoodEntry>> streamDailyLogs(DateTime date) {
    if (_auth.currentUser == null) return Stream.value([]);
    
    return _logsRef(date).orderBy('created_at').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return LoggedFoodEntry.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> logFood(DateTime date, LoggedFoodEntry entry) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Ensure the parent user document exists so it shows in the Firestore console explicitly
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? 'Unknown',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'last_active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final ref = _logsRef(date).doc(); // auto-ID
    await ref.set(entry.toFirestore());
  }

  Future<void> updateLoggedFood(DateTime date, LoggedFoodEntry entry) async {
    if (entry.id == null) return;
    await _logsRef(date).doc(entry.id).update(entry.toFirestore());
  }

  Future<void> deleteLoggedFood(DateTime date, String entryId) async {
    await _logsRef(date).doc(entryId).delete();
  }
}
