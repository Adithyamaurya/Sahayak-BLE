import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get sos => _db.collection('sos');

  Future<void> upsertCurrentUserProfile({
    required String uid,
    required String email,
    required String phone,
  }) async {
    await users.doc(uid).set(
      {
        'uid': uid,
        'email': email,
        'phone': phone,
        'lastLocation': null,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> ensureProfileForCurrentUser({
    required String phone,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await upsertCurrentUserProfile(
      uid: user.uid,
      email: user.email ?? '',
      phone: phone,
    );
  }

  Future<DocumentReference<Map<String, dynamic>>> createSos({
    required String userId,
    required double lat,
    required double lng,
  }) async {
    return sos.add({
      'userId': userId,
      'location': {'lat': lat, 'lng': lng},
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  Future<void> updateSosLocation({
    required String sosId,
    required double lat,
    required double lng,
  }) async {
    await sos.doc(sosId).set(
      {
        'location': {'lat': lat, 'lng': lng},
        'timestamp': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> resolveSos({required String sosId}) async {
    await sos.doc(sosId).set({'status': 'resolved'}, SetOptions(merge: true));
  }

  // New methods for functional dashboard
  Stream<int> streamActiveSosCount() {
    return sos
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<List<Map<String, dynamic>>> streamActiveAlerts() {
    return sos
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}

