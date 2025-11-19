import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

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
import 'services/membership_service.dart';
import 'services/user_library_service.dart';

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

class CountryOption {
  final String code;
  final String name;

  const CountryOption({required this.code, required this.name});
}

const List<CountryOption> countryOptions = [
  CountryOption(code: 'US', name: 'United States'),
  CountryOption(code: 'CA', name: 'Canada'),
  CountryOption(code: 'MX', name: 'Mexico'),
  CountryOption(code: 'GB', name: 'United Kingdom'),
  CountryOption(code: 'IE', name: 'Ireland'),
  CountryOption(code: 'FR', name: 'France'),
  CountryOption(code: 'DE', name: 'Germany'),
  CountryOption(code: 'ES', name: 'Spain'),
  CountryOption(code: 'IT', name: 'Italy'),
  CountryOption(code: 'PT', name: 'Portugal'),
  CountryOption(code: 'NL', name: 'Netherlands'),
  CountryOption(code: 'SE', name: 'Sweden'),
  CountryOption(code: 'NO', name: 'Norway'),
  CountryOption(code: 'FI', name: 'Finland'),
  CountryOption(code: 'DK', name: 'Denmark'),
  CountryOption(code: 'IS', name: 'Iceland'),
  CountryOption(code: 'AU', name: 'Australia'),
  CountryOption(code: 'NZ', name: 'New Zealand'),
  CountryOption(code: 'JP', name: 'Japan'),
  CountryOption(code: 'CN', name: 'China'),
  CountryOption(code: 'HK', name: 'Hong Kong'),
  CountryOption(code: 'SG', name: 'Singapore'),
  CountryOption(code: 'KR', name: 'South Korea'),
  CountryOption(code: 'IN', name: 'India'),
  CountryOption(code: 'BR', name: 'Brazil'),
  CountryOption(code: 'AR', name: 'Argentina'),
  CountryOption(code: 'CL', name: 'Chile'),
  CountryOption(code: 'ZA', name: 'South Africa'),
  CountryOption(code: 'AE', name: 'United Arab Emirates'),
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
  } else {
    await docRef.set(baseData, SetOptions(merge: true));
    final existingLevel = snapshot.data()?['membershipLevel'] as String?;
    if (existingLevel == null) {
      await docRef.set(
        {'membershipLevel': membershipLevels.first},
        SetOptions(merge: true),
      );
    }
  }

  final fallbackLevel =
      snapshot.data()?['membershipLevel'] as String? ?? membershipLevels.first;
  await MembershipService().ensureMembershipProfile(
    userId: user.uid,
    fallbackTier: fallbackLevel,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error');
      debugPrint('$stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Whiskey Manuscript',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.darkGreen,
          onPrimary: AppColors.onDark,
          secondary: AppColors.leather,
          onSecondary: AppColors.onDark,
          error: Color(0xFFB3261E),
          onError: AppColors.onDark,
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
    final stream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();

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
            bool alreadyFriend = false;
            VoidCallback? addFriendCallback;
            if (postOwnerId != null &&
                currentUserId != null &&
                postOwnerId != currentUserId) {
              alreadyFriend = _friendIds.contains(postOwnerId);
              if (!alreadyFriend) {
                addFriendCallback = () => _addFriend(postOwnerId);
              }
            }

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
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
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
  const _UserPostsList({required this.userId});

  final String userId;

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
              onDelete: () => _deletePost(context, doc.id),
              onTap: () => _openPostDetail(doc.id),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FollowerStat extends StatelessWidget {
  const _FollowerStat({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ProfileStatChip(
            label: 'Followers unavailable',
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        final label = count == 1 ? '1 follower' : '$count followers';
        return _ProfileStatChip(
          label: label,
          onTap: () => _showFollowersSheet(context, userId: userId),
        );
      },
    );
  }
}

class _FollowingStat extends StatelessWidget {
  const _FollowingStat({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ProfileStatChip(
            label: 'Following unavailable',
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        final label = count == 1 ? '1 following' : '$count following';
        return _ProfileStatChip(
          label: label,
          onTap: () => _showFollowingSheet(context, userId: userId),
        );
      },
    );
  }
}

class _PostCountSummary extends StatelessWidget {
  const _PostCountSummary({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ProfileStatChip(
            label: 'Posts unavailable',
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        final label = count == 1 ? '1 post' : '$count posts';
        return _ProfileStatChip(
          label: label,
        );
      },
    );
  }
}

Future<void> _showFollowersSheet(BuildContext context,
    {required String userId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _RelationshipList(
        userId: userId,
        collection: 'followers',
        emptyLabel: 'No followers yet.',
        title: 'Followers',
      ),
    ),
  );
}

Future<void> _showFollowingSheet(BuildContext context,
    {required String userId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _RelationshipList(
        userId: userId,
        collection: 'following',
        emptyLabel: 'Not following anyone yet.',
        title: 'Following',
      ),
    ),
  );
}

class _RelationshipList extends StatefulWidget {
  const _RelationshipList({required this.userId,
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
      final targetMembership = targetData['membershipLevel'] as String?;

      final currentDoc =
          await _firestore.collection('users').doc(current.uid).get();
      final currentData = currentDoc.data() ?? const <String, dynamic>{};
      final currentDisplayName =
          (currentData['displayName'] as String?)?.trim() ?? '';
      final currentEmail = (currentData['email'] as String?)?.trim();
      final currentMembership = currentData['membershipLevel'] as String?;

      final batch = _firestore.batch();
      batch.set(
        _firestore
            .collection('users')
            .doc(current.uid)
            .collection('following')
            .doc(targetId),
        {
          'userId': targetId,
          'displayName': targetDisplayName.isNotEmpty
              ? targetDisplayName
              : (targetEmail ?? 'Member'),
          'email': targetEmail,
          'membershipLevel': targetMembership,
          'addedAt': FieldValue.serverTimestamp(),
        },
      );
      batch.set(
        _firestore
            .collection('users')
            .doc(targetId)
            .collection('followers')
            .doc(current.uid),
        {
          'userId': current.uid,
          'displayName': currentDisplayName.isNotEmpty
              ? currentDisplayName
              : (currentEmail ?? 'Member'),
          'email': currentEmail,
          'membershipLevel': currentMembership,
          'addedAt': FieldValue.serverTimestamp(),
        },
      );
      await batch.commit();
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
      final batch = _firestore.batch();
      batch.delete(
        _firestore
            .collection('users')
            .doc(current.uid)
            .collection('following')
            .doc(targetId),
      );
      batch.delete(
        _firestore
            .collection('users')
            .doc(targetId)
            .collection('followers')
            .doc(current.uid),
      );
      await batch.commit();
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

class _ProfileStatChip extends StatelessWidget {
  const _ProfileStatChip({required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.darkGreen,
        ),
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: chip,
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label,
    this.value,
    this.allowCopy = false,
  });

  final String label;
  final String? value;
  final bool allowCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedValue =
        (value == null || value!.isEmpty) ? 'Not provided' : value!;
    final valueStyle =
        theme.textTheme.bodyMedium?.copyWith(color: AppColors.darkGreen);
    final valueWidget = allowCopy
        ? SelectableText(resolvedValue, style: valueStyle)
        : Text(resolvedValue, style: valueStyle);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.leatherDark),
          ),
          const SizedBox(height: 4),
          valueWidget,
        ],
      ),
    );
  }
}

