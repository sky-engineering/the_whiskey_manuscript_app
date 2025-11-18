import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendMessage({
    required String toUserId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a message.');
    }

    final sender = _auth.currentUser;
    if (sender == null) {
      throw Exception('Please sign in.');
    }

    if (sender.uid == toUserId) {
      throw Exception('You cannot message yourself.');
    }

    final recipientsRef = _firestore.collection('users').doc(toUserId);
    final recipientSnapshot = await recipientsRef.get();
    if (!recipientSnapshot.exists) {
      throw Exception('Recipient not found.');
    }

    final senderSnapshot =
        await _firestore.collection('users').doc(sender.uid).get();

    final senderData = senderSnapshot.data() ?? <String, dynamic>{};
    final recipientData = recipientSnapshot.data() ?? <String, dynamic>{};

    final senderDisplayName = (senderData['displayName'] as String?)?.trim();
    final senderName =
        (senderDisplayName != null && senderDisplayName.isNotEmpty)
            ? senderDisplayName
            : (sender.displayName ?? sender.email ?? 'Member');

    final recipientDisplayName =
        (recipientData['displayName'] as String?)?.trim();
    final recipientName =
        (recipientDisplayName != null && recipientDisplayName.isNotEmpty)
            ? recipientDisplayName
            : ((recipientData['email'] as String?)?.trim() ?? 'Member');

    await _firestore.collection('messages').add({
      'fromUserId': sender.uid,
      'fromDisplayName': senderName,
      'fromEmail': sender.email,
      'fromMembershipLevel': senderData['membershipLevel'],
      'toUserId': toUserId,
      'toDisplayName': recipientName,
      'toEmail': recipientData['email'],
      'toMembershipLevel': recipientData['membershipLevel'],
      'message': trimmed,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }
}
