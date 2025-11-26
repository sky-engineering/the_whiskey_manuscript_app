part of 'package:the_whiskey_manuscript_app/main.dart';

/// SOCIAL PAGE WITH CAPTIONS + POSTER EMAIL + TIMESTAMP
/// ------------------------------------------------------------
class SocialPage extends StatefulWidget {
  const SocialPage({super.key, this.repository});

  final FirestoreRepository? repository;

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final PostUploader _uploader = PostUploader();
  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final FirestoreRepository _repository;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _followingSub;
  StreamSubscription<User?>? _authSub;
  Set<String> _followingIds = <String>{};
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreRepository();
    _listenForFollowing();
    _authSub = _auth.userChanges().listen((_) {
      _listenForFollowing();
    });
  }

  @override
  void dispose() {
    _followingSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _listenForFollowing() {
    final userId = _auth.currentUser?.uid;
    _followingSub?.cancel();
    if (userId == null) {
      if (mounted) {
        setState(() {
          _followingIds = <String>{};
        });
      }
      return;
    }

    _followingSub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _followingIds = snapshot.docs.map((doc) => doc.id).toSet();
      });
    });
  }

  Future<void> _addFriend(String friendUserId) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add friends.')),
      );
      return;
    }

    if (_followingIds.contains(friendUserId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already in your circle.')),
      );
      return;
    }

    try {
      await _friendService.addFriend(friendUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend added.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add friend: $e')),
      );
    }
  }

  Future<void> _uploadPost() async {
    final caption = await _askForCaption();
    if (caption == null) return;
    if (caption.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption before posting.')),
      );
      return;
    }

    setState(() => _isPosting = true);
    try {
      final imageUrl = await _uploader.pickAndUploadImage(
          processingOptions: ImageProcessingOptions.postDefault);
      if (imageUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No photo selected.')),
        );
        return;
      }

      await _postService.createPost(imageUrl, caption: caption);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading post: $e')));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<String?> _askForCaption() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _CaptionDialog(),
    );
  }

  Future<void> _toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like posts.')),
      );
      return;
    }

    try {
      await _postService.toggleLike(postId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update like: $e')),
      );
    }
  }

  Future<void> _showLikesSheet(List<String> likedUserIds) {
    return showLikesBottomSheet(context, likedUserIds);
  }

  Future<void> _openComments(String postId) {
    return showCommentsBottomSheet(context, postId: postId);
  }

  void _openPostDetail(String postId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailPage(postId: postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildFeed(),
          if (_isPosting)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.leather,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    final stream = _repository.postsFeedStream();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildFeedContainer(
            _FeedMessage(
              message: 'We could not load the social feed.',
              actionLabel: 'Retry',
              onAction: () => setState(() {}),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildFeedContainer(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final hasPosts = docs.isNotEmpty;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: hasPosts ? docs.length + 1 : 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSocialHeader();
            }

            if (!hasPosts) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: _FeedMessage(
                  message: 'No posts yet.\nBe the first to raise a glass!',
                ),
              );
            }

            final doc = docs[index - 1];
            final data = doc.data();
            final imageUrl = data['imageUrl'] as String?;
            final firstName = (data['firstName'] as String?)?.trim();
            final lastName = (data['lastName'] as String?)?.trim();
            final displayName = (data['displayName'] as String?)?.trim();
            final email = (data['email'] as String?)?.trim();
            final resolvedName = _resolvePostAuthorName(
              firstName: firstName,
              lastName: lastName,
              displayName: displayName,
              fallbackEmail: email,
            );
            final caption = (data['caption'] as String? ?? '').trim();
            final timestamp = _coerceTimestamp(data['timestamp']);
            final likedBy =
                List<String>.from((data['likedBy'] as List<dynamic>? ?? []));
            final likeCount = data['likeCount'] as int? ?? likedBy.length;
            final commentCount = data['commentCount'] as int? ?? 0;
            final postOwnerId = data['userId'] as String?;
            final currentUserId = _auth.currentUser?.uid;
            final isLiked =
                currentUserId != null && likedBy.contains(currentUserId);
            bool alreadyFriend = false;
            VoidCallback? addFriendCallback;
            if (postOwnerId != null &&
                currentUserId != null &&
                postOwnerId != currentUserId) {
              alreadyFriend = _followingIds.contains(postOwnerId);
              if (!alreadyFriend) {
                addFriendCallback = () => _addFriend(postOwnerId);
              }
            }

            return _PostCard(
              authorLabel: resolvedName,
              timestamp: timestamp,
              imageUrl: imageUrl,
              caption: caption,
              likeCount: likeCount,
              commentCount: commentCount,
              isLiked: isLiked,
              onToggleLike: () => _toggleLike(doc.id),
              onShowLikes: () => _showLikesSheet(likedBy),
              onOpenComments: () => _openComments(doc.id),
              onAddFriend: addFriendCallback,
              onTap: () => _openPostDetail(doc.id),
            );
          },
        );
      },
    );
  }

  Widget _buildFeedContainer(Widget child) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildSocialHeader(),
        child,
      ],
    );
  }

  Widget _buildSocialHeader() {
    final user = _auth.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? 'Member');
    final initials = _initialsFor(displayName);
    final photoUrl = user?.photoURL;

    Widget avatar;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      avatar = CircleAvatar(
        radius: 26,
        backgroundImage: NetworkImage(photoUrl),
      );
    } else {
      avatar = CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.leather.withValues(alpha: 0.2),
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.leather,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          avatar,
          const Spacer(),
          _HeaderActionButton(
            tooltip: 'New Post',
            onPressed: _isPosting ? null : _uploadPost,
            child: _isPosting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add, size: 22),
          ),
          const SizedBox(width: 12),
          _HeaderActionButton(
            tooltip: 'Search Members',
            onPressed: _openUserSearchDialog,
            child: const Icon(Icons.search_rounded, size: 22),
          ),
        ],
      ),
    );
  }

  void _openUserSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Find Members',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.darkGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _UserLookupSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final borderColor = isDisabled
        ? AppColors.leather.withValues(alpha: 0.4)
        : AppColors.leather;
    final iconColor = borderColor;

    final button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        alignment: Alignment.center,
        child: IconTheme.merge(
          data: IconThemeData(color: iconColor, size: 22),
          child: child,
        ),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }
}

