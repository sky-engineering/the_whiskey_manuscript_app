part of 'package:the_whiskey_manuscript_app/main.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({
    super.key,
    this.auth,
    this.firestore,
    this.messageService,
  });

  final FirebaseAuth? auth;

  final FirebaseFirestore? firestore;

  final MessageService? messageService;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late final FirebaseAuth _auth;

  late final FirebaseFirestore _firestore;

  late final MessageService _messageService;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;

  StreamSubscription<User?>? _authSub;

  List<_FriendOption> _friends = const [];

  @override
  void initState() {
    super.initState();

    _auth = widget.auth ?? FirebaseAuth.instance;

    _firestore = widget.firestore ?? FirebaseFirestore.instance;

    _messageService = widget.messageService ?? MessageService();

    _bindFriends();

    _authSub = _auth.userChanges().listen((_) => _bindFriends());
  }

  @override
  void dispose() {
    _friendsSub?.cancel();

    _authSub?.cancel();

    super.dispose();
  }

  void _bindFriends() {
    final userId = _auth.currentUser?.uid;

    _friendsSub?.cancel();

    if (userId == null) {
      if (mounted) {
        setState(() => _friends = const []);
      }

      return;
    }

    _friendsSub = _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .listen((snapshot) {
      final options = snapshot.docs.map((doc) {
        final data = doc.data();

        return _FriendOption(
          userId: doc.id,
          displayName: (data['displayName'] as String? ?? 'Member').trim(),
          email: (data['email'] as String?)?.trim(),
          membership: data['membershipLevel'] as String?,
        );
      }).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

      if (!mounted) return;

      setState(() => _friends = options);
    });
  }

  Future<void> _openComposer() async {
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to send messages.')),
      );

      return;
    }

    if (_friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a friend to start a conversation.')),
      );

      return;
    }

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ComposeMessageSheet(
        friends: _friends,
        onSend: _sendMessage,
      ),
    );

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent.')),
      );
    }
  }

  Future<void> _openConversation(_ConversationListItem room) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConversationDetailPage(
          room: room,
          currentUserId: user.uid,
          messageService: _messageService,
          firestore: _firestore,
        ),
      ),
    );
  }

  Future<void> _sendMessage(String userId, String message) async {
    await _messageService.sendMessage(toUserId: userId, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please sign in to view your messages.'),
      );
    }

    final roomQuery = _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: user.uid);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        tooltip: 'New message',
        onPressed: _openComposer,
        backgroundColor: AppColors.leather,
        foregroundColor: AppColors.onDark,
        child: const Icon(Icons.edit_rounded),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Direct Messages',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 8),
            const Text(
              'Friends can drop you notes about bottle shares, events, or travel plans.',
              style: TextStyle(color: AppColors.leatherDark),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: roomQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _FeedMessage(
                      message: 'We could not load your inbox.',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const _FeedMessage(
                      message:
                          'No conversations yet. Start a new conversation.',
                    );
                  }

                  final rooms = docs
                      .map(
                        (doc) => _ConversationListItem.fromDocument(
                          doc,
                          currentUserId: user.uid,
                        ),
                      )
                      .whereType<_ConversationListItem>()
                      .toList()
                    ..sort(
                      (a, b) => b.lastMessageAt.compareTo(a.lastMessageAt),
                    );

                  if (rooms.isEmpty) {
                    return const _FeedMessage(
                      message:
                          'No conversations yet. Start a new conversation.',
                    );
                  }

                  return ListView.separated(
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final room = rooms[index];

                      final preview = room.isLastMessageFromCurrentUser
                          ? 'You: ${room.lastMessage}'
                          : room.lastMessage;

                      return _ConversationCard(
                        partnerName: room.partnerName,
                        membership: room.partnerMembership,
                        messagePreview: preview,
                        timestamp: room.lastMessageAt,
                        onTap: () => _openConversation(room),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendOption {
  const _FriendOption({
    required this.userId,
    required this.displayName,
    this.email,
    this.membership,
  });

  final String userId;

  final String displayName;

  final String? email;

  final String? membership;
}

class _ComposeMessageSheet extends StatefulWidget {
  const _ComposeMessageSheet({
    required this.friends,
    required this.onSend,
  });

  final List<_FriendOption> friends;

  final Future<void> Function(String userId, String message) onSend;

  @override
  State<_ComposeMessageSheet> createState() => _ComposeMessageSheetState();
}

class _ComposeMessageSheetState extends State<_ComposeMessageSheet> {
  late String _selectedFriendId;

  final TextEditingController _controller = TextEditingController();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _selectedFriendId = widget.friends.first.userId;
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share a note before sending.')),
      );

      return;
    }

    setState(() => _isSending = true);

    try {
      await widget.onSend(_selectedFriendId, message);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send message: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send a message',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.darkGreen),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedFriendId,
            items: [
              for (final friend in widget.friends)
                DropdownMenuItem(
                  value: friend.userId,
                  child: Text(friend.displayName),
                ),
            ],
            onChanged: (value) =>
                setState(() => _selectedFriendId = value ?? _selectedFriendId),
            decoration: const InputDecoration(
              labelText: 'Friend',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: !_isSending,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSending ? null : _submit,
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationListItem {
  _ConversationListItem({
    required this.roomId,
    required this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.isLastMessageFromCurrentUser,
    this.partnerMembership,
  });

  final String roomId;

  final String partnerId;

  final String partnerName;

  final String? partnerMembership;

  final String lastMessage;

  final DateTime lastMessageAt;

  final bool isLastMessageFromCurrentUser;

  static _ConversationListItem? fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data();

    final partnerProfile = _resolvePartnerProfile(data, currentUserId);

    if (partnerProfile == null) return null;

    final partnerId = (partnerProfile['userId'] as String?)?.trim();

    if (partnerId == null || partnerId.isEmpty) return null;

    final message = _resolveLastMessage(data);

    final timestampSource =
        data['lastMessageAt'] ?? data['updatedAt'] ?? data['createdAt'];

    final timestamp = _coerceTimestamp(timestampSource).toLocal();

    final isOutgoing =
        (data['lastMessageSenderId'] as String?) == currentUserId;

    return _ConversationListItem(
      roomId: doc.id,
      partnerId: partnerId,
      partnerName: _resolveProfileName(partnerProfile),
      partnerMembership: _resolveProfileMembership(partnerProfile),
      lastMessage: message,
      lastMessageAt: timestamp,
      isLastMessageFromCurrentUser: isOutgoing,
    );
  }

  static String _resolveLastMessage(Map<String, dynamic> data) {
    final raw = (data['lastMessage'] as String?)?.trim();

    if (raw == null || raw.isEmpty) {
      return 'Say hello to keep the conversation going.';
    }

    return raw;
  }

  static Map<String, dynamic>? _resolvePartnerProfile(
    Map<String, dynamic> data,
    String currentUserId,
  ) {
    final profilesRaw = data['participantProfiles'];

    if (profilesRaw is Map<String, dynamic>) {
      for (final entry in profilesRaw.entries) {
        final value = entry.value;

        if (entry.key == currentUserId || value is! Map<String, dynamic>) {
          continue;
        }

        return {
          'userId': entry.key,
          ...value,
        };
      }
    }

    final participantsRaw = data['participants'];

    if (participantsRaw is Iterable) {
      for (final participant in participantsRaw) {
        if (participant is String && participant != currentUserId) {
          return {'userId': participant};
        }
      }
    }

    return null;
  }

  static String _resolveProfileName(Map<String, dynamic> profile) {
    final displayName = (profile['displayName'] as String?)?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = (profile['email'] as String?)?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Member';
  }

  static String? _resolveProfileMembership(Map<String, dynamic> profile) {
    final primary = (profile['membershipLevel'] as String?)?.trim();

    if (primary != null && primary.isNotEmpty) {
      return primary;
    }

    final fallback = (profile['membership'] as String?)?.trim();

    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.partnerName,
    required this.messagePreview,
    required this.timestamp,
    this.membership,
    this.onTap,
  });

  final String partnerName;

  final String messagePreview;

  final DateTime timestamp;

  final String? membership;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMessageTimestamp(timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.leatherDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (membership != null && membership!.isNotEmpty)
                    Chip(
                      label: Text(membership!),
                      backgroundColor: AppColors.neutralLight,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                messagePreview,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationDetailPage extends StatefulWidget {
  const _ConversationDetailPage({
    required this.room,
    required this.currentUserId,
    required this.messageService,
    required this.firestore,
  });

  final _ConversationListItem room;

  final String currentUserId;

  final MessageService messageService;

  final FirebaseFirestore firestore;

  @override
  State<_ConversationDetailPage> createState() =>
      _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<_ConversationDetailPage> {
  final TextEditingController _messageController = TextEditingController();

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _messageController.addListener(_handleComposerChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleComposerChanged);

    _messageController.dispose();

    super.dispose();
  }

  void _handleComposerChanged() {
    if (mounted) setState(() {});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream() {
    return widget.firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: widget.room.roomId)
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  Future<void> _sendCurrentMessage() async {
    final trimmed = _messageController.text.trim();

    if (trimmed.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      await widget.messageService
          .sendMessage(toUserId: widget.room.partnerId, message: trimmed);

      _messageController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  bool get _composerHasText => _messageController.text.trim().isNotEmpty;

  Future<void> _confirmAndDeleteMessage(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text('Remove this message from the conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.messageService.deleteMessage(messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerLabel = widget.room.partnerName;

    final membership = widget.room.partnerMembership;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partnerLabel),
            if (membership != null && membership.isNotEmpty)
              Text(
                membership,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.neutralLight),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messageStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Could not load this conversation.'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No messages yet. Say hello to get things going.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();

                      final messageId = docs[index].id;

                      final message = (data['message'] as String? ?? '').trim();

                      final senderName =
                          (data['fromDisplayName'] as String? ?? 'Member')
                              .trim();

                      final isMe = data['fromUserId'] == widget.currentUserId;

                      final timestamp =
                          _coerceTimestamp(data['sentAt']).toLocal();

                      return _ConversationBubble(
                        isOwnMessage: isMe,
                        message: message,
                        senderName: senderName,
                        timestamp: timestamp,
                        onDelete: isMe
                            ? () => _confirmAndDeleteMessage(messageId)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 3,
                      onSubmitted: (_) => _sendCurrentMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Send',
                    onPressed: (!_composerHasText || _isSending)
                        ? null
                        : _sendCurrentMessage,
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.leather,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({
    required this.isOwnMessage,
    required this.message,
    required this.senderName,
    required this.timestamp,
    this.onDelete,
  });

  final bool isOwnMessage;
  final String message;
  final String senderName;
  final DateTime timestamp;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final alignment =
        isOwnMessage ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor =
        isOwnMessage ? AppColors.leather : AppColors.neutralLight;
    final textColor = isOwnMessage ? AppColors.onDark : AppColors.darkGreen;
    final enableDeletion = isOwnMessage && onDelete != null;

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: enableDeletion ? onDelete : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
              bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: isOwnMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isOwnMessage)
                Text(
                  senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.leatherDark,
                  ),
                ),
              Text(
                message,
                style: TextStyle(color: textColor, fontSize: 15, height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                _formatMessageTimestamp(timestamp),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatMessageTimestamp(DateTime timestamp) {
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;

  final minute = timestamp.minute.toString().padLeft(2, '0');

  final period = timestamp.hour >= 12 ? 'PM' : 'AM';

  return '${timestamp.month}/${timestamp.day}/${timestamp.year}  $hour:$minute $period';
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.location,
    required this.details,
    required this.date,
    this.onDelete,
  });

  final String title;

  final String location;

  final String details;

  final DateTime date;

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ),
                Text(
                  _formatEventDate(date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.leatherDark,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete event',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.leatherDark,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location,
              style: const TextStyle(color: AppColors.leatherDark),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details,
                style: const TextStyle(color: AppColors.darkGreen),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatEventDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}
