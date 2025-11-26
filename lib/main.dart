import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'src/repositories/firestore_repository.dart';
import 'package:the_whiskey_manuscript_app/src/pages/article_detail_page.dart';
import 'src/theme/app_colors.dart';
import 'src/dashboard/dashboard_shell.dart';

part 'src/pages/dashboard/social_page.dart';
part 'src/pages/dashboard/social_feed_widgets.dart';
part 'src/pages/dashboard/content_page.dart';
part 'src/pages/dashboard/messages_page.dart';
part 'src/pages/dashboard/events_page.dart';
part 'src/pages/dashboard/profile_page.dart';
part 'src/pages/dashboard/profile_info_widgets.dart';
part 'src/pages/dashboard/common_dialogs.dart';
part 'src/pages/dashboard/user_library_widgets.dart';
part 'src/pages/dashboard/admin_database_widgets.dart';
part 'src/pages/dashboard/library_admin.dart';

const List<String> membershipLevels = ['Neat', 'Cask', 'Manuscript'];

const Map<String, String> membershipDescriptions = {
  'Neat': 'Classic access to the community, social feed, and curated stories.',
  'Cask': 'Extended perks including event RSVPs and deeper content drops.',
  'Manuscript':
      'Full access to rare releases, private salons, and archival notes.',
};

const List<DashboardTabConfig> _dashboardTabs = [
  DashboardTabConfig(
    label: 'Social',
    icon: Icons.groups_rounded,
    view: SocialPage(),
  ),
  DashboardTabConfig(
    label: 'Content',
    icon: Icons.menu_book_rounded,
    view: ContentPage(),
  ),
  DashboardTabConfig(
    label: 'Messages',
    icon: Icons.chat_bubble_rounded,
    view: MessagesPage(),
  ),
  DashboardTabConfig(
    label: 'Events',
    icon: Icons.event_available_rounded,
    view: EventsPage(),
  ),
  DashboardTabConfig(
    label: 'Profile',
    icon: Icons.person_rounded,
    view: ProfilePage(),
  ),
];

const List<String> whiskeyStyles = [
  'Single Malt',
  'Blend',
  'Bourbon',
  'Rye',
  'Cask Strength',
  'Other',
];

const List<String> whiskeyCategories = [
  'Scotch',
  'Bourbon',
  'Rye',
  'Irish',
  'Japanese',
  'American',
  'Canadian',
  'World',
];

const List<String> whiskeySubCategories = [
  'Single Malt',
  'Blended Malt',
  'Single Grain',
  'Blended Whiskey',
  'Cask Strength',
  'Finished',
  'Single Barrel',
  'Small Batch',
  'Other',
];

const List<String> whiskeyReleaseTypes = [
  'Standard',
  'Single Barrel',
  'Store Pick',
  'Limited Release',
];

const List<String> whiskeyRarityLevels = [
  'Everyday',
  'Limited',
  'Annual',
  'Ultra-Rare',
];

const List<String> whiskeyAvailabilityStatuses = [
  'Common',
  'Hard-to-Find',
  'Limited',
  'Discontinued',
];

const List<String> distillerySpotlights = [
  'Heritage House',
  'Experimental Lab',
  'Independent Bottler',
  'New World Grain',
  'Peated Specialist',
  'Other',
];

const List<String> producerPlaceTypes = [
  'Distillery',
  'Independent Bottler',
  'Brand',
  'Bar',
  'Tasting Room',
  'Experience Venue',
];

const List<String> articleCategories = [
  'Education',
  'History',
  'Tasting Guide',
  'Feature',
  'WOTM',
  'Distillery Profile',
  'Travel',
  'Release News',
  'Other',
];

const List<String> merchCategories = [
  'apparel',
  'glassware',
  'accessories',
  'limited_release',
  'art',
  'books',
  'experiences',
  'other',
];

const List<String> merchandiseMembershipTiers = [
  'neat',
  'cask',
  'manuscript',
];

String _titleize(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return normalized;
  return normalized
      .split(RegExp(r'[_\s]+'))
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            segment[0].toUpperCase() +
            (segment.length > 1 ? segment.substring(1).toLowerCase() : ''),
      )
      .join(' ');
}

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
        if (snapshot.hasData) {
          return const DashboardShell(configs: _dashboardTabs);
        }
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

/// ------------------------------------------------------------
