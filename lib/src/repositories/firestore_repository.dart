import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple repository that caches frequently used Firestore queries so that
/// multiple widgets can reuse the same stream instead of creating their own
/// listeners.
class FirestoreRepository {
  FirestoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>> _streamCache =
      <String, Stream<QuerySnapshot<Map<String, dynamic>>>>{};

  Stream<QuerySnapshot<Map<String, dynamic>>> postsFeedStream() {
    return _streamCache.putIfAbsent(
      'posts_feed',
      () => _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> userPostsStream(String userId) {
    final cacheKey = 'user_posts:$userId';
    return _streamCache.putIfAbsent(
      cacheKey,
      () => _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> followersStream(String userId) {
    final cacheKey = 'followers:$userId';
    return _streamCache.putIfAbsent(
      cacheKey,
      () => _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .snapshots(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> followingStream(String userId) {
    final cacheKey = 'following:$userId';
    return _streamCache.putIfAbsent(
      cacheKey,
      () => _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .snapshots(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> eventsStream() {
    return _streamCache.putIfAbsent(
      'events',
      () => _firestore.collection('events').orderBy('date').snapshots(),
    );
  }
}
