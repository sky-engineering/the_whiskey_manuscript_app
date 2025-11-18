import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'services/post_uploader.dart';
import 'services/post_service.dart';
import 'services/whiskey_service.dart';
import 'services/distillery_service.dart';
import 'services/article_service.dart';
import 'services/merchandise_service.dart';
import 'services/friend_service.dart';
import 'services/message_service.dart';
import 'services/event_service.dart';

/// Centralized access to the Whiskey Manuscript palette.
class AppColors {
  static const Color leather = Color(0xFF6A4A3C);
  static const Color leatherLight = Color(0xFF8A6956);
  static const Color leatherDark = Color(0xFF4F362C);

  static const Color darkGreen = Color(0xFF2E3F34);
  static const Color greenLight = Color(0xFF415346);
  static const Color greenDark = Color(0xFF1F2A22);

  static const Color lightNeutral = Color(0xFFE9E4D8);
  static const Color neutralLight = Color(0xFFF4F2EC);
  static const Color neutralMid = Color(0xFFCFC8BA);

  static const Color onDark = neutralLight;
}

const List<String> membershipLevels = ['Neat', 'Cask', 'Manuscript'];

const Map<String, String> membershipDescriptions = {
  'Neat': 'Classic access to the community, social feed, and curated stories.',
  'Cask': 'Extended perks including event RSVPs and deeper content drops.',
  'Manuscript':
      'Full access to rare releases, private salons, and archival notes.',
};

const List<String> whiskeyStyles = [
  'Single Malt',
  'Blend',
  'Bourbon',
  'Rye',
  'Cask Strength',
  'Other',
];

const List<String> distillerySpotlights = [
  'Heritage House',
  'Experimental Lab',
  'Independent Bottler',
  'New World Grain',
  'Peated Specialist',
  'Other',
];

const List<String> articleCategories = [
  'Tasting Notes',
  'Distillery Story',
  'Travel',
  'Education',
  'Release News',
  'Other',
];

const List<String> merchCategories = [
  'Apparel',
  'Glassware',
  'Books',
  'Art',
  'Membership',
  'Other',
];

Future<void> _ensureUserProfileDocument(User user) async {
  final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final snapshot = await docRef.get();
  final baseData = <String, dynamic>{
    'email': user.email,
    'displayName': user.displayName,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  if (!snapshot.exists) {
    await docRef.set({
      ...baseData,
      'membershipLevel': membershipLevels.first,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return;
  }

  await docRef.set(baseData, SetOptions(merge: true));
  final existingLevel = snapshot.data()?['membershipLevel'] as String?;
  if (existingLevel == null) {
    await docRef.set(
        {'membershipLevel': membershipLevels.first}, SetOptions(merge: true));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Whiskey Manuscript',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.darkGreen,
          onPrimary: AppColors.onDark,
          secondary: AppColors.leather,
          onSecondary: AppColors.onDark,
          error: Color(0xFFB3261E),
          onError: AppColors.onDark,
          background: AppColors.neutralLight,
          onBackground: AppColors.darkGreen,
          surface: AppColors.lightNeutral,
          onSurface: AppColors.darkGreen,
        ),
        scaffoldBackgroundColor: AppColors.neutralLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkGreen,
          foregroundColor: AppColors.onDark,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) return const DashboardShell();
        return const SignInPage();
      },
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (credential.user != null) {
        await _ensureUserProfileDocument(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _register() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (credential.user != null) {
        await _ensureUserProfileDocument(credential.user!);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to continue')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'The Whiskey Manuscript',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an account or sign in to see your personalized pours, events, and groups.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.leatherDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _isBusy ? null : _signIn,
                          child: _isBusy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isBusy ? null : _register,
                          child: const Text('Register'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, this.configs});

  final List<DashboardTabConfig>? configs;

  static const List<DashboardTabConfig> defaultTabs = [
    DashboardTabConfig(
        label: 'Social', icon: Icons.groups_rounded, view: SocialPage()),
    DashboardTabConfig(
        label: 'Content', icon: Icons.menu_book_rounded, view: ContentPage()),
    DashboardTabConfig(
        label: 'Messages',
        icon: Icons.chat_bubble_rounded,
        view: MessagesPage()),
    DashboardTabConfig(
        label: 'Events',
        icon: Icons.event_available_rounded,
        view: EventsPage()),
    DashboardTabConfig(
        label: 'Profile', icon: Icons.person_rounded, view: ProfilePage()),
  ];

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  late final List<DashboardTabConfig> _pageConfigs =
      widget.configs ?? DashboardShell.defaultTabs;

  void _onItemTapped(int newIndex) {
    if (newIndex == _selectedIndex) return;
    setState(() => _selectedIndex = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pageConfigs[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPage.label),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: currentPage.view,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          for (final config in _pageConfigs)
            NavigationDestination(
              icon: Icon(config.icon),
              label: config.label,
            ),
        ],
      ),
    );
  }
}

class DashboardTabConfig {
  final String label;
  final IconData icon;
  final Widget view;

  const DashboardTabConfig({
    required this.label,
    required this.icon,
    required this.view,
  });
}

/// ------------------------------------------------------------
/// SOCIAL PAGE WITH CAPTIONS + POSTER EMAIL + TIMESTAMP
/// ------------------------------------------------------------
class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final PostUploader _uploader = PostUploader();
  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<User?>? _authSub;
  Set<String> _friendIds = <String>{};
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _listenForFriends();
    _authSub = _auth.userChanges().listen((_) {
      _listenForFriends();
    });
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _listenForFriends() {
    final userId = _auth.currentUser?.uid;
    _friendsSub?.cancel();
    if (userId == null) {
      if (mounted) {
        setState(() {
          _friendIds = <String>{};
        });
      }
      return;
    }

    _friendsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _friendIds = snapshot.docs.map((doc) => doc.id).toSet();
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

    if (_friendIds.contains(friendUserId)) {
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
      final imageUrl = await _uploader.pickAndUploadImage();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.leather,
        foregroundColor: AppColors.onDark,
        onPressed: _isPosting ? null : _uploadPost,
        child: _isPosting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onDark),
                ),
              )
            : const Icon(Icons.add_a_photo_rounded),
      ),
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
    final stream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FeedMessage(
            message: 'We could not load the social feed.',
            actionLabel: 'Retry',
            onAction: () => setState(() {}),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'No posts yet.\nBe the first to raise a glass!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final imageUrl = data['imageUrl'] as String?;
            final email = data['email'] as String? ?? 'Unknown user';
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
            final canAddFriend = postOwnerId != null &&
                currentUserId != null &&
                postOwnerId != currentUserId;
            final alreadyFriend = canAddFriend &&
                postOwnerId != null &&
                _friendIds.contains(postOwnerId);
            final VoidCallback? addFriendCallback =
                (!alreadyFriend && canAddFriend && postOwnerId != null)
                    ? () => _addFriend(postOwnerId)
                    : null;

            return _PostCard(
              authorLabel: email,
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
              isFriend: alreadyFriend,
            );
          },
        );
      },
    );
  }
}

