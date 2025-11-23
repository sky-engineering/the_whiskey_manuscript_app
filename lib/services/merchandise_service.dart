import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MerchandiseService {
  MerchandiseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> saveItem(Map<String, dynamic> payload) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final collection = _firestore.collection('merch');
    final timestamp = FieldValue.serverTimestamp();
    final membershipLevel = await _userMembershipLevel(user.uid);
    final rawId = (payload['id'] as String?)?.trim();

    if (rawId == null || rawId.isEmpty) {
      final docRef = collection.doc();
      await docRef.set({
        ...payload,
        'id': docRef.id,
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Curator',
        'userEmail': user.email,
        'membershipLevel': membershipLevel,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });
      return;
    }

    final docRef = collection.doc(rawId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Merchandise item not found.');
    }

    final ownerId = snapshot.data()?['userId'] as String?;
    if (ownerId != user.uid) {
      throw Exception('You can only edit your own merchandise.');
    }

    await docRef.set(
      {
        ...payload,
        'id': rawId,
        'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Curator',
        'userEmail': user.email,
        'membershipLevel': membershipLevel,
        'updatedAt': timestamp,
      },
      SetOptions(merge: true),
    );
  }

  Future<String?> _userMembershipLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['membershipLevel'] as String?;
  }

  Future<void> deleteItem(String itemId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final docRef = _firestore.collection('merch').doc(itemId);
    final snapshot = await docRef.get();
    final ownerId = snapshot.data()?['userId'] as String?;
    if (!snapshot.exists || ownerId != user.uid) {
      throw Exception('You can only delete your own merchandise.');
    }

    await docRef.delete();
  }

}
