import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArticleService {
  ArticleService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> addArticle({
    required String title,
    String? subtitle,
    required String category,
    required String markdownFilename,
    required List<String> tags,
    String? imageFilename,
    String? iconUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final membership = await _userMembershipLevel(user.uid);
    final sanitizedMarkdown = markdownFilename.trim();
    final normalizedTags =
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    final rawImage = imageFilename?.trim();
    final sanitizedImage =
        rawImage == null || rawImage.isEmpty ? null : rawImage;
    final rawSubtitle = subtitle?.trim();
    final sanitizedSubtitle =
        rawSubtitle == null || rawSubtitle.isEmpty ? null : rawSubtitle;

    await _firestore.collection('articles').add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Contributor',
      'userEmail': user.email,
      'membershipLevel': membership,
      'title': title.trim(),
      if (sanitizedSubtitle != null && sanitizedSubtitle.isNotEmpty)
        'subtitle': sanitizedSubtitle,
      'category': category.trim(),
      'tags': normalizedTags,
      'markdownFilename': sanitizedMarkdown,
      'markdownPath': 'assets/articles/$sanitizedMarkdown',
      if (sanitizedImage != null && sanitizedImage.isNotEmpty) ...{
        'imageFilename': sanitizedImage,
        'imagePath': 'assets/images/articles/$sanitizedImage',
      },
      if (iconUrl != null) 'iconUrl': iconUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateArticle(
    String articleId, {
    required String title,
    String? subtitle,
    required String category,
    required String markdownFilename,
    required List<String> tags,
    String? imageFilename,
    String? iconUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final docRef = _firestore.collection('articles').doc(articleId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Article not found.');
    }
    final ownerId = snapshot.data()?['userId'] as String?;
    if (ownerId != user.uid) {
      throw Exception('You can only edit your own articles.');
    }

    final membership = await _userMembershipLevel(user.uid);
    final sanitizedMarkdown = markdownFilename.trim();
    final normalizedTags =
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    final rawImage = imageFilename?.trim();
    final sanitizedImage =
        rawImage == null || rawImage.isEmpty ? null : rawImage;
    final rawSubtitle = subtitle?.trim();
    final sanitizedSubtitle =
        rawSubtitle == null || rawSubtitle.isEmpty ? null : rawSubtitle;

    final payload = <String, dynamic>{
      'title': title.trim(),
      'subtitle': sanitizedSubtitle,
      'category': category.trim(),
      'tags': normalizedTags,
      'markdownFilename': sanitizedMarkdown,
      'markdownPath': 'assets/articles/$sanitizedMarkdown',
      'iconUrl': iconUrl,
      'membershipLevel': membership,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (sanitizedImage != null && sanitizedImage.isNotEmpty) {
      payload.addAll({
        'imageFilename': sanitizedImage,
        'imagePath': 'assets/images/articles/$sanitizedImage',
      });
    } else {
      payload.addAll({
        'imageFilename': null,
        'imagePath': null,
      });
    }

    await docRef.update(payload);
  }

  Future<String?> _userMembershipLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['membershipLevel'] as String?;
  }
  Future<void> deleteArticle(String articleId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final docRef = _firestore.collection('articles').doc(articleId);
    final snapshot = await docRef.get();
    final ownerId = snapshot.data()?['userId'] as String?;
    if (!snapshot.exists || ownerId != user.uid) {
      throw Exception('You can only delete your own articles.');
    }

    await docRef.delete();
  }

}
