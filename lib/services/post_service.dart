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

    await _firestore.collection('posts').add({
      'userId': user.uid,
      'email': user.email,
      'imageUrl': imageUrl,
      'caption': caption,
      'likeCount': 0,
      'likedBy': <String>[],
      'commentCount': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
}
