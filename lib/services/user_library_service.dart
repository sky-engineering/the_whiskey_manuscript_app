import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserLibraryException implements Exception {
  UserLibraryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserLibraryService {
  UserLibraryService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> addWhiskeyToCollection({
    required String whiskeyId,
    required String name,
    required String style,
    required String region,
    String? membership,
  }) async {
    final userId = _requireUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('whiskeyCollection')
        .doc(whiskeyId)
        .set(
      {
        'whiskeyId': whiskeyId,
        'name': name,
        'style': style,
        'region': region,
        'membershipLevel': membership,
        'addedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addWhiskeyToWishlist({
    required String whiskeyId,
    required String name,
    required String style,
    required String region,
    String? membership,
  }) async {
    final userId = _requireUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('whiskeyWishlist')
        .doc(whiskeyId)
        .set(
      {
        'whiskeyId': whiskeyId,
        'name': name,
        'style': style,
        'region': region,
        'membershipLevel': membership,
        'addedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> addFavoriteDistillery({
    required String distilleryId,
    required String name,
    required String location,
    required String signaturePour,
  }) async {
    final userId = _requireUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDistilleries')
        .doc(distilleryId)
        .set(
      {
        'distilleryId': distilleryId,
        'name': name,
        'location': location,
        'signaturePour': signaturePour,
        'addedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeFavoriteDistillery(String distilleryId) async {
    final userId = _requireUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteDistilleries')
        .doc(distilleryId)
        .delete();
  }

  Future<void> addFavoriteArticle({
    required String articleId,
    required String title,
    required String category,
    required String author,
  }) async {
    final userId = _requireUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteArticles')
        .doc(articleId)
        .set(
      {
        'articleId': articleId,
        'title': title,
        'category': category,
        'author': author,
        'addedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeFavoriteArticle(String articleId) async {
    final userId = _requireUserId();
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('favoriteArticles')
        .doc(articleId)
        .delete();
  }

  String _requireUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw UserLibraryException('Please sign in to save items.');
    }
    return user.uid;
  }
}
