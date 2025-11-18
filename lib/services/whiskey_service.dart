import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WhiskeyService {
  WhiskeyService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> addWhiskey({
    required String name,
    required String region,
    required String notes,
    required String style,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    await _firestore.collection('whiskeys').add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Anonymous',
      'userEmail': user.email,
      'membershipLevel': await _userMembershipLevel(user.uid),
      'name': name.trim(),
      'region': region.trim(),
      'notes': notes.trim(),
      'style': style.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _userMembershipLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['membershipLevel'] as String?;
  }
}
