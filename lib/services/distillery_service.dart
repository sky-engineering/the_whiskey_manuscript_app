import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DistilleryService {
  DistilleryService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> addDistillery({
    required String name,
    required String location,
    required String story,
    required String signaturePour,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final membership = await _userMembershipLevel(user.uid);

    await _firestore.collection('distilleries').add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Explorer',
      'userEmail': user.email,
      'membershipLevel': membership,
      'name': name.trim(),
      'location': location.trim(),
      'story': story.trim(),
      'signaturePour': signaturePour.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _userMembershipLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['membershipLevel'] as String?;
  }
}