class _ProfileEditableField extends StatelessWidget {
  const _ProfileEditableField({required this.label,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.words,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              theme.textTheme.bodySmall?.copyWith(color: AppColors.leatherDark),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          textCapitalization: textCapitalization,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}

class MembershipDetailsPage extends StatefulWidget {
  const MembershipDetailsPage({super.key, required this.userId,
    this.fallbackTier,
  });

  final String userId;
  final String? fallbackTier;

  @override
  State<MembershipDetailsPage> createState() => _MembershipDetailsPageState();
}

class _MembershipDetailsPageState extends State<MembershipDetailsPage> {
  final MembershipService _membershipService = MembershipService();
  late Future<Map<String, dynamic>> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _membershipService.ensureMembershipProfile(
      userId: widget.userId,
      fallbackTier: widget.fallbackTier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership & Billing'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'We could not load membership data. ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.leatherDark),
                ),
              ),
            );
          }

          final membership = snapshot.data ?? const <String, dynamic>{};
          return _MembershipDetailsView(membership: membership);
        },
      ),
    );
  }
}

class _MembershipDetailsView extends StatelessWidget {
  const _MembershipDetailsView({
    required this.membership,
  });

  final Map<String, dynamic> membership;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fields = <_MembershipFieldTileData>[
      _MembershipFieldTileData(
        label: 'membership.tier',
        value: _formatEnum(membership['tier'] as String?),
      ),
      _MembershipFieldTileData(
        label: 'membership.status',
        value: _formatEnum(membership['status'] as String?),
      ),
      _MembershipFieldTileData(
        label: 'membership.startedAt',
        value: _formatTimestamp(membership['startedAt']),
      ),
      _MembershipFieldTileData(
        label: 'membership.renewsAt',
        value: _formatTimestamp(membership['renewsAt']),
      ),
      _MembershipFieldTileData(
        label: 'membership.canceledAt',
        value: _formatTimestamp(membership['canceledAt']),
      ),
      _MembershipFieldTileData(
        label: 'membership.billingProvider',
        value: _formatEnum(membership['billingProvider'] as String?),
      ),
      _MembershipFieldTileData(
        label: 'membership.billingCustomerId',
        value: _formatString(membership['billingCustomerId'] as String?),
      ),
      _MembershipFieldTileData(
        label: 'membership.trialEndsAt',
        value: _formatTimestamp(membership['trialEndsAt']),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Membership Overview',
          style: textTheme.headlineSmall?.copyWith(color: AppColors.darkGreen),
        ),
        const SizedBox(height: 8),
        Text(
          'Tiering, lifecycle, and billing identifiers synced directly from the profile document.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.leatherDark),
        ),
        const SizedBox(height: 24),
        for (final field in fields)
          _MembershipFieldTile(
            label: field.label,
            value: field.value,
          ),
      ],
    );
  }

  static String _formatEnum(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not set';
    }
    final sanitized = value.trim();
    return '${sanitized[0].toUpperCase()}${sanitized.substring(1)}';
  }

  static String _formatString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not set';
    }
    return value.trim();
  }

  static String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return _formatDate(value.toDate());
    }
    if (value is DateTime) {
      return _formatDate(value);
    }
    return 'Not set';
  }

  static String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hourValue = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month/$day/$year $hourValue:$minute $period';
  }
}

