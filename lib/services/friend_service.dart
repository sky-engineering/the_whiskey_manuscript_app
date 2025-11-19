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

    final friendDocRef = _firestore.collection('users').doc(friendUserId);
    final friendSnapshot = await friendDocRef.get();
    if (!friendSnapshot.exists) {
      throw Exception('Member not found.');
    }
    final friendData = friendSnapshot.data() ?? <String, dynamic>{};

    final currentDocRef = _firestore.collection('users').doc(currentUser.uid);
    final currentSnapshot = await currentDocRef.get();
    final currentData = currentSnapshot.data() ?? <String, dynamic>{};

    String resolveDisplayName(String? name, String? email) {
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        return email.trim();
      }
      return 'Member';
    }

    final friendDisplayName = resolveDisplayName(
        friendData['displayName'] as String?, friendData['email'] as String?);
    final friendEmail = (friendData['email'] as String?)?.trim();
    final friendMembership = friendData['membershipLevel'] as String?;

    final currentDisplayName = resolveDisplayName(
        currentData['displayName'] as String?, currentData['email'] as String?);
    final currentEmail = (currentData['email'] as String?)?.trim();
    final currentMembership = currentData['membershipLevel'] as String?;

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    batch.set(friendRef, {
      'userId': friendUserId,
      'displayName': friendDisplayName,
      'email': friendEmail,
      'membershipLevel': friendMembership,
      'addedAt': timestamp,
    });

    batch.set(
      currentDocRef.collection('following').doc(friendUserId),
      {
        'userId': friendUserId,
        'displayName': friendDisplayName,
        'email': friendEmail,
        'membershipLevel': friendMembership,
        'addedAt': timestamp,
      },
    );

    batch.set(
      friendDocRef.collection('followers').doc(currentUser.uid),
      {
        'userId': currentUser.uid,
        'displayName': currentDisplayName,
        'email': currentEmail,
        'membershipLevel': currentMembership,
        'addedAt': timestamp,
      },
    );

    await batch.commit();
  }

  Future<void> removeFriend(String friendUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Please sign in to manage friends.');
    }

    if (currentUser.uid == friendUserId) {
      throw Exception('You cannot remove yourself.');
    }

    final currentDocRef = _firestore.collection('users').doc(currentUser.uid);
    final friendDocRef = _firestore.collection('users').doc(friendUserId);
    final friendSnapshot = await friendDocRef.get();
    if (!friendSnapshot.exists) {
      throw Exception('Member not found.');
    }

    final batch = _firestore.batch();
    batch.delete(
      currentDocRef.collection('friends').doc(friendUserId),
    );
    batch.delete(
      currentDocRef.collection('following').doc(friendUserId),
    );
    batch.delete(
      friendDocRef.collection('followers').doc(currentUser.uid),
    );

    await batch.commit();
  }

}
