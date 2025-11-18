import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addFriend(String friendUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in to add friends.');
    }

    if (currentUser.uid == friendUserId) {
      throw Exception('You cannot add yourself.');
    }

    final friendRef = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .doc(friendUserId);
    final existing = await friendRef.get();
    if (existing.exists) {
      throw Exception('Already in your friends list.');
    }

    final friendSnapshot =
        await _firestore.collection('users').doc(friendUserId).get();
    if (!friendSnapshot.exists) {
      throw Exception('Member not found.');
    }

    final data = friendSnapshot.data() ?? <String, dynamic>{};
    final displayName = (data['displayName'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim();
    final membership = data['membershipLevel'] as String?;

    await friendRef.set({
      'userId': friendUserId,
      'displayName': (displayName != null && displayName.isNotEmpty)
          ? displayName
          : (email != null && email.isNotEmpty ? email : 'Member'),
      'email': email,
      'membershipLevel': membership,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }
}
