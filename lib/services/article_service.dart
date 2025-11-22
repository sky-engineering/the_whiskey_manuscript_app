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
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final membership = await _userMembershipLevel(user.uid);
    final sanitizedMarkdown = markdownFilename.trim();
    final normalizedTags =
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    final sanitizedImage = imageFilename?.trim();
    final sanitizedSubtitle = subtitle?.trim();

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
      'createdAt': FieldValue.serverTimestamp(),
    });
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