class _MembershipFieldTileData {
  const _MembershipFieldTileData({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _MembershipFieldTile extends StatelessWidget {
  const _MembershipFieldTile({required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: AppColors.leatherDark),
        ),
        subtitle: Text(
          value,
          style:
              theme.textTheme.titleMedium?.copyWith(color: AppColors.darkGreen),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatefulWidget {
  const _ProfileInfoCard({required this.userId,
    required this.initials,
    required this.primaryName,
    required this.email,
    required this.emailVerified,
    required this.membership,
    required this.membershipDescription,
    required this.memberSince,
    required this.firstName,
    required this.lastName,
    required this.countryCode,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.allowLocationBasedFeatures,
    required this.birthYear,
    required this.onSave,
    required this.onMembershipChanged,
  });

  final String userId;
  final String initials;
  final String primaryName;
  final String email;
  final bool emailVerified;
  final String membership;
  final String membershipDescription;
  final DateTime? memberSince;
  final String? firstName;
  final String? lastName;
  final String countryCode;
  final String? city;
  final String? region;
  final String? postalCode;
  final bool allowLocationBasedFeatures;
  final int? birthYear;
  final Future<void> Function(Map<String, dynamic> data,
      {String? successMessage}) onSave;
  final Future<void> Function(String? level) onMembershipChanged;

  @override
  State<_ProfileInfoCard> createState() => _ProfileInfoCardState();
}

Future<bool> _confirmDeletion(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> _performDeletion(
  BuildContext context, {
  required Future<void> Function() action,
  required String successMessage,
}) async {
  try {
    await action();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(successMessage)));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not complete this action: $e')));
  }
}

class _ProfileInfoCardState extends State<_ProfileInfoCard> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _birthYearController;
  String _countryCode = 'US';
  String? _postalCode;
  String? _resolvedCity;
  String? _region;
  bool _allowLocationFeatures = false;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _suppressFieldListeners = false;
  Map<String, dynamic> _initialValues = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _cityController = TextEditingController();
    _birthYearController = TextEditingController();
    _firstNameController.addListener(_handleFieldChange);
    _lastNameController.addListener(_handleFieldChange);
    _cityController.addListener(_handleFieldChange);
    _birthYearController.addListener(_handleFieldChange);
    _hydrateFromWidget();
  }

  @override
  void didUpdateWidget(covariant _ProfileInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDirty && _hasWidgetDataChanged(oldWidget)) {
      _hydrateFromWidget();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  bool _hasWidgetDataChanged(_ProfileInfoCard oldWidget) {
    return oldWidget.firstName != widget.firstName ||
        oldWidget.lastName != widget.lastName ||
        oldWidget.countryCode != widget.countryCode ||
        oldWidget.city != widget.city ||
        oldWidget.region != widget.region ||
        oldWidget.postalCode != widget.postalCode ||
        oldWidget.allowLocationBasedFeatures !=
            widget.allowLocationBasedFeatures ||
        oldWidget.birthYear != widget.birthYear ||
        oldWidget.membership != widget.membership;
  }

  void _hydrateFromWidget() {
    _suppressFieldListeners = true;
    _firstNameController.text = widget.firstName ?? '';
    _lastNameController.text = widget.lastName ?? '';
    _cityController.text = widget.city ?? '';
    _birthYearController.text = widget.birthYear?.toString() ?? '';
    _suppressFieldListeners = false;
    _countryCode = widget.countryCode;
    _postalCode = widget.postalCode;
    _resolvedCity = widget.countryCode == 'US' ? widget.city : null;
    _region = widget.region;
    _allowLocationFeatures = widget.allowLocationBasedFeatures;
    _initialValues = _currentValueMap();
    _isDirty = false;
    setState(() {});
  }

  Map<String, dynamic> _currentValueMap({int? birthYearOverride}) {
    final isUs = _countryCode == 'US';
    return {
      'firstName': _normalizeText(_firstNameController.text),
      'lastName': _normalizeText(_lastNameController.text),
      'countryCode': _countryCode,
      'postalCode': isUs ? _normalizeText(_postalCode) : null,
      'city': isUs ? _resolvedCity : _normalizeText(_cityController.text),
      'region': isUs ? _region : null,
      'birthYear': birthYearOverride ?? _tryParseBirthYear(),
      'allowLocationBasedFeatures': _allowLocationFeatures,
      'membership': widget.membership,
    };
  }

  String? _normalizeText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  int? _tryParseBirthYear() {
    final trimmed = _birthYearController.text.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  void _handleFieldChange() {
    if (_suppressFieldListeners) {
      return;
    }
    final dirty = _computeIsDirty();
    if (dirty != _isDirty) {
      setState(() => _isDirty = dirty);
    }
  }

  bool _computeIsDirty() {
    final current = _currentValueMap();
    for (final entry in _initialValues.entries) {
      if (current[entry.key] != entry.value) {
        return true;
      }
    }
    return false;
  }

  void _handleCountryChanged(String? value) {
    if (value == null || value == _countryCode) {
      return;
    }
    setState(() {
      _countryCode = value;
      if (_countryCode != 'US') {
        _cityController.text = _resolvedCity ?? _cityController.text;
        _resolvedCity = null;
        _postalCode = null;
        _region = null;
      } else {
        _resolvedCity = _normalizeText(_cityController.text);
      }
    });
    _handleFieldChange();
  }

  void _handleZipInputChanged(String zip) {
    setState(() {
      _postalCode = zip.isEmpty ? null : zip;
      if (zip.isEmpty) {
        _resolvedCity = null;
        _region = null;
      }
    });
    _handleFieldChange();
  }

  Future<void> _handleZipResolved(
      String zip, String? city, String? state) async {
    setState(() {
      _postalCode = zip;
      _resolvedCity = city;
      _region = state;
    });
    _handleFieldChange();
  }

  void _handleLocationToggle(bool value) {
    setState(() => _allowLocationFeatures = value);
    _handleFieldChange();
  }

  Future<void> _save() async {
    final trimmed = _birthYearController.text.trim();
    int? parsedBirthYear;
    if (trimmed.isNotEmpty) {
      parsedBirthYear = int.tryParse(trimmed);
      if (parsedBirthYear == null) {
        _showSnack('Enter a valid birth year.');
        return;
      }
    }
    final changes = _diffWithInitial(birthYearOverride: parsedBirthYear);
    if (changes.isEmpty) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave(changes, successMessage: 'Profile updated');
      _initialValues = _currentValueMap(birthYearOverride: parsedBirthYear);
      setState(() {
        _isDirty = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Map<String, dynamic> _diffWithInitial({int? birthYearOverride}) {
    final current = _currentValueMap(birthYearOverride: birthYearOverride);
    final result = <String, dynamic>{};
    for (final entry in current.entries) {
      if (_initialValues[entry.key] != entry.value) {
        if (entry.key == 'membership') continue;
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  void _revertChanges() {
    _suppressFieldListeners = true;
    _firstNameController.text = (_initialValues['firstName'] as String?) ?? '';
    _lastNameController.text = (_initialValues['lastName'] as String?) ?? '';
    _cityController.text = (_initialValues['city'] as String?) ?? '';
    _birthYearController.text =
        (_initialValues['birthYear'] as int?)?.toString() ?? '';
    _suppressFieldListeners = false;
    setState(() {
      _countryCode = (_initialValues['countryCode'] as String?) ?? 'US';
      _postalCode = _initialValues['postalCode'] as String?;
      _resolvedCity = _initialValues['city'] as String?;
      _region = _initialValues['region'] as String?;
      _allowLocationFeatures =
          _initialValues['allowLocationBasedFeatures'] as bool? ?? false;
      _isDirty = false;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openMembershipDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MembershipDetailsPage(
          userId: widget.userId,
          fallbackTier: widget.membership,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final memberSince = widget.memberSince;
    final isUsSelected = _countryCode == 'US';

    final trimmedFirstName = widget.firstName?.trim();
    final trimmedLastName = widget.lastName?.trim();
    final nameParts = <String>[
      if (trimmedFirstName != null && trimmedFirstName.isNotEmpty)
        trimmedFirstName,
      if (trimmedLastName != null && trimmedLastName.isNotEmpty)
        trimmedLastName,
    ];
    final resolvedDisplayName =
        nameParts.isEmpty ? 'Whiskey Person' : nameParts.join(' ');

    return Card(
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
                  radius: 48,
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: AppColors.onDark,
                  child: Text(
                    widget.initials,
                    style: const TextStyle(
                      fontSize: 42,
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
                        resolvedDisplayName,
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.leatherDark),
                      ),
                      if (memberSince != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Member since ${memberSince.month}/${memberSince.day}/${memberSince.year}',
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.leatherDark),
                        ),
                      ],
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _openMembershipDetails,
                        child: Text(
                          'Membership Level: ${widget.membership}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.leather,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FollowerStat(userId: widget.userId),
                _FollowingStat(userId: widget.userId),
                _PostCountSummary(userId: widget.userId),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _ProfileInfoRow(
                    label: 'Email',
                    value: widget.email,
                    allowCopy: true,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.verified,
                  color: widget.emailVerified
                      ? Colors.green
                      : AppColors.leatherDark.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ProfileEditableField(
                    label: 'First Name',
                    controller: _firstNameController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileEditableField(
                    label: 'Last Name',
                    controller: _lastNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _countryCode,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                for (final option in countryOptions)
                  DropdownMenuItem(
                    value: option.code,
                    child: Text(option.name),
                  ),
              ],
              onChanged: _handleCountryChanged,
            ),
            const SizedBox(height: 12),
            if (isUsSelected)
              _ZipCodeField(
                postalCode: _postalCode,
                city: _resolvedCity,
                state: _region,
                onZipResolved: _handleZipResolved,
                onZipChanged: _handleZipInputChanged,
              )
            else
              _ProfileEditableField(
                label: 'City',
                controller: _cityController,
              ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow location-based features'),
              subtitle: const Text(
                'Enables experiences tailored to your location.',
              ),
              dense: true,
              value: _allowLocationFeatures,
              onChanged: _handleLocationToggle,
            ),
            const SizedBox(height: 12),
            _ProfileEditableField(
              label: 'Birth Year',
              controller: _birthYearController,
              keyboardType: TextInputType.number,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isDirty)
                  TextButton(
                    onPressed: _isSaving ? null : _revertChanges,
                    child: const Text('Revert changes'),
                  ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isDirty && !_isSaving ? _save : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZipCodeField extends StatefulWidget {
  const _ZipCodeField({
    required this.postalCode,
    required this.city,
    required this.state,
    required this.onZipResolved,
    required this.onZipChanged,
  });

  final String? postalCode;
  final String? city;
  final String? state;
  final Future<void> Function(String zip, String? city, String? state)
      onZipResolved;
  final ValueChanged<String> onZipChanged;

  @override
  State<_ZipCodeField> createState() => _ZipCodeFieldState();
}

class _ZipCodeFieldState extends State<_ZipCodeField> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  String? _city;
  String? _state;
  String? _error;
  bool _suppressChange = false;
  String _lastLookupCandidate = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.postalCode ?? '');
    _city = widget.city;
    _state = widget.state;
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant _ZipCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postalCode != oldWidget.postalCode &&
        widget.postalCode != _controller.text) {
      _suppressChange = true;
      _controller.text = widget.postalCode ?? '';
      _suppressChange = false;
    }
    if (widget.city != oldWidget.city || widget.state != oldWidget.state) {
      setState(() {
        _city = widget.city;
        _state = widget.state;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    if (_suppressChange) {
      return;
    }
    final value = _controller.text;
    widget.onZipChanged(value);
    if (value.length == 5 && value != _lastLookupCandidate) {
      _lastLookupCandidate = value;
      _resolveZip(value);
    } else if (value.length != 5) {
      _lastLookupCandidate = '';
    }
  }

  Future<void> _resolveZip([String? value]) async {
    final zip = (value ?? _controller.text).trim();
    if (zip.isEmpty) {
      setState(() {
        _error = null;
        _city = null;
        _state = null;
      });
      await widget.onZipResolved('', null, null);
      return;
    }
    if (!RegExp(r'^\d{5}$').hasMatch(zip)) {
      setState(() => _error = 'Enter a valid 5-digit ZIP code.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await ZipLookupService.lookup(zip);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _isLoading = false;
        _error = 'We could not find that ZIP code.';
      });
      return;
    }
    await widget.onZipResolved(zip, result.city, result.stateAbbreviation);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _city = result.city;
      _state = result.stateAbbreviation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final helperColor = _error != null ? Colors.red : AppColors.leatherDark;
    final helperText = _error ??
        ((_city != null && _state != null)
            ? '$_city, $_state'
            : 'ZIP will auto-fill city and state');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'ZIP code',
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Lookup ZIP',
                    onPressed: () => _resolveZip(),
                    icon: const Icon(Icons.search_rounded),
                  ),
          ),
          onFieldSubmitted: _resolveZip,
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: theme.textTheme.bodySmall?.copyWith(color: helperColor),
        ),
      ],
    );
  }
}

class ZipLookupResult {
  const ZipLookupResult({
    required this.zip,
    required this.city,
    required this.state,
    required this.stateAbbreviation,
  });

  final String zip;
  final String city;
  final String state;
  final String stateAbbreviation;
}

class ZipLookupService {
  ZipLookupService._();

  static final Map<String, ZipLookupResult> _cache = {};

  static Future<ZipLookupResult?> lookup(String zip) async {
    if (_cache.containsKey(zip)) {
      return _cache[zip];
    }
    final uri = Uri.parse('https://api.zippopotam.us/us/$zip');
    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List<dynamic>?;
      if (places == null || places.isEmpty) {
        return null;
      }
      final place = places.first as Map<String, dynamic>;
      final city = (place['place name'] as String? ?? '').trim();
      final state = (place['state'] as String? ?? '').trim();
      final abbr = (place['state abbreviation'] as String? ?? '').trim();
      if (city.isEmpty || abbr.isEmpty) {
        return null;
      }
      final result = ZipLookupResult(
        zip: zip,
        city: city,
        state: state,
        stateAbbreviation: abbr,
      );
      _cache[zip] = result;
      return result;
    } catch (_) {
      return null;
    }
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
    this.onDelete,
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
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              authorLabel,
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
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.leatherDark,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
    final resolvedPadding =
        (widget.padding ?? basePadding).add(EdgeInsets.only(bottom: viewInsets));

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
              _WhiskeyCard(
                whiskeyName: doc.data()['name'] as String? ?? 'Untitled Bottle',
                style: doc.data()['style'] as String? ?? 'Special Release',
                region: doc.data()['region'] as String? ?? 'Unknown region',
                notes: doc.data()['notes'] as String? ?? '',
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

class _UserSavedWhiskeyList extends StatelessWidget {
  const _UserSavedWhiskeyList({required this.userId,
    required this.collectionName,
    required this.emptyMessage,
  });

  final String userId;
  final String collectionName;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .orderBy('addedAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your saved bottles.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _FeedMessage(message: emptyMessage);
        }

        return Column(
          children: [
            for (final doc in docs)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    doc.data()['name'] as String? ?? 'Whiskey',
                    style: const TextStyle(color: AppColors.darkGreen),
                  ),
                  subtitle: Text(
                    _buildSavedWhiskeySubtitle(doc.data()),
                    style: const TextStyle(color: AppColors.leatherDark),
                  ),
                  trailing: Text(
                    _formatEventDate(_coerceTimestamp(doc.data()['addedAt'])),
                    style: const TextStyle(color: AppColors.leatherDark),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _buildSavedWhiskeySubtitle(Map<String, dynamic> data) {
    final style = (data['style'] as String? ?? '').trim();
    final region = (data['region'] as String? ?? '').trim();
    final parts = [style, region].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Details coming soon';
    }
    return parts.join(' - ');
  }
}

class _UserFavoriteDistilleriesList extends StatelessWidget {
  const _UserFavoriteDistilleriesList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoriteDistilleries')
        .orderBy('addedAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load favorite distilleries.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message:
                'Your Distillery list is blank.\nVisit the Content tab and mark your first favorite.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    doc.data()['name'] as String? ?? 'Distillery',
                    style: const TextStyle(color: AppColors.darkGreen),
                  ),
                  subtitle: Text(
                    _buildFavoriteDistillerySubtitle(doc.data()),
                    style: const TextStyle(color: AppColors.leatherDark),
                  ),
                  trailing: Text(
                    _formatEventDate(_coerceTimestamp(doc.data()['addedAt'])),
                    style: const TextStyle(color: AppColors.leatherDark),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _buildFavoriteDistillerySubtitle(Map<String, dynamic> data) {
    final location = (data['location'] as String? ?? '').trim();
    final pour = (data['signaturePour'] as String? ?? '').trim();
    final parts = [location, pour].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Details coming soon';
    }
    return parts.join(' - ');
  }
}

class _UserFavoriteArticlesList extends StatelessWidget {
  const _UserFavoriteArticlesList({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoriteArticles')
        .orderBy('addedAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load favorite articles.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message:
                'Your Article Library is empty.\nFind something in Content and add it here.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    doc.data()['title'] as String? ?? 'Article',
                    style: const TextStyle(color: AppColors.darkGreen),
                  ),
                  subtitle: Text(
                    _buildFavoriteArticleSubtitle(doc.data()),
                    style: const TextStyle(color: AppColors.leatherDark),
                  ),
                  trailing: Text(
                    _formatEventDate(_coerceTimestamp(doc.data()['addedAt'])),
                    style: const TextStyle(color: AppColors.leatherDark),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _buildFavoriteArticleSubtitle(Map<String, dynamic> data) {
    final category = (data['category'] as String? ?? '').trim();
    final author = (data['author'] as String? ?? '').trim();
    final parts = [category, author].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Details coming soon';
    }
    return parts.join(' - ');
  }
}

class _UserLookupSection extends StatefulWidget {
  const _UserLookupSection();
  @override
  State<_UserLookupSection> createState() => _UserLookupSectionState();
}

class _UserLookupSectionState extends State<_UserLookupSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<_LookupUser> _results = [];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final rawQuery = _controller.text.trim();
    final keyword = rawQuery.toLowerCase();
    if (keyword.isEmpty) {
      setState(() {
        _error = 'Enter a name or email to search.';
        _results = [];
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _results = [];
    });
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').limit(150).get();
      final matches = <_LookupUser>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final matchesQuery = _matchesTerm(data['displayName'], keyword) ||
            _matchesTerm(data['firstName'], keyword) ||
            _matchesTerm(data['lastName'], keyword) ||
            _matchesTerm(data['email'], keyword) ||
            _matchesTerm(data['postalCode'], keyword) ||
            _matchesTerm(data['zipCode'], keyword);
        if (matchesQuery) {
          matches.add(_LookupUser(id: doc.id, data: data));
        }
      }
      if (!mounted) return;
      setState(() {
        _results = matches;
        if (matches.isEmpty) {
          _error = "No users matched '$rawQuery'.";
        }
      });
      if (matches.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showResultsSheet();
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'We could not search users right now.';
        _results = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultsSheet() {
    if (_results.isEmpty || !mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final titleStyle = Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: AppColors.darkGreen, fontWeight: FontWeight.bold);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search Results', style: titleStyle),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      final data = user.data;
                      final name = _resolveName(data, user.id);
                      final email = (data['email'] as String? ?? '').trim();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          title: Text(name),
                          subtitle: Text(
                            email.isEmpty ? 'Email not provided' : email,
                            style:
                                const TextStyle(color: AppColors.leatherDark),
                          ),
                          onTap: () {
                            Navigator.of(context).maybePop();
                            _showUserDetails(user);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search members by name or email',
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _search,
            icon: const Icon(Icons.person_search_rounded),
            label: const Text('Find User'),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.leatherDark),
            ),
          )
        else if (!_isLoading && _results.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _showResultsSheet,
              icon: const Icon(Icons.expand_circle_down_rounded),
              label: const Text('View Results'),
            ),
          ),
      ],
    );
  }

  bool _matchesTerm(Object? source, String term) {
    if (source == null) return false;
    final value = source.toString().toLowerCase();
    return value.contains(term);
  }

  String _resolveName(Map<String, dynamic> data, String fallback) {
    final displayName = (data['displayName'] as String? ?? '').trim();
    if (displayName.isNotEmpty) return displayName;
    final parts = [
      (data['firstName'] as String? ?? '').trim(),
      (data['lastName'] as String? ?? '').trim(),
    ]..removeWhere((part) => part.isEmpty);
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    if (fallback.isNotEmpty) {
      final max = fallback.length < 6 ? fallback.length : 6;
      return 'Member ${fallback.substring(0, max)}';
    }
    return 'Member';
  }

// ignore: unused_element
String _roleLabel(Map<String, dynamic> data) {
    return _roleValue(data) == 'admin' ? 'Admin' : 'User';
  }

  String _roleValue(Map<String, dynamic> data) {
    final raw = (data['role'] as String? ?? 'user').toLowerCase();
    return raw == 'admin' ? 'admin' : 'user';
  }

  String _formatLocation(Map<String, dynamic> data) {
    final parts = [
      (data['city'] as String? ?? '').trim(),
      (data['region'] as String? ?? '').trim(),
      (data['countryCode'] as String? ?? '').trim(),
    ]..removeWhere((part) => part.isEmpty);
    return parts.join(', ');
  }

  void _showUserDetails(_LookupUser user) {
    final data = user.data;
    final name = _resolveName(data, user.id);
    final email = (data['email'] as String? ?? '').trim();
    final membership = (data['membershipLevel'] as String? ?? '').trim();
    final location = _formatLocation(data);
    var roleValue = _roleValue(data);
    var isUpdatingRole = false;
    String? roleError;
    final joined = data['createdAt'] != null
        ? _formatEventDate(_coerceTimestamp(data['createdAt']).toLocal())
        : 'Not available';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final titleStyle = Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: AppColors.darkGreen, fontWeight: FontWeight.bold);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> handleRoleChange(String? value) async {
              if (value == null || value == roleValue) return;
              setSheetState(() {
                isUpdatingRole = true;
                roleError = null;
              });
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.id)
                    .set({'role': value}, SetOptions(merge: true));
                if (!mounted) return;
                setState(() {
                  user.data['role'] = value;
                });
                setSheetState(() {
                  roleValue = value;
                });
              } catch (_) {
                setSheetState(() {
                  roleError = 'We could not update the role. Try again soon.';
                });
              } finally {
                setSheetState(() {
                  isUpdatingRole = false;
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: titleStyle),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(color: AppColors.leatherDark),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Role',
                      style: TextStyle(
                        color: AppColors.leatherDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: roleValue,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: AppColors.lightNeutral,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: isUpdatingRole ? null : handleRoleChange,
                    ),
                    if (roleError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        roleError!,
                        style: const TextStyle(color: AppColors.leatherDark),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _UserDetailRow(
                      label: 'Membership',
                      value: membership.isEmpty ? 'Not set' : membership,
                    ),
                    _UserDetailRow(
                      label: 'Location',
                      value: location.isEmpty ? 'Not shared' : location,
                    ),
                    _UserDetailRow(label: 'Joined', value: joined),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LookupUser {
  _LookupUser({required this.id, required Map<String, dynamic> data})
      : data = Map<String, dynamic>.from(data);
  final String id;
  final Map<String, dynamic> data;
}

class _UserDetailRow extends StatelessWidget {
  const _UserDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.leatherDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.darkGreen),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _UserFriendsList extends StatelessWidget {
  const _UserFriendsList({required this.userId});

  final String userId;
  static final FriendService _friendService = FriendService();

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
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your friends.',
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'No friends yet. Tap profiles to add someone.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.neutralLight,
                    foregroundColor: AppColors.darkGreen,
                    child: Text(
                      _initialsFor(
                        (doc.data()['displayName'] as String? ?? 'F').trim(),
                      ),
                    ),
                  ),
                  title: Text(
                    (doc.data()['displayName'] as String? ?? 'Member').trim(),
                    style: const TextStyle(color: AppColors.darkGreen),
                  ),
                  subtitle: Text(
                    (doc.data()['email'] as String? ?? 'No email').trim(),
                    style: const TextStyle(color: AppColors.leatherDark),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove friend',
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.leatherDark),
                    onPressed: () => _removeFriend(
                      context,
                      doc.id,
                      doc.data()['displayName'] as String?,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _removeFriend(
    BuildContext context,
    String friendId,
    String? label,
  ) async {
    final displayName =
        (label == null || label.trim().isEmpty) ? 'this friend' : label.trim();
    final confirmed = await _confirmDeletion(
      context,
      title: 'Remove friend',
      message: 'Remove $displayName from your list?',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => _friendService.removeFriend(friendId),
      successMessage: 'Friend removed.',
    );
  }
}

// ignore: unused_element
class _UserSentMessagesList extends StatelessWidget {
  const _UserSentMessagesList({required this.userId});

  final String userId;
  static final MessageService _messageService = MessageService();

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('messages')
        .where('fromUserId', isEqualTo: userId)
        .orderBy('sentAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your messages.',
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'You have not sent any messages yet.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    "To ${doc.data()['toDisplayName'] as String? ?? 'Member'}",
                    style: const TextStyle(color: AppColors.darkGreen),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatMessageTimestamp(
                            _coerceTimestamp(doc.data()['sentAt'])),
                        style: const TextStyle(color: AppColors.leatherDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (doc.data()['message'] as String? ?? '').trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.darkGreen),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete message',
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.leatherDark),
                    onPressed: () => _deleteMessage(context, doc.id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMessage(BuildContext context, String messageId) async {
    final confirmed = await _confirmDeletion(
      context,
      title: 'Delete message',
      message: 'This removes the sent message for you. Continue?',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => _messageService.deleteMessage(messageId),
      successMessage: 'Message deleted.',
    );
  }
}

// ignore: unused_element
class _UserEventList extends StatelessWidget {
  const _UserEventList({required this.userId});

  final String userId;
  static final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('events')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load your events.',
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'No hosted events yet. Create one to get started.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              _EventCard(
                title: doc.data()['title'] as String? ?? 'Private Event',
                location: doc.data()['location'] as String? ?? 'TBD',
                details: (doc.data()['details'] as String? ?? '').trim(),
                date: _coerceTimestamp(doc.data()['date']),
                onDelete: () => _deleteEvent(
                  context,
                  doc.id,
                  doc.data()['title'] as String?,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteEvent(
    BuildContext context,
    String eventId,
    String? label,
  ) async {
    final displayName =
        (label == null || label.trim().isEmpty) ? 'this event' : label.trim();
    final confirmed = await _confirmDeletion(
      context,
      title: 'Delete event',
      message: 'Cancel $displayName?',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => _eventService.deleteEvent(eventId),
      successMessage: 'Event removed.',
    );
  }
}

class _WhiskeyCard extends StatelessWidget {
  const _WhiskeyCard({required this.whiskeyName,
    required this.style,
    required this.region,
    required this.notes,
    required this.authorLabel,
    required this.timestamp,
    this.membership,
    this.showAuthor = true,
    this.onDelete,
  });

  final String whiskeyName;
  final String style;
  final String region;
  final String notes;
  final String authorLabel;
  final DateTime timestamp;
  final String? membership;
  final bool showAuthor;
  final VoidCallback? onDelete;

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
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.leatherDark,
                    ),
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

class _AddWhiskeySheet extends StatefulWidget {
  const _AddWhiskeySheet();

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add whiskey: $e')));
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
              initialValue: _style,
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

// ignore: unused_element
class _UserDistilleryList extends StatelessWidget {
  const _UserDistilleryList({required this.userId});

  final String userId;
  static final DistilleryService _distilleryService = DistilleryService();

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
                onDelete: () => _deleteDistillery(
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

  Future<void> _deleteDistillery(
    BuildContext context,
    String distilleryId,
    String? label,
  ) async {
    final displayName = (label == null || label.trim().isEmpty)
        ? 'this distillery'
        : label.trim();
    final confirmed = await _confirmDeletion(
      context,
      title: 'Remove distillery',
      message: 'Delete $displayName from your spotlights?',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => _distilleryService.deleteDistillery(distilleryId),
      successMessage: 'Distillery removed.',
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
    this.onDelete,
  });

  final String name;
  final String location;
  final String story;
  final String signaturePour;
  final String authorLabel;
  final DateTime timestamp;
  final String? membership;
  final bool showAuthor;
  final VoidCallback? onDelete;

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
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.leatherDark,
                    ),
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

class _AddDistillerySheet extends StatefulWidget {
  const _AddDistillerySheet();

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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add distillery: $e')));
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

// ignore: unused_element
class _UserArticleList extends StatelessWidget {
  const _UserArticleList({required this.userId});

  final String userId;
  static final ArticleService _articleService = ArticleService();

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
                onDelete: () => _deleteArticle(
                  context,
                  doc.id,
                  doc.data()['title'] as String?,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteArticle(
    BuildContext context,
    String articleId,
    String? label,
  ) async {
    final displayName =
        (label == null || label.trim().isEmpty) ? 'this article' : label.trim();
    final confirmed = await _confirmDeletion(
      context,
      title: 'Remove article',
      message: 'Delete $displayName from your archive?',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => _articleService.deleteArticle(articleId),
      successMessage: 'Article removed.',
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
    this.onDelete,
  });

  final String title;
  final String summary;
  final String link;
  final String category;
  final String authorLabel;
  final DateTime timestamp;
  final String? membership;
  final bool showAuthor;
  final VoidCallback? onDelete;

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
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.leatherDark,
                    ),
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
  const _AddArticleSheet();

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
              initialValue: _category,
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

// ignore: unused_element
class _UserMerchList extends StatelessWidget {
  const _UserMerchList({required this.userId});

  final String userId;
  static final MerchandiseService _merchService = MerchandiseService();

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
                onDelete: () => _deleteMerch(
                  context,
                  doc.id,
                  doc.data()['title'] as String?,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMerch(
    BuildContext context,
    String itemId,
    String? label,
  ) async {
    final displayName =
        (label == null || label.trim().isEmpty) ? 'this item' : label.trim();
    final confirmed = await _confirmDeletion(
      context,
      title: 'Remove item',
      message: 'Delete $displayName from your merchandise?',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => _merchService.deleteItem(itemId),
      successMessage: 'Item removed.',
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
    this.onDelete,
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
  final VoidCallback? onDelete;

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
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.leatherDark,
                    ),
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
  const _AddMerchSheet();

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
            .showSnackBar(SnackBar(content: Text('Could not add item: $e')));
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
              initialValue: _category,
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
  const _AddEventSheet();

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
              label: Text('Date: $dateLabel'),
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
  const _CaptionDialog();

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
          'Favorite Distilleries',
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
  final List<_ShowcaseAction> actions;

  const _ShowcaseData({
    required this.title,
    required this.subtitle,
    required this.footer,
    this.badge,
    this.actions = const [],
  });
}

class _ShowcaseAction {
  const _ShowcaseAction({
    required this.label,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Future<void> Function(BuildContext context) onSelected;
}

String _resolveActionErrorMessage(Object error) {
  final raw = error.toString();
  if (raw.startsWith('Exception: ')) {
    return raw.substring(11);
  }
  if (raw.startsWith('Bad state: ')) {
    return raw.substring(11);
  }
  return raw;
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Chip(
                    label: Text(data.badge!),
                    backgroundColor: AppColors.neutralLight,
                  ),
                ),
              if (data.actions.isNotEmpty)
                PopupMenuButton<_ShowcaseAction>(
                  tooltip: 'Save',
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.leatherDark,
                  ),
                  onSelected: (action) {
                    action.onSelected(context);
                  },
                  itemBuilder: (context) => [
                    for (final action in data.actions)
                      PopupMenuItem<_ShowcaseAction>(
                        value: action,
                        child: Row(
                          children: [
                            if (action.icon != null) ...[
                              Icon(
                                action.icon,
                                size: 18,
                                color: AppColors.leatherDark,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(action.label),
                          ],
                        ),
                      ),
                  ],
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
  const _LibraryDatabaseSheet();

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

class WhiskeyDatabasePage extends StatefulWidget {
  const WhiskeyDatabasePage({super.key, required this.onAddWhiskey});

  final Future<void> Function(BuildContext) onAddWhiskey;

  @override
  State<WhiskeyDatabasePage> createState() => _WhiskeyDatabasePageState();
}

class _WhiskeyDatabasePageState extends State<WhiskeyDatabasePage> {
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

  Future<void> _handleAddWhiskey() async {
    await widget.onAddWhiskey(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TWM Whiskey Database'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddWhiskey,
        icon: const Icon(Icons.local_bar_rounded),
        label: const Text('Add Whiskey'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search whiskeys by name, style, or region...',
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
            const SizedBox(height: 12),
            Expanded(
              child: _DatabaseWhiskeyList(
                query: _query,
                membership: _membershipFilter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DistilleryDatabasePage extends StatefulWidget {
  const DistilleryDatabasePage({super.key, required this.onAddDistillery});

  final Future<void> Function(BuildContext) onAddDistillery;

  @override
  State<DistilleryDatabasePage> createState() => _DistilleryDatabasePageState();
}

class _DistilleryDatabasePageState extends State<DistilleryDatabasePage> {
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

  Future<void> _handleAddDistillery() async {
    await widget.onAddDistillery(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TWM Distillery Database'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddDistillery,
        icon: const Icon(Icons.factory_rounded),
        label: const Text('Add Distillery'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search distilleries by name or location...',
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
            const SizedBox(height: 12),
            Expanded(
              child: _DatabaseDistilleryList(
                query: _query,
                membership: _membershipFilter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatabaseLinkButton extends StatelessWidget {
  const _DatabaseLinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.darkGreen,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.darkGreen,
        );
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.centerLeft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '•',
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: linkStyle),
          ],
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

class ArticleDatabasePage extends StatefulWidget {
  const ArticleDatabasePage({super.key, required this.onAddArticle});

  final Future<void> Function(BuildContext) onAddArticle;

  @override
  State<ArticleDatabasePage> createState() => _ArticleDatabasePageState();
}

class _ArticleDatabasePageState extends State<ArticleDatabasePage> {
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

  Future<void> _handleAddArticle() async {
    await widget.onAddArticle(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TWM Articles Database'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddArticle,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('Add Article'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search articles by title or category...',
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
            const SizedBox(height: 12),
            Expanded(
              child: _DatabaseArticleList(
                query: _query,
                membership: _membershipFilter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchDatabasePage extends StatefulWidget {
  const MerchDatabasePage({super.key, required this.onAddMerch});

  final Future<void> Function(BuildContext) onAddMerch;

  @override
  State<MerchDatabasePage> createState() => _MerchDatabasePageState();
}

class EventsDatabasePage extends StatelessWidget {
  const EventsDatabasePage({super.key, required this.onAddEvent});

  final Future<void> Function(BuildContext) onAddEvent;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('events')
        .orderBy('date')
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TWM Events Database'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => onAddEvent(context),
        icon: const Icon(Icons.event_note_rounded),
        label: const Text('Add Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
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
            if (docs.isEmpty) {
              return const _FeedMessage(
                message: 'No events planned yet. Add one from your profile.',
              );
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final title =
                    (data['title'] as String? ?? 'Private Event').trim();
                final location = (data['location'] as String? ?? 'TBD').trim();
                final details = (data['details'] as String? ?? '').trim();
                final date = _coerceTimestamp(data['date']);
                return _EventCard(
                  title: title,
                  location: location,
                  details: details,
                  date: date,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MerchDatabasePageState extends State<MerchDatabasePage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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

  Future<void> _handleAdd() async {
    await widget.onAddMerch(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TWM Merchandise Database'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAdd,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search merchandise by title or category...',
              ),
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: _MerchandiseFeed(),
            ),
          ],
        ),
      ),
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

  Future<void> _handleWhiskeySave(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool wishlist,
  }) async {
    final data = doc.data();
    final service = UserLibraryService();
    final rawName = (data['name'] as String? ?? 'Whiskey').trim();
    final resolvedName = rawName.isEmpty ? 'This whiskey' : rawName;
    try {
      if (wishlist) {
        await service.addWhiskeyToWishlist(
          whiskeyId: doc.id,
          name: resolvedName,
          style: data['style'] as String? ?? 'Special Release',
          region: data['region'] as String? ?? 'Unknown region',
          membership: data['membershipLevel'] as String?,
        );
      } else {
        await service.addWhiskeyToCollection(
          whiskeyId: doc.id,
          name: resolvedName,
          style: data['style'] as String? ?? 'Special Release',
          region: data['region'] as String? ?? 'Unknown region',
          membership: data['membershipLevel'] as String?,
        );
      }
      if (!context.mounted) return;
      final target = wishlist ? 'wishlist' : 'collection';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$resolvedName added to your $target.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not save: ${_resolveActionErrorMessage(e)}')),
      );
    }
  }

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
              actions: [
                _ShowcaseAction(
                  label: 'Add to collection',
                  icon: Icons.inventory_2_rounded,
                  onSelected: (ctx) =>
                      _handleWhiskeySave(ctx, doc, wishlist: false),
                ),
                _ShowcaseAction(
                  label: 'Add to wishlist',
                  icon: Icons.favorite_border_rounded,
                  onSelected: (ctx) =>
                      _handleWhiskeySave(ctx, doc, wishlist: true),
                ),
              ],
            ),
        ];

        return _HorizontalShowcase(items: items);
      },
    );
  }
}

class _GlobalArticleFeed extends StatelessWidget {
  const _GlobalArticleFeed();

  Future<void> _favoriteArticle(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final service = UserLibraryService();
    final rawTitle = (data['title'] as String? ?? 'Article').trim();
    final resolvedTitle = rawTitle.isEmpty ? 'This article' : rawTitle;
    try {
      await service.addFavoriteArticle(
        articleId: doc.id,
        title: resolvedTitle,
        category: data['category'] as String? ?? 'Story',
        author: data['userName'] as String? ?? 'Contributor',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$resolvedTitle added to favorites.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not save: ${_resolveActionErrorMessage(e)}')),
      );
    }
  }

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
              actions: [
                _ShowcaseAction(
                  label: 'Favorite article',
                  icon: Icons.bookmark_add_outlined,
                  onSelected: (ctx) => _favoriteArticle(ctx, doc),
                ),
              ],
            ),
        ];
        return _HorizontalShowcase(items: items);
      },
    );
  }
}

class _GlobalDistilleryFeed extends StatelessWidget {
  const _GlobalDistilleryFeed();

  Future<void> _favoriteDistillery(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final service = UserLibraryService();
    final rawName = (data['name'] as String? ?? 'Distillery').trim();
    final resolvedName = rawName.isEmpty ? 'This distillery' : rawName;
    try {
      await service.addFavoriteDistillery(
        distilleryId: doc.id,
        name: resolvedName,
        location: data['location'] as String? ?? 'Unknown location',
        signaturePour: data['signaturePour'] as String? ?? 'Signature pour',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$resolvedName added to favorites.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not save: ${_resolveActionErrorMessage(e)}')),
      );
    }
  }

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
              actions: [
                _ShowcaseAction(
                  label: 'Favorite distillery',
                  icon: Icons.star_border_rounded,
                  onSelected: (ctx) => _favoriteDistillery(ctx, doc),
                ),
              ],
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

  void _openWhiskeyDatabasePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhiskeyDatabasePage(
          onAddWhiskey: _openAddWhiskeySheet,
        ),
      ),
    );
  }

  void _openDistilleryDatabasePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DistilleryDatabasePage(
          onAddDistillery: _openAddDistillerySheet,
        ),
      ),
    );
  }

  void _openArticlesDatabasePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDatabasePage(
          onAddArticle: _openAddArticleSheet,
        ),
      ),
    );
  }

  void _openMerchDatabasePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MerchDatabasePage(
          onAddMerch: _openAddMerchSheet,
        ),
      ),
    );
  }

  void _openEventsDatabasePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventsDatabasePage(
          onAddEvent: _openAddEventSheet,
        ),
      ),
    );
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
        final membershipDescription =
            membershipDescriptions[membership] ?? 'Exclusive experiences.';
        final roleValue = (userData['role'] as String? ?? 'user').toLowerCase();
        final isAdmin = roleValue == 'admin';
        final metadata = user.metadata.creationTime;
        final email = user.email ?? 'No email available';
        final displayName = (user.displayName ?? email).trim();
        final initials = _initialsFor(displayName);
        final firstName = (userData['firstName'] as String?)?.trim();
        final lastName = (userData['lastName'] as String?)?.trim();
        final hasFullName = (firstName != null && firstName.isNotEmpty) &&
            (lastName != null && lastName.isNotEmpty);
        final primaryName = hasFullName ? '$firstName $lastName' : displayName;
        final countryCode =
            (userData['countryCode'] as String? ?? 'US').toUpperCase();
        final city = (userData['city'] as String?)?.trim();
        final region = (userData['region'] as String?)?.trim();
        final postalCode = (userData['postalCode'] as String?)?.trim();
        final allowLocationBasedFeatures =
            userData['allowLocationBasedFeatures'] as bool? ?? false;
        final birthYear = userData['birthYear'] as int?;
        final emailVerified =
            userData['emailVerified'] as bool? ?? user.emailVerified;

        Future<void> saveProfileData(Map<String, dynamic> data,
            {String? successMessage}) async {
          try {
            await docRef.set(data, SetOptions(merge: true));
            if (successMessage != null && context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(successMessage)));
            }
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not update profile: $e')),
            );
          }
        }

        Future<void> updateMembership(String? level) async {
          if (level == null || level == membership) return;
          try {
            final normalizedTier = level.toLowerCase();
            await docRef.set(
              {
                'membershipLevel': level,
                'membership': {'tier': normalizedTier},
              },
              SetOptions(merge: true),
            );
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
            _ProfileInfoCard(
              userId: user.uid,
              initials: initials,
              primaryName: primaryName,
              email: email,
              emailVerified: emailVerified,
              membership: membership,
              membershipDescription: membershipDescription,
              memberSince: metadata,
              firstName: firstName,
              lastName: lastName,
              countryCode: countryCode,
              city: city,
              region: region,
              postalCode: postalCode,
              allowLocationBasedFeatures: allowLocationBasedFeatures,
              birthYear: birthYear,
              onSave: saveProfileData,
              onMembershipChanged: updateMembership,
            ),
            const SizedBox(height: 32),
            Text(
              'Whiskey Collection',
              style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 12),
            _UserSavedWhiskeyList(
              userId: user.uid,
              collectionName: 'whiskeyCollection',
              emptyMessage:
                  'Your Library is blank.\nBrowse the Content tab and add your first entry.',
            ),
            const SizedBox(height: 32),
            Text(
              'Whiskey Wishlist',
              style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 12),
            _UserSavedWhiskeyList(
              userId: user.uid,
              collectionName: 'whiskeyWishlist',
              emptyMessage:
                  'Your Wishlist is empty.\nExplore the Content tab to plan your next pour.',
            ),
            const SizedBox(height: 32),
            Text(
              'Favorite Distilleries',
              style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 12),
            _UserFavoriteDistilleriesList(userId: user.uid),
            const SizedBox(height: 32),
            Text(
              'Favorite Articles',
              style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 12),
            _UserFavoriteArticlesList(userId: user.uid),
            if (isAdmin) ...[
              const SizedBox(height: 32),
              Text(
                'User Lookup',
                style:
                    textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
              ),
              const SizedBox(height: 12),
              const _UserLookupSection(),
              const SizedBox(height: 20),
              Text(
                'The Whiskey Manuscript Databases',
                style: textTheme.titleMedium?.copyWith(color: AppColors.leatherDark),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DatabaseLinkButton(
                    label: 'Whiskey',
                    onTap: () => _openWhiskeyDatabasePage(context),
                  ),
                  _DatabaseLinkButton(
                    label: 'Distillery',
                    onTap: () => _openDistilleryDatabasePage(context),
                  ),
                  _DatabaseLinkButton(
                    label: 'Articles',
                    onTap: () => _openArticlesDatabasePage(context),
                  ),
                  _DatabaseLinkButton(
                    label: 'Merchandise',
                    onTap: () => _openMerchDatabasePage(context),
                  ),
                  _DatabaseLinkButton(
                    label: 'Events',
                    onTap: () => _openEventsDatabasePage(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
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

// ignore: unused_element
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


