class _UserPostsList extends StatefulWidget {
  const _UserPostsList({super.key, required this.userId});

  final String userId;

  @override
  State<_UserPostsList> createState() => _UserPostsListState();
}

class _UserPostsListState extends State<_UserPostsList> {
  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
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
            final likedBy =
                List<String>.from((data['likedBy'] as List<dynamic>? ?? []));
            final likeCount = data['likeCount'] as int? ?? likedBy.length;
            final commentCount = data['commentCount'] as int? ?? 0;
            return _PostCard(
              authorLabel: (data['email'] as String? ?? 'You').trim(),
              timestamp: _coerceTimestamp(data['timestamp']),
              imageUrl: data['imageUrl'] as String?,
              caption: (data['caption'] as String? ?? '').trim(),
              likeCount: likeCount,
              commentCount: commentCount,
              onShowLikes: () => showLikesBottomSheet(context, likedBy),
              onOpenComments: () =>
                  showCommentsBottomSheet(context, postId: doc.id),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FriendSummary extends StatelessWidget {
  const _FriendSummary({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        final label = count == 1 ? '1 friend' : '$count friends';
        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.leather,
            ),
            onPressed: () => showFriendsBottomSheet(context, userId: userId),
            icon: const Icon(Icons.people_alt_rounded),
            label: Text(label),
          ),
        );
      },
    );
  }
}

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
    this.isFriend = false,
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
  final bool isFriend;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.leatherDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAddFriend != null || isFriend)
                  IconButton(
                    onPressed: isFriend ? null : onAddFriend,
                    tooltip: isFriend ? 'Friends' : 'Add friend',
                    icon: Icon(
                      isFriend ? Icons.person_rounded : Icons.person_add_alt_1,
                      color:
                          isFriend ? AppColors.leather : AppColors.leatherDark,
                    ),
                  ),
              ],
            ),
          ),
          if (imageUrl != null)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 300,
            ),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                caption,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          if ((onToggleLike != null || likeCount != null) ||
              onOpenComments != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 24,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onToggleLike != null || likeCount != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onToggleLike != null) ...[
                          IconButton(
                            onPressed: onToggleLike,
                            icon: Icon(
                              isLiked == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isLiked == true
                                  ? AppColors.leather
                                  : AppColors.leatherDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _LikeCountLabel(
                          label: _formatLikeLabel(likeCount ?? 0),
                          onTap: onShowLikes,
                        ),
                      ],
                    ),
                  if (onOpenComments != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: onOpenComments,
                          icon: const Icon(
                            Icons.mode_comment_outlined,
                            color: AppColors.leatherDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onOpenComments,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            child: Text(
                              _formatCommentLabel(commentCount ?? 0),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.leatherDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime timestamp) =>
      '${timestamp.month}/${timestamp.day}/${timestamp.year}';

  static String _formatLikeLabel(int count) =>
      '$count ${count == 1 ? 'like' : 'likes'}';

  static String _formatCommentLabel(int count) =>
      '$count ${count == 1 ? 'comment' : 'comments'}';
}

class _LikeCountLabel extends StatelessWidget {
  const _LikeCountLabel({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.leatherDark,
      ),
    );

    if (onTap == null) return text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: text,
      ),
    );
  }
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
      child: _CommentsBottomSheet(postId: postId),
    ),
  );
}

