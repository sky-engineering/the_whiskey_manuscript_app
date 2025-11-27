part of 'package:the_whiskey_manuscript_app/main.dart';

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.authorLabel,
    required this.timestamp,
    this.imageUrl,
    this.caption = '',
    this.likeCount,
    this.commentCount,
    this.isLiked,
    this.onToggleLike,
    this.onShowLikes,
    this.onOpenComments,
    this.onAddFriend,
    this.onTap,
  });

  final String authorLabel;
  final DateTime timestamp;
  final String? imageUrl;
  final String caption;
  final int? likeCount;
  final int? commentCount;
  final bool? isLiked;
  final VoidCallback? onToggleLike;
  final VoidCallback? onShowLikes;
  final VoidCallback? onOpenComments;
  final VoidCallback? onAddFriend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedAuthor =
        authorLabel.trim().isNotEmpty ? authorLabel.trim() : 'Whiskey User';
    final likeTotal = likeCount ?? 0;
    final commentTotal = commentCount ?? 0;
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.neutralLight,
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          resolvedAuthor,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                      if (onAddFriend != null)
                        GestureDetector(
                          onTap: onAddFriend,
                          child: Container(
                            margin: const EdgeInsets.only(left: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.leather),
                              color: Colors.transparent,
                            ),
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.leather,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (imageUrl != null)
            _buildCachedImage(
              imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                _buildReactionIcon(
                  icon:
                      isLiked == true ? Icons.favorite : Icons.favorite_border,
                  color: isLiked == true
                      ? AppColors.leather
                      : AppColors.leatherDark,
                  onPressed: onToggleLike,
                ),
                const SizedBox(width: 0),
                GestureDetector(
                  onTap: onShowLikes,
                  child: Text(
                    '$likeTotal',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.leatherDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                _buildReactionIcon(
                  icon: Icons.mode_comment_outlined,
                  color: AppColors.leatherDark,
                  onPressed: onOpenComments,
                ),
                const SizedBox(width: 0),
                Text(
                  '$commentTotal',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.leatherDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkGreen,
                ),
                children: [
                  TextSpan(
                    text: '$resolvedAuthor ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (caption.isNotEmpty)
                    TextSpan(
                      text: caption,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              _formatDate(timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.leatherDark,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }
    return content;
  }

  static String _formatDate(DateTime timestamp) =>
      '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  Widget _buildReactionIcon({
    required IconData icon,
    Color? color,
    VoidCallback? onPressed,
  }) {
    if (onPressed == null) {
      return Icon(icon, color: color ?? AppColors.leatherDark);
    }
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color ?? AppColors.leatherDark),
    );
  }
}

String _resolvePostAuthorName({
  String? firstName,
  String? lastName,
  String? fallbackEmail,
}) {
  final first = firstName?.trim() ?? '';
  final last = lastName?.trim() ?? '';
  if (first.isNotEmpty && last.isNotEmpty) {
    return '$first $last';
  }
  final email = fallbackEmail?.trim();
  if (email != null && email.isNotEmpty) {
    return email;
  }
  return 'Whiskey User';
}

Future<void> showFriendsBottomSheet(BuildContext context,
    {required String userId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _FriendsBottomSheet(userId: userId),
    ),
  );
}

