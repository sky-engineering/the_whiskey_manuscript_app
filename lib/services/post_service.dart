import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> createPost(
    String imageUrl, {
    required String caption,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user');

    final userSnapshot =
        await _firestore.collection('users').doc(user.uid).get();
    final profileData = userSnapshot.data();

    String? firstName = (profileData?['firstName'] as String?)?.trim();
    if (firstName != null && firstName.isEmpty) {
      firstName = null;
    }
    String? lastName = (profileData?['lastName'] as String?)?.trim();
    if (lastName != null && lastName.isEmpty) {
      lastName = null;
    }
    String? displayName = (profileData?['displayName'] as String?)?.trim();
    if (displayName == null || displayName.isEmpty) {
      final authDisplayName = user.displayName?.trim();
      if (authDisplayName != null && authDisplayName.isNotEmpty) {
        displayName = authDisplayName;
      } else {
        displayName = (user.email ?? 'Member').trim();
      }
    }

    final postData = <String, dynamic>{
      'userId': user.uid,
      'email': user.email,
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
      'imageUrl': imageUrl,
      'caption': caption,
      'likeCount': 0,
      'likedBy': <String>[],
      'commentCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    postData.removeWhere((_, value) => value == null);

    await _firestore.collection('posts').add(postData);
  }

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user');

    final docRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception('Post not found');
      }

      final data = snapshot.data() ?? <String, dynamic>{};
      final likedBy =
          List<String>.from(data['likedBy'] as List<dynamic>? ?? []);
      final hasLiked = likedBy.contains(user.uid);

      transaction.update(docRef, {
        'likedBy': hasLiked
            ? FieldValue.arrayRemove([user.uid])
            : FieldValue.arrayUnion([user.uid]),
        'likeCount': FieldValue.increment(hasLiked ? -1 : 1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addComment(String postId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a comment.');
    }

    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user');

    final profileSnapshot =
        await _firestore.collection('users').doc(user.uid).get();
    final profileData = profileSnapshot.data();
    final membership = profileData?['membershipLevel'] as String?;
    final displayNameRaw = (profileData?['displayName'] as String?)?.trim();
    final resolvedName = (displayNameRaw != null && displayNameRaw.isNotEmpty)
        ? displayNameRaw
        : (user.displayName ?? user.email ?? 'Member');

    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) {
        throw Exception('Post not found');
      }

      transaction.set(commentRef, {
        'postId': postId,
        'userId': user.uid,
        'userName': resolvedName,
        'userEmail': user.email,
        'membershipLevel': membership,
        'text': trimmed,
        'timestamp': FieldValue.serverTimestamp(),
      });

      transaction.update(postRef, {
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user');

    final docRef = _firestore.collection('posts').doc(postId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Post not found.');
    }
    final data = snapshot.data();
    final ownerId = data?['userId'] as String?;
    if (ownerId != user.uid) {
      throw Exception('You can only delete your posts.');
    }

    final comments = await docRef.collection('comments').get();
    final batch = _firestore.batch();
    batch.delete(docRef);
    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }
    await batch.commit();
  }

}