class _CommentsBottomSheet extends StatefulWidget {
  const _CommentsBottomSheet({required this.postId});

  final String postId;

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
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
              'Comments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.darkGreen, fontWeight: FontWeight.w600),
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

class _UserWhiskeyList extends StatelessWidget {
  const _UserWhiskeyList({super.key, required this.userId});

  final String userId;

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
              _WhiskeyCard(
                whiskeyName: doc.data()['name'] as String? ?? 'Untitled Bottle',
                style: doc.data()['style'] as String? ?? 'Special Release',
                region: doc.data()['region'] as String? ?? 'Unknown region',
                notes: doc.data()['notes'] as String? ?? '',
                authorLabel: 'You',
                membership: doc.data()['membershipLevel'] as String?,
                timestamp: _coerceTimestamp(doc.data()['createdAt']),
                showAuthor: false,
              ),
          ],
        );
      },
    );
  }
}

class _WhiskeyCard extends StatelessWidget {
  const _WhiskeyCard({
    super.key,
    required this.whiskeyName,
    required this.style,
    required this.region,
    required this.notes,
    required this.authorLabel,
    required this.timestamp,
    this.membership,
    this.showAuthor = true,
  });

  final String whiskeyName;
  final String style;
  final String region;
  final String notes;
  final String authorLabel;
  final DateTime timestamp;
  final String? membership;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final descriptionStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppColors.leatherDark);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        whiskeyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style,
                        style: descriptionStyle,
                      ),
                    ],
                  ),
                ),
                if (membership != null)
                  Chip(
                    label: Text(membership!),
                    backgroundColor: AppColors.neutralLight,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Region - $region', style: descriptionStyle),
            const SizedBox(height: 8),
            if (notes.isNotEmpty)
              Text(
                notes,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.darkGreen),
              ),
            if (showAuthor) ...[
              const SizedBox(height: 12),
              Text(
                'Shared by ' +
                    authorLabel +
                    ' on ' +
                    '${timestamp.month}/${timestamp.day}/${timestamp.year}',
                style: descriptionStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddWhiskeySheet extends StatefulWidget {
  const _AddWhiskeySheet({super.key});

  @override
  State<_AddWhiskeySheet> createState() => _AddWhiskeySheetState();
}

class _AddWhiskeySheetState extends State<_AddWhiskeySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _notesController = TextEditingController();
  String _style = whiskeyStyles.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await WhiskeyService().addWhiskey(
        name: _nameController.text,
        region: _regionController.text,
        notes: _notesController.text,
        style: _style,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add whiskey: ' + e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a Whiskey',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Whiskey Name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _style,
              decoration: const InputDecoration(labelText: 'Style'),
              items: [
                for (final style in whiskeyStyles)
                  DropdownMenuItem(
                    value: style,
                    child: Text(style),
                  ),
              ],
              onChanged: (value) => setState(() => _style = value ?? _style),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _regionController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Region / Distillery (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Tasting Notes'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save to Library'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _UserDistilleryList extends StatelessWidget {
  const _UserDistilleryList({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('distilleries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your distilleries.',
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
            message: 'Spotlight a distillery to remember the story.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              _DistilleryCard(
                name: doc.data()['name'] as String? ?? 'Untitled Distillery',
                location:
                    doc.data()['location'] as String? ?? 'Unknown location',
                story: doc.data()['story'] as String? ?? '',
                signaturePour: doc.data()['signaturePour'] as String? ??
                    'House pour unknown',
                authorLabel: 'You',
                membership: doc.data()['membershipLevel'] as String?,
                timestamp: _coerceTimestamp(doc.data()['createdAt']),
                showAuthor: false,
              ),
          ],
        );
      },
    );
  }
}

class _DistilleryCard extends StatelessWidget {
  const _DistilleryCard({
    required this.name,
    required this.location,
    required this.story,
    required this.signaturePour,
    required this.authorLabel,
    required this.timestamp,
    this.membership,
    this.showAuthor = true,
  });

  final String name;
  final String location;
  final String story;
  final String signaturePour;
  final String authorLabel;
  final DateTime timestamp;
  final String? membership;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final descriptionStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppColors.leatherDark);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(location, style: descriptionStyle),
                    ],
                  ),
                ),
                if (membership != null)
                  Chip(
                    label: Text(membership!),
                    backgroundColor: AppColors.neutralLight,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Signature pour - $signaturePour', style: descriptionStyle),
            const SizedBox(height: 8),
            if (story.isNotEmpty)
              Text(
                story,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.darkGreen),
              ),
            if (showAuthor) ...[
              const SizedBox(height: 12),
              Text(
                'Shared by ' +
                    authorLabel +
                    ' on '
                        ' \${timestamp.month}/\${timestamp.day}/\${timestamp.year}',
                style: descriptionStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddDistillerySheet extends StatefulWidget {
  const _AddDistillerySheet({super.key});

  @override
  State<_AddDistillerySheet> createState() => _AddDistillerySheetState();
}

class _AddDistillerySheetState extends State<_AddDistillerySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _storyController = TextEditingController();
  final _pourController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _storyController.dispose();
    _pourController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await DistilleryService().addDistillery(
        name: _nameController.text,
        location: _locationController.text,
        story: _storyController.text,
        signaturePour: _pourController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not add distillery: ' + e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a Distillery',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Distillery Name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Location / Region'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pourController,
              decoration: const InputDecoration(labelText: 'Signature Pour'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _storyController,
              maxLines: 4,
              decoration:
                  const InputDecoration(labelText: 'Story / Why it matters'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Distillery'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _UserArticleList extends StatelessWidget {
  const _UserArticleList({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('articles')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your articles.',
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
            message: 'Capture a story or tasting reflection.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              _ArticleCard(
                title: doc.data()['title'] as String? ?? 'Untitled Article',
                summary: doc.data()['summary'] as String? ?? '',
                link: doc.data()['link'] as String? ?? '',
                category: doc.data()['category'] as String? ?? 'Story',
                authorLabel: 'You',
                membership: doc.data()['membershipLevel'] as String?,
                timestamp: _coerceTimestamp(doc.data()['createdAt']),
                showAuthor: false,
              ),
          ],
        );
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.title,
    required this.summary,
    required this.link,
    required this.category,
    required this.authorLabel,
    required this.timestamp,
    this.membership,
    this.showAuthor = true,
  });

  final String title;
  final String summary;
  final String link;
  final String category;
  final String authorLabel;
  final DateTime timestamp;
  final String? membership;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final descriptionStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppColors.leatherDark);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(category, style: descriptionStyle),
                    ],
                  ),
                ),
                if (membership != null)
                  Chip(
                    label: Text(membership!),
                    backgroundColor: AppColors.neutralLight,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (summary.isNotEmpty)
              Text(
                summary,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.darkGreen),
              ),
            const SizedBox(height: 8),
            if (link.isNotEmpty)
              Text(
                link,
                style: const TextStyle(
                  color: AppColors.leather,
                  decoration: TextDecoration.underline,
                ),
              ),
            if (showAuthor) ...[
              const SizedBox(height: 12),
              Text(
                'Shared by $authorLabel on ${timestamp.month}/${timestamp.day}/${timestamp.year}',
                style: descriptionStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddArticleSheet extends StatefulWidget {
  const _AddArticleSheet({super.key});

  @override
  State<_AddArticleSheet> createState() => _AddArticleSheetState();
}

class _AddArticleSheetState extends State<_AddArticleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _linkController = TextEditingController();
  String _category = articleCategories.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ArticleService().addArticle(
        title: _titleController.text,
        summary: _summaryController.text,
        link: _linkController.text,
        category: _category,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add article: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add an Article',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in articleCategories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'Link (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _summaryController,
              maxLines: 4,
              decoration:
                  const InputDecoration(labelText: 'Summary / pull quote'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _UserMerchList extends StatelessWidget {
  const _UserMerchList({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('merch')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your merchandise.',
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
            message: 'No items yet. Add your first piece.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              _MerchCard(
                title: doc.data()['title'] as String? ?? 'Untitled Item',
                description: doc.data()['description'] as String? ?? '',
                price: (doc.data()['price'] as num? ?? 0).toDouble(),
                link: doc.data()['link'] as String? ?? '',
                category: doc.data()['category'] as String? ?? 'Lifestyle',
                authorLabel: 'You',
                membership: doc.data()['membershipLevel'] as String?,
                timestamp: _coerceTimestamp(doc.data()['createdAt']),
                showAuthor: false,
              ),
          ],
        );
      },
    );
  }
}

class _MerchCard extends StatelessWidget {
  const _MerchCard({
    required this.title,
    required this.description,
    required this.price,
    required this.link,
    required this.category,
    required this.authorLabel,
    required this.timestamp,
    this.membership,
    this.showAuthor = true,
  });

  final String title;
  final String description;
  final double price;
  final String link;
  final String category;
  final String authorLabel;
  final DateTime timestamp;
  final String? membership;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    final descriptionStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: AppColors.leatherDark);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$category  -  \$${price.toStringAsFixed(2)}',
                        style: descriptionStyle,
                      ),
                    ],
                  ),
                ),
                if (membership != null)
                  Chip(
                    label: Text(membership!),
                    backgroundColor: AppColors.neutralLight,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (description.isNotEmpty)
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.darkGreen),
              ),
            const SizedBox(height: 8),
            if (link.isNotEmpty)
              Text(
                link,
                style: const TextStyle(
                  color: AppColors.leather,
                  decoration: TextDecoration.underline,
                ),
              ),
            if (showAuthor) ...[
              const SizedBox(height: 12),
              Text(
                'Shared by $authorLabel on ${timestamp.month}/${timestamp.day}/${timestamp.year}',
                style: descriptionStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddMerchSheet extends StatefulWidget {
  const _AddMerchSheet({super.key});

  @override
  State<_AddMerchSheet> createState() => _AddMerchSheetState();
}

class _AddMerchSheetState extends State<_AddMerchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _priceController = TextEditingController();
  String _category = merchCategories.first;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await MerchandiseService().addItem(
        title: _titleController.text,
        description: _descriptionController.text,
        link: _linkController.text,
        category: _category,
        price: double.tryParse(_priceController.text) ?? 0,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add item: ')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Merchandise',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in merchCategories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (USD)'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Required';
                return double.tryParse(value) == null
                    ? 'Enter a valid number'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'Purchase Link'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Item'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({super.key});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _detailsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await EventService().addEvent(
        title: _titleController.text,
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
        location: _locationController.text,
        details: _detailsController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add event: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}';
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Event',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Event Title'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Location / Venue'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickDate,
              icon: const Icon(Icons.event),
              label: Text('Date: ' + dateLabel),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Details / Notes'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Event'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CaptionDialog extends StatefulWidget {
  const _CaptionDialog({super.key});

  @override
  State<_CaptionDialog> createState() => _CaptionDialogState();
}

class _CaptionDialogState extends State<_CaptionDialog> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Caption'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Say something about your pour...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _FeedMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FeedMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.darkGreen),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// OTHER PAGES LEFT UNCHANGED FOR BREVITY
class ContentPage extends StatelessWidget {
  const ContentPage({super.key});

  void _openDatabaseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LibraryDatabaseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Whiskey Manuscript Database',
                style:
                    textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openDatabaseSheet(context),
              icon: const Icon(Icons.table_rows_rounded),
              label: const Text('Browse All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MerchandisePage()),
          ),
          icon: const Icon(Icons.shopping_bag_rounded),
          label: const Text('Visit Merchandise'),
        ),
        const SizedBox(height: 32),
        Text(
          'Featured Whiskeys',
          style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
        ),
        const SizedBox(height: 12),
        const _GlobalWhiskeyFeed(),
        const SizedBox(height: 32),
        Text(
          'Distillery Spotlights',
          style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
        ),
        const SizedBox(height: 12),
        const _GlobalDistilleryFeed(),
        const SizedBox(height: 32),
        Text(
          'Community Articles',
          style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
        ),
        const SizedBox(height: 12),
        const _GlobalArticleFeed(),
      ],
    );
  }
}

