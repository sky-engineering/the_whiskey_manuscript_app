import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addEvent({
    required String title,
    required DateTime date,
    required String location,
    String? details,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to add events.');
    }

    final trimmedTitle = title.trim();
    final trimmedLocation = location.trim();
    final trimmedDetails = details?.trim() ?? '';

    if (trimmedTitle.isEmpty) {
      throw Exception('Title is required.');
    }
    if (trimmedLocation.isEmpty) {
      throw Exception('Location is required.');
    }

    await _firestore.collection('events').add({
      'userId': user.uid,
      'title': trimmedTitle,
      'date': Timestamp.fromDate(date),
      'location': trimmedLocation,
      'details': trimmedDetails,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
