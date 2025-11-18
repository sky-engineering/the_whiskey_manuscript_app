import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String imageUrl;
  final DateTime timestamp;

  Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.timestamp,
  });

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Post(
      id: doc.id,
      userId: data['userId'] as String,
      imageUrl: data['imageUrl'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