class _ShowcaseData {
  final String title;
  final String subtitle;
  final String footer;
  final String? badge;

  const _ShowcaseData({
    required this.title,
    required this.subtitle,
    required this.footer,
    this.badge,
  });
}

class _HorizontalShowcase extends StatelessWidget {
  const _HorizontalShowcase({required this.items});

  final List<_ShowcaseData> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _ShowcaseCard(data: items[index]),
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({required this.data});

  final _ShowcaseData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightNeutral,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutralMid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              if (data.badge != null)
                Chip(
                  label: Text(data.badge!),
                  backgroundColor: AppColors.neutralLight,
                ),
            ],
          ),
          const Spacer(),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.leatherDark),
          ),
          const SizedBox(height: 8),
          Text(
            data.footer,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.darkGreen),
          ),
        ],
      ),
    );
  }
}

class _LibraryDatabaseSheet extends StatefulWidget {
  const _LibraryDatabaseSheet({super.key});

  @override
  State<_LibraryDatabaseSheet> createState() => _LibraryDatabaseSheetState();
}

class MerchandisePage extends StatelessWidget {
  const MerchandisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchandise'),
      ),
      body: const _MerchandiseFeed(),
    );
  }
}

class _MerchandiseFeed extends StatelessWidget {
  const _MerchandiseFeed();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('merch')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load merchandise.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'No items have been added yet.',
          );
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            for (final doc in docs)
              _MerchCard(
                title: doc.data()['title'] as String? ?? 'Untitled Item',
                description: doc.data()['description'] as String? ?? '',
                price: (doc.data()['price'] as num? ?? 0).toDouble(),
                link: doc.data()['link'] as String? ?? '',
                category: doc.data()['category'] as String? ?? 'Lifestyle',
                authorLabel: doc.data()['userName'] as String? ?? 'Curator',
                membership: doc.data()['membershipLevel'] as String?,
                timestamp: _coerceTimestamp(doc.data()['createdAt']),
              ),
          ],
        );
      },
    );
  }
}

