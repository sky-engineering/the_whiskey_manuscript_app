import 'package:flutter/material.dart';

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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme(
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
    );

    final textTheme = ThemeData().textTheme.apply(
          bodyColor: AppColors.darkGreen,
          displayColor: AppColors.darkGreen,
        );

    return MaterialApp(
      title: 'The Whiskey Manuscript',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: AppColors.neutralLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkGreen,
          foregroundColor: AppColors.onDark,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.lightNeutral,
          indicatorColor: AppColors.greenLight,
          iconTheme: const MaterialStatePropertyAll(
            IconThemeData(color: AppColors.darkGreen),
          ),
          labelTextStyle: MaterialStatePropertyAll(
            textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightNeutral,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.neutralMid),
          ),
        ),
        textTheme: textTheme,
        useMaterial3: true,
      ),
      home: const DashboardShell(),
    );
  }
}

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  static const List<_PageConfig> _pageConfigs = [
    _PageConfig(label: 'Social', icon: Icons.groups_rounded, view: SocialPage()),
    _PageConfig(label: 'Content', icon: Icons.menu_book_rounded, view: ContentPage()),
    _PageConfig(label: 'Messages', icon: Icons.chat_bubble_rounded, view: MessagesPage()),
    _PageConfig(label: 'Events', icon: Icons.event_available_rounded, view: EventsPage()),
    _PageConfig(label: 'Profile', icon: Icons.person_rounded, view: ProfilePage()),
  ];

  void _onItemTapped(int newIndex) {
    if (newIndex == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = _pageConfigs[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPage.label),
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

class _PageConfig {
  final String label;
  final IconData icon;
  final Widget view;

  const _PageConfig({required this.label, required this.icon, required this.view});
}

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PageLayout(
      title: 'Raise a Glass',
      description:
          'Connect with the community, swap tasting notes, and celebrate new discoveries.',
      highlights: [
        'Community feed',
        'Tasting circles',
        'Trending bottles',
      ],
    );
  }
}

class ContentPage extends StatelessWidget {
  const ContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PageLayout(
      title: 'Curated Content',
      description:
          'Dive into articles, videos, and tasting guides selected for whiskey lovers.',
      highlights: [
        'Editor\'s picks',
        'Distillery spotlights',
        'Flavor maps',
      ],
    );
  }
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PageLayout(
      title: 'Direct Messages',
      description:
          'Coordinate bottle trades, RSVP to tastings, or say hello to a new friend.',
      highlights: [
        'Inbox overview',
        'Group chats',
        'Message requests',
      ],
    );
  }
}

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PageLayout(
      title: 'Events Calendar',
      description:
          'Track upcoming releases, live tastings, and member meetups around the globe.',
      highlights: [
        'Featured tastings',
        'Local meetups',
        'Virtual masterclasses',
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PageLayout(
      title: 'Profile & Cellar',
      description:
          'Showcase your collection, manage preferences, and update your membership details.',
      highlights: [
        'Personal stats',
        'Saved bottles',
        'Membership settings',
      ],
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