class _FriendsBottomSheet extends StatelessWidget {
  const _FriendsBottomSheet({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutralMid,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your friends',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.darkGreen, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'We could not load your friends list.',
                      style: TextStyle(color: AppColors.leatherDark),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No friends just yet.',
                      style: TextStyle(color: AppColors.leatherDark),
                    ),
                  );
                }

                final estimatedHeight = (docs.length * 68).clamp(180, 400);
                return SizedBox(
                  height: estimatedHeight.toDouble(),
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final name =
                          (data['displayName'] as String? ?? 'Member').trim();
                      final membership = data['membershipLevel'] as String?;
                      final email = (data['email'] as String?)?.trim();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.neutralMid,
                          child: Text(
                            _initialsFor(name),
                            style: const TextStyle(color: AppColors.darkGreen),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (email != null && email.isNotEmpty)
                              Text(
                                email,
                                style: const TextStyle(
                                    color: AppColors.leatherDark),
                              ),
                            if (membership != null && membership.isNotEmpty)
                              Text(
                                membership,
                                style: const TextStyle(
                                    color: AppColors.leatherDark),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showLikesBottomSheet(
    BuildContext context, List<String> likedUserIds) {
  final uniqueIds = LinkedHashSet<String>.from(likedUserIds);
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _LikesBottomSheet(userIds: uniqueIds.toList()),
  );
}

Future<void> showCommentsBottomSheet(
  BuildContext context, {
  required String postId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.9,
      child: PostCommentsView(
        postId: postId,
        showHandle: true,
      ),
    ),
  );
}

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts.')),
      );
      return;
    }

    try {
      await _postService.toggleLike(widget.postId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update like: $e')),
      );
    }
  }

  Future<void> _showLikes(List<String> likedUserIds) {
    return showLikesBottomSheet(context, likedUserIds);
  }

  @override
  Widget build(BuildContext context) {
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: postRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load this post.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text('Post is no longer available.'),
            );
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(
              child: Text('Post is no longer available.'),
            );
          }

          final likedBy =
              List<String>.from((data['likedBy'] as List<dynamic>? ?? []));
          final likeCount = data['likeCount'] as int? ?? likedBy.length;
          final commentCount = data['commentCount'] as int? ?? 0;
          final caption = (data['caption'] as String? ?? '').trim();
          final author = (data['email'] as String? ?? 'Member').trim();
          final imageUrl = data['imageUrl'] as String?;
          final timestamp = _coerceTimestamp(data['timestamp']);
          final currentUserId = _auth.currentUser?.uid;
          final isLiked =
              currentUserId != null && likedBy.contains(currentUserId);

          return Column(
            children: [
              _PostCard(
                authorLabel: author,
                timestamp: timestamp,
                imageUrl: imageUrl,
                caption: caption,
                likeCount: likeCount,
                commentCount: commentCount,
                isLiked: isLiked,
                onToggleLike: _toggleLike,
                onShowLikes: () => _showLikes(likedBy),
              ),
              const Divider(height: 1),
              Expanded(
                child: PostCommentsView(
                  postId: widget.postId,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PostCommentsView extends StatefulWidget {
  const PostCommentsView({
    super.key,
    required this.postId,
    this.showHandle = false,
    this.padding,
  });

  final String postId;
  final bool showHandle;
  final EdgeInsetsGeometry? padding;

  @override
  State<PostCommentsView> createState() => _PostCommentsViewState();
}

class _PostCommentsViewState extends State<PostCommentsView> {
  final PostService _postService = PostService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a comment before sending.')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await _postService.addComment(widget.postId, text);
      _controller.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not post comment: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsQuery = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: false);

    final user = _auth.currentUser;

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    const basePadding = EdgeInsets.fromLTRB(24, 16, 24, 16);
    final resolvedPadding = (widget.padding ?? basePadding)
        .add(EdgeInsets.only(bottom: viewInsets));

    return SafeArea(
      top: !widget.showHandle,
      child: Padding(
        padding: resolvedPadding,
        child: Column(
          children: [
            if (widget.showHandle) ...[
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutralMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Comments',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.darkGreen, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: commentsQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'We could not load the comments.',
                        style: TextStyle(color: AppColors.leatherDark),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Start the conversation.',
                        style: TextStyle(color: AppColors.leatherDark),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final author =
                          (data['userName'] as String? ?? 'Member').trim();
                      final membership = data['membershipLevel'] as String?;
                      final body = (data['text'] as String? ?? '').trim();
                      final timestamp = _coerceTimestamp(data['timestamp']);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.neutralMid,
                          child: Text(
                            _initialsFor(author),
                            style: const TextStyle(color: AppColors.darkGreen),
                          ),
                        ),
                        title: Text(
                          author,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              body,
                              style:
                                  const TextStyle(color: AppColors.darkGreen),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCommentTimestamp(timestamp, membership),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.leatherDark,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildComposer(user),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(User? user) {
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Sign in to add a comment.',
          style: TextStyle(color: AppColors.leatherDark),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !_isSending,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts...',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 4,
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: _isSending ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: AppColors.leather,
            foregroundColor: AppColors.onDark,
          ),
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}

String _formatCommentTimestamp(DateTime timestamp, String? membership) {
  final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final period = timestamp.hour >= 12 ? 'PM' : 'AM';
  final date = '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  final time = '$hour:$minute $period';
  final membershipLabel = (membership != null && membership.isNotEmpty)
      ? ' ($membership member)'
      : '';
  return '$date at $time$membershipLabel';
}

class _LikesBottomSheet extends StatelessWidget {
  const _LikesBottomSheet({required this.userIds});

  final List<String> userIds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutralMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Liked by',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (userIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No likes just yet.',
                  style: TextStyle(color: AppColors.leatherDark),
                ),
              )
            else
              FutureBuilder<List<_LikeUser>>(
                future: _fetchLikeUsers(userIds),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'We could not load who liked this pour.',
                        style: TextStyle(color: AppColors.leatherDark),
                      ),
                    );
                  }

                  final likes = snapshot.data ?? [];
                  if (likes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'We could not find any profiles for these likes yet.',
                        style: TextStyle(color: AppColors.leatherDark),
                      ),
                    );
                  }

                  final estimatedHeight = likes.length * 64 + 80;
                  final height = estimatedHeight > 360
                      ? 360.0
                      : estimatedHeight.toDouble();

                  return SizedBox(
                    height: height,
                    child: ListView.separated(
                      itemCount: likes.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final like = likes[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.neutralMid,
                            child: Text(
                              _initialsFor(like.displayName),
                              style:
                                  const TextStyle(color: AppColors.darkGreen),
                            ),
                          ),
                          title: Text(
                            like.displayName,
                            style: const TextStyle(color: AppColors.darkGreen),
                          ),
                          subtitle: like.membership == null
                              ? null
                              : Text(
                                  like.membership!,
                                  style: const TextStyle(
                                      color: AppColors.leatherDark),
                                ),
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LikeUser {
  const _LikeUser({
    required this.userId,
    required this.displayName,
    this.membership,
  });

  final String userId;
  final String displayName;
  final String? membership;
}

Future<List<_LikeUser>> _fetchLikeUsers(List<String> userIds) async {
  if (userIds.isEmpty) return <_LikeUser>[];
  final firestore = FirebaseFirestore.instance;
  final Map<String, _LikeUser> likeMap = {};
  for (var i = 0; i < userIds.length; i += 10) {
    final end = i + 10;
    final chunk =
        userIds.sublist(i, end > userIds.length ? userIds.length : end);
    final snapshot = await firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: chunk)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final displayName = (data['displayName'] as String?)?.trim();
      final fallbackEmail = (data['email'] as String?)?.trim();
      final resolved = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : (fallbackEmail != null && fallbackEmail.isNotEmpty
              ? fallbackEmail
              : 'Member');
      likeMap[doc.id] = _LikeUser(
        userId: doc.id,
        displayName: resolved,
        membership: data['membershipLevel'] as String?,
      );
    }
  }

  for (final id in userIds) {
    likeMap.putIfAbsent(
      id,
      () => _LikeUser(userId: id, displayName: 'Member'),
    );
  }

  final likes = likeMap.values.toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));
  return likes;
}

DateTime _coerceTimestamp(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  return DateTime.now();
}

String _initialsFor(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  final buffer = StringBuffer();
  for (final part in parts) {
    if (part.isNotEmpty) buffer.write(part[0].toUpperCase());
    if (buffer.length >= 2) break;
  }
  return buffer.isEmpty ? trimmed[0].toUpperCase() : buffer.toString();
}

// ignore: unused_element
class _UserWhiskeyList extends StatelessWidget {
  const _UserWhiskeyList({required this.userId});

  final String userId;
  static final WhiskeyService _whiskeyService = WhiskeyService();

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('whiskeys')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your whiskey library.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'Add your first bottle to the library.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              _buildWhiskeyCardFromData(
                doc.data(),
                authorLabel: 'You',
                membership: doc.data()['membershipLevel'] as String?,
                timestamp: _coerceTimestamp(doc.data()['createdAt']),
                showAuthor: false,
                onDelete: () => _deleteWhiskey(
                  context,
                  doc.id,
                  doc.data()['name'] as String?,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteWhiskey(
    BuildContext context,
    String whiskeyId,
    String? label,
  ) async {
    final displayName =
        (label == null || label.trim().isEmpty) ? 'this whiskey' : label.trim();
    final confirmed = await _confirmDeletion(
      context,
      title: 'Remove whiskey',
      message: 'Delete $displayName from your library?',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => _whiskeyService.deleteWhiskey(whiskeyId),
      successMessage: 'Whiskey removed.',
    );
  }
}