class _LibraryDatabaseSheetState extends State<_LibraryDatabaseSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _membershipFilter = 'All';

  List<String> get _membershipFilters => ['All', ...membershipLevels];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manuscript Database',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.darkGreen),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search bottles, distilleries, or essays...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final filter in _membershipFilters)
                          ChoiceChip(
                            label: Text(filter),
                            selected: _membershipFilter == filter,
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() => _membershipFilter = filter);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Whiskeys'),
                  Tab(text: 'Distilleries'),
                  Tab(text: 'Articles'),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
                  children: [
                    _DatabaseWhiskeyList(
                        query: _query, membership: _membershipFilter),
                    _DatabaseDistilleryList(
                        query: _query, membership: _membershipFilter),
                    _DatabaseArticleList(
                        query: _query, membership: _membershipFilter),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatabaseWhiskeyList extends StatelessWidget {
  const _DatabaseWhiskeyList({required this.query, required this.membership});

  final String query;
  final String membership;

  bool _matches(Map<String, dynamic> data) {
    final q = query.toLowerCase();
    final target =
        '${data['name'] ?? ''} ${data['style'] ?? ''} ${data['region'] ?? ''} ${data['userName'] ?? ''}'
            .toLowerCase();
    final membershipLevel =
        (data['membershipLevel'] as String? ?? '').toLowerCase();
    final membershipMatch =
        membership == 'All' || membershipLevel == membership.toLowerCase();
    return membershipMatch && (q.isEmpty || target.contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('whiskeys')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return _DatabaseStream(
      stream: stream,
      emptyMessage: 'No whiskeys match your filters yet.',
      itemBuilder: (doc) => _WhiskeyCard(
        whiskeyName: doc['name'] as String? ?? 'Untitled Bottle',
        style: doc['style'] as String? ?? 'Special Release',
        region: doc['region'] as String? ?? 'Unknown region',
        notes: (doc['notes'] as String? ?? '').trim(),
        authorLabel: doc['userName'] as String? ?? 'Explorer',
        membership: doc['membershipLevel'] as String?,
        timestamp: _coerceTimestamp(doc['createdAt']),
      ),
      filter: _matches,
    );
  }
}

class _DatabaseDistilleryList extends StatelessWidget {
  const _DatabaseDistilleryList(
      {required this.query, required this.membership});

  final String query;
  final String membership;

  bool _matches(Map<String, dynamic> data) {
    final q = query.toLowerCase();
    final target =
        '${data['name'] ?? ''} ${data['location'] ?? ''} ${data['userName'] ?? ''}'
            .toLowerCase();
    final membershipLevel =
        (data['membershipLevel'] as String? ?? '').toLowerCase();
    final membershipMatch =
        membership == 'All' || membershipLevel == membership.toLowerCase();
    return membershipMatch && (q.isEmpty || target.contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('distilleries')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return _DatabaseStream(
      stream: stream,
      emptyMessage: 'No distilleries match your filters yet.',
      itemBuilder: (doc) => _DistilleryCard(
        name: doc['name'] as String? ?? 'Untitled Distillery',
        location: doc['location'] as String? ?? 'Unknown location',
        story: doc['story'] as String? ?? '',
        signaturePour: doc['signaturePour'] as String? ?? 'House pour unknown',
        authorLabel: doc['userName'] as String? ?? 'Explorer',
        membership: doc['membershipLevel'] as String?,
        timestamp: _coerceTimestamp(doc['createdAt']),
      ),
      filter: _matches,
    );
  }
}

class _DatabaseArticleList extends StatelessWidget {
  const _DatabaseArticleList({required this.query, required this.membership});

  final String query;
  final String membership;

  bool _matches(Map<String, dynamic> data) {
    final q = query.toLowerCase();
    final target =
        '${data['title'] ?? ''} ${data['summary'] ?? ''} ${data['category'] ?? ''} ${data['userName'] ?? ''}'
            .toLowerCase();
    final membershipLevel =
        (data['membershipLevel'] as String? ?? '').toLowerCase();
    final membershipMatch =
        membership == 'All' || membershipLevel == membership.toLowerCase();
    return membershipMatch && (q.isEmpty || target.contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('articles')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return _DatabaseStream(
      stream: stream,
      emptyMessage: 'No articles match your filters yet.',
      itemBuilder: (doc) => _ArticleCard(
        title: doc['title'] as String? ?? 'Untitled Article',
        summary: doc['summary'] as String? ?? '',
        link: doc['link'] as String? ?? '',
        category: doc['category'] as String? ?? 'Story',
        authorLabel: doc['userName'] as String? ?? 'Contributor',
        membership: doc['membershipLevel'] as String?,
        timestamp: _coerceTimestamp(doc['createdAt']),
      ),
      filter: _matches,
    );
  }
}

class _DatabaseStream extends StatelessWidget {
  const _DatabaseStream({
    required this.stream,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.filter,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final Widget Function(Map<String, dynamic> data) itemBuilder;
  final String emptyMessage;
  final bool Function(Map<String, dynamic>) filter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _FeedMessage(message: emptyMessage);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((doc) => filter(doc.data())).toList();
        if (filtered.isEmpty) {
          return _FeedMessage(message: emptyMessage);
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            for (final doc in filtered) itemBuilder(doc.data()),
          ],
        );
      },
    );
  }
}

class _GlobalWhiskeyFeed extends StatelessWidget {
  const _GlobalWhiskeyFeed();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('whiskeys')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load the whiskey library.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'No whiskeys yet. Add one from your profile!',
          );
        }

        final items = [
          for (final doc in docs)
            _ShowcaseData(
              title: doc.data()['name'] as String? ?? 'Untitled Bottle',
              subtitle: doc.data()['style'] as String? ?? 'Release',
              footer: doc.data()['region'] as String? ?? 'Unknown region',
              badge: doc.data()['membershipLevel'] as String?,
            ),
        ];

        return _HorizontalShowcase(items: items);
      },
    );
  }
}

