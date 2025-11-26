part of 'package:the_whiskey_manuscript_app/main.dart';

class _UserSavedWhiskeyList extends StatelessWidget {
  const _UserSavedWhiskeyList({
    required this.userId,
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatEventDate(
                            _coerceTimestamp(doc.data()['addedAt'])),
                        style: const TextStyle(color: AppColors.leatherDark),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.leatherDark,
                        onPressed: () => _removeSavedWhiskey(context, doc),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _removeSavedWhiskey(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final rawName = (doc.data()['name'] as String? ?? '').trim();
    final resolvedName = rawName.isEmpty ? 'this whiskey' : rawName;
    final targetLabel =
        collectionName == 'whiskeyWishlist' ? 'wishlist' : 'collection';
    final confirmed = await _confirmDeletion(
      context,
      title: 'Remove whiskey',
      message: 'Delete $resolvedName from your $targetLabel?',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;
    await _performDeletion(
      context,
      action: () => doc.reference.delete(),
      successMessage: '$resolvedName removed from your $targetLabel.',
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
            message: 'We could not load favorite producers and places.',
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
                'Your Producers and Places list is blank.\nVisit the Content tab and mark your first favorite.',
          );
        }

        return Column(
          children: [
            for (final doc in docs)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    doc.data()['name'] as String? ?? 'Producer or Place',
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
  const _WhiskeyCard({
    required this.whiskeyName,
    required this.categoryLabel,
    required this.region,
    required this.shortDescription,
    required this.authorLabel,
    required this.timestamp,
    this.brand,
    this.distilleryName,
    this.country,
    this.subCategory,
    this.ageStatement,
    this.abv,
    this.proof,
    this.releaseType,
    this.vintageOrBatch,
    this.yearReleased,
    this.msrp,
    this.priceLow,
    this.priceHigh,
    this.rarityLevel,
    this.availabilityStatus,
    this.tags = const [],
    this.isHighlighted = false,
    this.imageUrl,
    this.membership,
    this.showAuthor = true,
    this.onDelete,
  });

  final String whiskeyName;
  final String categoryLabel;
  final String region;
  final String shortDescription;
  final String authorLabel;
  final DateTime timestamp;
  final String? brand;
  final String? distilleryName;
  final String? country;
  final String? subCategory;
  final String? ageStatement;
  final double? abv;
  final double? proof;
  final String? releaseType;
  final String? vintageOrBatch;
  final int? yearReleased;
  final double? msrp;
  final double? priceLow;
  final double? priceHigh;
  final String? rarityLevel;
  final String? availabilityStatus;
  final List<String> tags;
  final bool isHighlighted;
  final String? imageUrl;
  final String? membership;
  final bool showAuthor;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final descriptionStyle =
        textTheme.bodyMedium?.copyWith(color: AppColors.leatherDark);
    final pillWidgets = <Widget>[
      if ((subCategory ?? '').trim().isNotEmpty)
        _buildPill(subCategory!.trim()),
      if ((ageStatement ?? '').trim().isNotEmpty)
        _buildPill(ageStatement!.trim()),
      if (abv != null) _buildPill('${abv!.toStringAsFixed(1)}% ABV'),
      if (proof != null) _buildPill('${proof!.toStringAsFixed(1)} proof'),
      if ((releaseType ?? '').trim().isNotEmpty)
        _buildPill(releaseType!.trim()),
      if ((vintageOrBatch ?? '').trim().isNotEmpty)
        _buildPill('Batch ${vintageOrBatch!.trim()}'),
      if (yearReleased != null) _buildPill('Released $yearReleased'),
      if ((rarityLevel ?? '').trim().isNotEmpty)
        _buildPill('Rarity: ${rarityLevel!.trim()}'),
      if ((availabilityStatus ?? '').trim().isNotEmpty)
        _buildPill('Availability: ${availabilityStatus!.trim()}'),
    ];

    final originParts = <String>[
      if ((country ?? '').trim().isNotEmpty) country!.trim(),
      if (region.trim().isNotEmpty) region.trim(),
    ];

    final priceLine = _buildPriceLine();
    final sanitizedTags = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];

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
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildCachedImage(
                        imageUrl!,
                        width: 96,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        whiskeyName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildCategoryLabel(),
                        style: descriptionStyle,
                      ),
                      if ((brand ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Brand - ${brand!.trim()}',
                            style: descriptionStyle),
                      ],
                      if ((distilleryName ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Producer or Place - ${distilleryName!.trim()}',
                            style: descriptionStyle),
                      ],
                    ],
                  ),
                ),
                if (membership != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Chip(
                      label: Text(membership!),
                      backgroundColor: AppColors.neutralLight,
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
            if (originParts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(originParts.join(' - '), style: descriptionStyle),
            ],
            if (shortDescription.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                shortDescription.trim(),
                style:
                    textTheme.bodyLarge?.copyWith(color: AppColors.darkGreen),
              ),
            ],
            if (pillWidgets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: pillWidgets,
              ),
            ],
            if (priceLine != null) ...[
              const SizedBox(height: 12),
              Text(priceLine, style: descriptionStyle),
            ],
            if (sanitizedTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in sanitizedTags)
                    Chip(
                      label: Text(tag),
                      backgroundColor: AppColors.neutralLight,
                    ),
                ],
              ),
            ],
            if (isHighlighted) ...[
              const SizedBox(height: 12),
              _buildStatusChip('Highlighted'),
            ],
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

  String _buildCategoryLabel() {
    final buffer = StringBuffer(categoryLabel.trim());
    if ((subCategory ?? '').trim().isNotEmpty) {
      buffer.write(' - ');
      buffer.write(subCategory!.trim());
    }
    return buffer.toString();
  }

  String? _buildPriceLine() {
    final parts = <String>[];
    if (msrp != null) {
      parts.add('MSRP ${_formatCurrency(msrp!)}');
    }
    if (priceLow != null && priceHigh != null) {
      parts.add(
          'Typical ${_formatCurrency(priceLow!)} to ${_formatCurrency(priceHigh!)}');
    }
    if (parts.isEmpty) return null;
    return parts.join(' | ');
  }

  String _formatCurrency(double value) {
    final decimals = value == value.roundToDouble() ? 0 : 2;
    return '\$${value.toStringAsFixed(decimals)}';
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.leatherDark),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    return Chip(
      label: Text(label),
      avatar: const Icon(
        Icons.star_rounded,
        size: 16,
        color: AppColors.darkGreen,
      ),
      backgroundColor: AppColors.neutralLight,
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.darkGreen.withValues(alpha: 0.3)),
      ),
    );
  }
}

