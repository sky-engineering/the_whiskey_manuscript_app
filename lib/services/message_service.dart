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

    final chatRoomId = _chatRoomId(sender.uid, toUserId);

    await _ensureChatRoom(
      roomId: chatRoomId,
      senderId: sender.uid,
      senderProfile: _buildParticipantProfile(
        userId: sender.uid,
        displayName: senderName,
        email: sender.email,
        membershipLevel: senderData['membershipLevel'] as String?,
      ),
      recipientId: toUserId,
      recipientProfile: _buildParticipantProfile(
        userId: toUserId,
        displayName: recipientName,
        email: recipientData['email'] as String?,
        membershipLevel: recipientData['membershipLevel'] as String?,
      ),
      lastMessage: trimmed,
    );

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
      'chatRoomId': chatRoomId,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in.');
    }

    final docRef = _firestore.collection('messages').doc(messageId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Message not found.');
    }
    final data = snapshot.data();
    final senderId = data?['fromUserId'] as String?;
    final recipientId = data?['toUserId'] as String?;
    if (senderId != user.uid && recipientId != user.uid) {
      throw Exception('You can only delete your messages.');
    }
    final chatRoomId = data?['chatRoomId'] as String?;

    await docRef.delete();

    if (chatRoomId != null) {
      await _refreshChatRoomPreview(chatRoomId);
    }
  }

  Future<void> _refreshChatRoomPreview(String roomId) async {
    final chatRoomRef = _firestore.collection('chatRooms').doc(roomId);
    final latestSnapshot = await _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: roomId)
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();

    if (latestSnapshot.docs.isEmpty) {
      await chatRoomRef.set(
        {
          'lastMessage': null,
          'lastMessageSenderId': null,
          'lastMessageAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    final latest = latestSnapshot.docs.first.data();
    await chatRoomRef.set(
      {
        'lastMessage': latest['message'],
        'lastMessageSenderId': latest['fromUserId'],
        'lastMessageAt': latest['sentAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _ensureChatRoom({
    required String roomId,
    required String senderId,
    required Map<String, dynamic> senderProfile,
    required String recipientId,
    required Map<String, dynamic> recipientProfile,
    required String lastMessage,
  }) async {
    final chatRoomRef = _firestore.collection('chatRooms').doc(roomId);
    final existing = await chatRoomRef.get();

    final data = <String, dynamic>{
      'id': roomId,
      'participants': [senderId, recipientId],
      'participantIds': {
        senderId: true,
        recipientId: true,
      },
      'participantProfiles': {
        senderId: senderProfile,
        recipientId: recipientProfile,
      },
      'lastMessage': lastMessage,
      'lastMessageSenderId': senderId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await chatRoomRef.set(data, SetOptions(merge: true));
  }

  String _chatRoomId(String a, String b) {
    final participants = [a, b]..sort();
    return participants.join('_');
  }

  Map<String, dynamic> _buildParticipantProfile({
    required String userId,
    required String displayName,
    String? email,
    String? membershipLevel,
  }) {
    return {
      'userId': userId,
      'displayName': displayName,
      if (email != null) 'email': email,
      if (membershipLevel != null) 'membershipLevel': membershipLevel,
    };
  }
}
