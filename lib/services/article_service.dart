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
    required String summary,
    required String link,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final membership = await _userMembershipLevel(user.uid);

    await _firestore.collection('articles').add({
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Contributor',
      'userEmail': user.email,
      'membershipLevel': membership,
      'title': title.trim(),
      'summary': summary.trim(),
      'link': link.trim(),
      'category': category.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _userMembershipLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['membershipLevel'] as String?;
  }
}