_WhiskeyCard _buildWhiskeyCardFromData(
  Map<String, dynamic> data, {
  required String authorLabel,
  required DateTime timestamp,
  String? membership,
  bool showAuthor = true,
  VoidCallback? onDelete,
}) {
  final tags = ((data['tags'] as List?)
          ?.whereType<String>()
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList() ??
      const <String>[]);
  return _WhiskeyCard(
    whiskeyName: data['name'] as String? ?? 'Untitled Bottle',
    categoryLabel: data['category'] as String? ??
        data['style'] as String? ??
        'Special Release',
    region: data['region'] as String? ?? 'Unknown region',
    shortDescription:
        (data['shortDescription'] as String? ?? data['notes'] as String? ?? '')
            .trim(),
    authorLabel: authorLabel,
    timestamp: timestamp,
    membership: membership,
    showAuthor: showAuthor,
    onDelete: onDelete,
    brand: data['brand'] as String?,
    distilleryName: data['distilleryName'] as String?,
    country: data['country'] as String?,
    subCategory: data['subCategory'] as String?,
    ageStatement: data['ageStatement'] as String?,
    abv: (data['abv'] as num?)?.toDouble(),
    proof: (data['proof'] as num?)?.toDouble(),
    releaseType: data['releaseType'] as String?,
    vintageOrBatch: data['vintageOrBatch'] as String?,
    yearReleased: (data['yearReleased'] as num?)?.toInt(),
    msrp: (data['msrp'] as num?)?.toDouble(),
    priceLow: (data['priceLow'] as num?)?.toDouble(),
    priceHigh: (data['priceHigh'] as num?)?.toDouble(),
    rarityLevel: data['rarityLevel'] as String?,
    availabilityStatus: data['availabilityStatus'] as String?,
    tags: tags,
    isHighlighted: data['isHighlighted'] as bool? ?? false,
    imageUrl: data['imageUrl'] as String?,
  );
}
