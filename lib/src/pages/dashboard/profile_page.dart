part of 'package:the_whiskey_manuscript_app/main.dart';

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
        const SnackBar(content: Text('Producer/place spotlight saved.')),
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

  void _openSavedWhiskeyList(
    BuildContext context, {
    required String userId,
    required String collectionName,
    required String title,
    required String emptyMessage,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SavedWhiskeyListPage(
          userId: userId,
          collectionName: collectionName,
          title: title,
          emptyMessage: emptyMessage,
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

  void _openFavoriteDistilleriesPage(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FavoriteDistilleriesPage(userId: userId),
      ),
    );
  }

  void _openFavoriteArticlesPage(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FavoriteArticlesPage(userId: userId),
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

    final repository = FirestoreRepository();

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
        const collectionEmptyMessage =
            'Your Library is blank.\nBrowse the Content tab and add your first entry.';
        const wishlistEmptyMessage =
            'Your Wishlist is empty.\nExplore the Content tab to plan your next pour.';
        final roleValue = (userData['role'] as String? ?? 'user').toLowerCase();
        final isAdmin = roleValue == 'admin';
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
              repository: repository,
              initials: initials,
              primaryName: primaryName,
              email: email,
              emailVerified: emailVerified,
              membership: membership,
              membershipDescription: membershipDescription,
              firstName: firstName,
              lastName: lastName,
              countryCode: countryCode,
              city: city,
              region: region,
              postalCode: postalCode,
              birthYear: birthYear,
              onSave: saveProfileData,
              onMembershipChanged: updateMembership,
            ),
            const SizedBox(height: 32),
            Text(
              'Collections & Favorites',
              style: textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 12),
            _ProfileCollectionLink(
              icon: Icons.local_bar_rounded,
              title: 'Whiskey Collection',
              subtitle: 'See every bottle in your personal library.',
              onTap: () => _openSavedWhiskeyList(
                context,
                userId: user.uid,
                collectionName: 'whiskeyCollection',
                title: 'Whiskey Collection',
                emptyMessage: collectionEmptyMessage,
              ),
            ),
            const SizedBox(height: 12),
            _ProfileCollectionLink(
              icon: Icons.favorite_rounded,
              title: 'Whiskey Wishlist',
              subtitle: 'Plan the pours you still want to try.',
              onTap: () => _openSavedWhiskeyList(
                context,
                userId: user.uid,
                collectionName: 'whiskeyWishlist',
                title: 'Whiskey Wishlist',
                emptyMessage: wishlistEmptyMessage,
              ),
            ),
            const SizedBox(height: 12),
            _ProfileCollectionLink(
              icon: Icons.map_rounded,
              title: 'Favorite Producers & Places',
              subtitle: 'Keep track of the destinations you love most.',
              onTap: () => _openFavoriteDistilleriesPage(context, user.uid),
            ),
            const SizedBox(height: 12),
            _ProfileCollectionLink(
              icon: Icons.article_rounded,
              title: 'Favorite Articles',
              subtitle: 'Revisit insights and stories that resonated.',
              onTap: () => _openFavoriteArticlesPage(context, user.uid),
            ),
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
                style: textTheme.titleMedium
                    ?.copyWith(color: AppColors.leatherDark),
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
                    label: 'Producers and Places',
                    onTap: () => _openDistilleryDatabasePage(context),
                  ),
                  _DatabaseLinkButton(
                    label: 'Articles',
                    onTap: () => _openArticlesDatabasePage(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Additional Links',
                style: textTheme.titleMedium
                    ?.copyWith(color: AppColors.leatherDark),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DatabaseLinkButton(
                    label: 'Merchandise',
                    onTap: () => _openMerchDatabasePage(context),
                  ),
                  _DatabaseLinkButton(
                    label: 'Events',
                    onTap: () => _openEventsDatabasePage(context),
                  ),
                  _DatabaseLinkButton(
                    label: 'Featured Whiskeys',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FeaturedWhiskeyAdminPage(),
                      ),
                    ),
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
            _UserPostsList(userId: user.uid, repository: repository),
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

class _ProfileCollectionLink extends StatelessWidget {
  const _ProfileCollectionLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.neutralLight,
          foregroundColor: AppColors.darkGreen,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: textTheme.titleMedium?.copyWith(color: AppColors.darkGreen),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.leatherDark),
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.leatherDark),
      ),
    );
  }
}