class _UserPostsList extends StatefulWidget {
  const _UserPostsList({
    required this.userId,
    required this.repository,
  });

  final String userId;
  final FirestoreRepository repository;

  @override
  State<_UserPostsList> createState() => _UserPostsListState();
}

class _UserPostsListState extends State<_UserPostsList> {
  final PostService _postService = PostService();

  void _openPostDetail(String postId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailPage(postId: postId),
      ),
    );
  }

  Future<void> _deletePost(BuildContext context, String postId) async {
    final confirmed = await _confirmDeletion(
      context,
      title: 'Delete post',
      message: 'This will remove the post and its comments. Continue?',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => _postService.deletePost(postId),
      successMessage: 'Post deleted.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.repository.userPostsStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FeedMessage(
            message: 'We could not load your posts.',
            actionLabel: 'Retry',
            onAction: () => setState(() {}),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'You have not shared any posts yet.',
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final firstName = (data['firstName'] as String?)?.trim();
            final lastName = (data['lastName'] as String?)?.trim();
            final displayName = (data['displayName'] as String?)?.trim();
            final email = (data['email'] as String?)?.trim();
            final likedBy =
                List<String>.from((data['likedBy'] as List<dynamic>? ?? []));
            final likeCount = data['likeCount'] as int? ?? likedBy.length;
            final commentCount = data['commentCount'] as int? ?? 0;
            return _PostCard(
              authorLabel: _resolvePostAuthorName(
                firstName: firstName,
                lastName: lastName,
                displayName: displayName,
                fallbackEmail: email ?? 'You',
              ),
              timestamp: _coerceTimestamp(data['timestamp']),
              imageUrl: data['imageUrl'] as String?,
              caption: (data['caption'] as String? ?? '').trim(),
              likeCount: likeCount,
              commentCount: commentCount,
              onShowLikes: () => showLikesBottomSheet(context, likedBy),
              onOpenComments: () =>
                  showCommentsBottomSheet(context, postId: doc.id),
              onDelete: () => _deletePost(context, doc.id),
              onTap: () => _openPostDetail(doc.id),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RelationshipList extends StatefulWidget {
  const _RelationshipList({
    required this.userId,
    required this.collection,
    required this.emptyLabel,
    required this.title,
  });

  final String userId;
  final String collection;
  final String emptyLabel;
  final String title;

  @override
  State<_RelationshipList> createState() => _RelationshipListState();
}

class _RelationshipListState extends State<_RelationshipList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendService _friendService = FriendService();
  final Set<String> _pending = <String>{};

  bool get _isOwnProfile => _auth.currentUser?.uid == widget.userId;

  Future<void> _followUser(String targetId) async {
    final current = _auth.currentUser;
    if (current == null) {
      _showSnack('Sign in to follow members.');
      return;
    }
    if (current.uid == targetId) {
      _showSnack('You cannot follow yourself.');
      return;
    }
    setState(() => _pending.add(targetId));
    try {
      final targetDoc =
          await _firestore.collection('users').doc(targetId).get();
      if (!targetDoc.exists) {
        throw Exception('Member not found.');
      }
      final targetData = targetDoc.data() ?? const <String, dynamic>{};
      final targetDisplayName =
          (targetData['displayName'] as String?)?.trim() ?? '';
      final targetEmail = (targetData['email'] as String?)?.trim();
      await _friendService.addFriend(targetId);
      final friendlyTargetName = targetDisplayName.isNotEmpty
          ? targetDisplayName
          : (targetEmail ?? 'member');
      _showSnack('Now following $friendlyTargetName.');
    } catch (e) {
      _showSnack('Could not follow: $e');
    } finally {
      if (mounted) {
        setState(() => _pending.remove(targetId));
      }
    }
  }

  Future<void> _unfollowUser(String targetId) async {
    final current = _auth.currentUser;
    if (current == null) {
      _showSnack('Sign in to manage follows.');
      return;
    }
    setState(() => _pending.add(targetId));
    try {
      await _friendService.removeFriend(targetId);
      _showSnack('Unfollowed.');
    } catch (e) {
      _showSnack('Could not update follow: $e');
    } finally {
      if (mounted) {
        setState(() => _pending.remove(targetId));
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection(widget.collection)
        .orderBy('addedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.darkGreen),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (snapshot.hasError)
              const Expanded(
                child: Center(
                  child: Text('Could not load relationships.'),
                ),
              )
            else if (docs.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    widget.emptyLabel,
                    style: const TextStyle(color: AppColors.leatherDark),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final name =
                        (data['displayName'] as String? ?? 'Whiskey Friend')
                            .trim();
                    final targetUserId = (data['userId'] as String?)?.trim();
                    final resolvedTargetId =
                        (targetUserId != null && targetUserId.isNotEmpty)
                            ? targetUserId
                            : doc.id;
                    final addedAt = data['addedAt'];
                    final timestamp = addedAt is Timestamp
                        ? addedAt.toDate()
                        : DateTime.tryParse(addedAt?.toString() ?? '') ??
                            DateTime.now();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.darkGreen,
                        foregroundColor: AppColors.onDark,
                        child: Text(_initialsFor(name)),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        'Since ${timestamp.month}/${timestamp.day}/${timestamp.year}',
                      ),
                      trailing: _buildActionButton(resolvedTargetId),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(String targetUserId) {
    final currentUserId = _auth.currentUser?.uid;
    if (!_isOwnProfile ||
        currentUserId == null ||
        currentUserId == targetUserId) {
      return const SizedBox.shrink();
    }
    final isFollowingList = widget.collection == 'following';
    final isPending = _pending.contains(targetUserId);

    if (isFollowingList) {
      return TextButton(
        onPressed: isPending ? null : () => _unfollowUser(targetUserId),
        child: isPending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Unfollow'),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data?.exists ?? false;
        final busy = _pending.contains(targetUserId);
        if (isFollowing && widget.collection == 'followers') {
          return SizedBox(
            width: 90,
            child: Text(
              'Already\nFollowing',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.leatherDark.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          );
        }
        return TextButton(
          onPressed: busy
              ? null
              : () => isFollowing
                  ? _unfollowUser(targetUserId)
                  : _followUser(targetUserId),
          child: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isFollowing ? 'Unfollow' : 'Follow'),
        );
      },
    );
  }
}
