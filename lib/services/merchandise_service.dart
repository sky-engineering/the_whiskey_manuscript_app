import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MerchandiseService {
  MerchandiseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> addItem({
    required String title,
    required String description,
    required double price,
    required String link,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    await _firestore.collection('merch').add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Curator',
      'userEmail': user.email,
      'membershipLevel': await _userMembershipLevel(user.uid),
      'title': title.trim(),
      'description': description.trim(),
      'price': price,
      'link': link.trim(),
      'category': category.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
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