class _GlobalArticleFeed extends StatelessWidget {
  const _GlobalArticleFeed();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('articles')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load articles.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'No articles yet. Be the first to share insight!',
          );
        }

        final items = [
          for (final doc in docs)
            _ShowcaseData(
              title: doc.data()['title'] as String? ?? 'Untitled Article',
              subtitle: doc.data()['category'] as String? ?? 'Story',
              footer: doc.data()['userName'] as String? ?? 'Contributor',
              badge: doc.data()['membershipLevel'] as String?,
            ),
        ];
        return _HorizontalShowcase(items: items);
      },
    );
  }
}

class _GlobalDistilleryFeed extends StatelessWidget {
  const _GlobalDistilleryFeed();

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('distilleries')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load distilleries yet.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'No distilleries yet. Add one from your profile!',
          );
        }

        final items = [
          for (final doc in docs)
            _ShowcaseData(
              title: doc.data()['name'] as String? ?? 'Untitled Distillery',
              subtitle: doc.data()['location'] as String? ?? 'Unknown location',
              footer:
                  doc.data()['signaturePour'] as String? ?? 'Signature pour',
              badge: doc.data()['membershipLevel'] as String?,
            ),
        ];
        return _HorizontalShowcase(items: items);
      },
    );
  }
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MessageService _messageService = MessageService();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _friendsSub;
  StreamSubscription<User?>? _authSub;
  List<_FriendOption> _friends = const [];

  @override
  void initState() {
    super.initState();
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

    _friendsSub = FirebaseFirestore.instance
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

    final query = FirebaseFirestore.instance
        .collection('messages')
        .where('toUserId', isEqualTo: user.uid);

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
                stream: query.snapshots(),
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
                      message: 'No messages yet. Start a new conversation.',
                    );
                  }

                  final sortedDocs = List.of(docs)
                    ..sort((a, b) {
                      final aTime = _coerceTimestamp(a.data()['sentAt'])
                          .millisecondsSinceEpoch;
                      final bTime = _coerceTimestamp(b.data()['sentAt'])
                          .millisecondsSinceEpoch;
                      return bTime.compareTo(aTime);
                    });

                  return ListView.separated(
                    itemCount: sortedDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = sortedDocs[index].data();
                      final from =
                          (data['fromDisplayName'] as String? ?? 'Member')
                              .trim();
                      final membership = data['fromMembershipLevel'] as String?;
                      final body = (data['message'] as String? ?? '').trim();
                      final timestamp =
                          _coerceTimestamp(data['sentAt']).toLocal();
                      return _MessageCard(
                        senderName: from,
                        message: body,
                        membership: membership,
                        timestamp: timestamp,
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
            value: _selectedFriendId,
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.membership,
  });

  final String senderName;
  final String message;
  final DateTime timestamp;
  final String? membership;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
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
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.darkGreen,
              ),
            ),
          ],
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
  });

  final String title;
  final String location;
  final String details;
  final DateTime date;

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

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance.collection('events').orderBy('date');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _FeedMessage(
              message: 'We could not load upcoming events.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Events Calendar',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppColors.darkGreen),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track releases, tastings, and meetups hosted by Whiskey Manuscript members.',
                style: TextStyle(color: AppColors.leatherDark),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const Expanded(
                  child: _FeedMessage(
                    message:
                        'No events planned yet. Add one from your profile.',
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final title =
                          (data['title'] as String? ?? 'Private Event').trim();
                      final location =
                          (data['location'] as String? ?? 'TBD').trim();
                      final details = (data['details'] as String? ?? '').trim();
                      final date = _coerceTimestamp(data['date']);
                      return _EventCard(
                        title: title,
                        location: location,
                        details: details,
                        date: date,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _openAddWhiskeySheet(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddWhiskeySheet(),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Whiskey added to your library.')),
      );
    }
  }

  Future<void> _openAddDistillerySheet(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddDistillerySheet(),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Distillery spotlight saved.')),
      );
    }
  }

  Future<void> _openAddArticleSheet(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddArticleSheet(),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article submitted.')),
      );
    }
  }

  Future<void> _openAddEventSheet(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddEventSheet(),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event saved.')),
      );
    }
  }

  Future<void> _openAddMerchSheet(BuildContext context) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddMerchSheet(),
    );
    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merchandise item saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please sign in to view your profile.'),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your profile.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() ?? const <String, dynamic>{};
        final membership =
            (userData['membershipLevel'] as String?) ?? membershipLevels.first;
        final metadata = user.metadata.creationTime;
        final email = user.email ?? 'No email available';
        final displayName = (user.displayName ?? email).trim();
        final initials = _initialsFor(displayName);
        final membershipDescription =
            membershipDescriptions[membership] ?? 'Exclusive experiences.';

        Future<void> updateMembership(String? level) async {
          if (level == null || level == membership) return;
          try {
            await docRef
                .set({'membershipLevel': level}, SetOptions(merge: true));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Membership updated to $level.')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not update: $e')));
            }
          }
        }

        final textTheme = Theme.of(context).textTheme;

        return ListView(
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Your Profile',
              style: textTheme.headlineMedium
                  ?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.darkGreen,
                          foregroundColor: AppColors.onDark,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                    color: AppColors.leatherDark),
                              ),
                              if (metadata != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Member since ${metadata.month}/${metadata.day}/${metadata.year}',
                                  style: const TextStyle(
                                      color: AppColors.leatherDark),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Membership Level',
                      style: textTheme.titleMedium
                          ?.copyWith(color: AppColors.darkGreen),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: membership,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: AppColors.lightNeutral,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final level in membershipLevels)
                          DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                      ],
                      onChanged: updateMembership,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      membershipDescription,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.leatherDark),
                    ),
                    const SizedBox(height: 16),
                    _FriendSummary(userId: user.uid),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Whiskey Library',
                    style: textTheme.titleLarge
                        ?.copyWith(color: AppColors.darkGreen),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddWhiskeySheet(context),
                  icon: const Icon(Icons.local_bar_rounded),
                  label: const Text('Add Whiskey'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Favorite Distilleries',
                    style: textTheme.titleLarge
                        ?.copyWith(color: AppColors.darkGreen),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddDistillerySheet(context),
                  icon: const Icon(Icons.factory_rounded),
                  label: const Text('Add Distillery'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Articles & Essays',
                    style: textTheme.titleLarge
                        ?.copyWith(color: AppColors.darkGreen),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddArticleSheet(context),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Add Article'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Merchandise',
                    style: textTheme.titleLarge
                        ?.copyWith(color: AppColors.darkGreen),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddMerchSheet(context),
                  icon: const Icon(Icons.shopping_bag_rounded),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Events Calendar',
                    style: textTheme.titleLarge
                        ?.copyWith(color: AppColors.darkGreen),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddEventSheet(context),
                  icon: const Icon(Icons.event_note_rounded),
                  label: const Text('Add Event'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'My Posts',
              style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 12),
            _UserPostsList(userId: user.uid),
          ],
        );
      },
    );
  }
}

class _PageLayout extends StatelessWidget {
  final String title;
  final String description;
  final List<String> highlights;

  const _PageLayout({
    required this.title,
    required this.description,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(color: AppColors.darkGreen),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.leatherDark),
        ),
        const SizedBox(height: 24),
        for (final highlight in highlights)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(highlight),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              iconColor: AppColors.leather,
              textColor: AppColors.darkGreen,
            ),
          ),
      ],
    );
  }
}
