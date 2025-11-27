// ignore_for_file: prefer_const_constructors, deprecated_member_use
part of 'package:the_whiskey_manuscript_app/main.dart';

class _ProfileInfoCard extends StatefulWidget {
  const _ProfileInfoCard({
    required this.userId,
    required this.repository,
    required this.initials,
    required this.primaryName,
    required this.email,
    required this.emailVerified,
    required this.membership,
    required this.membershipDescription,
    required this.firstName,
    required this.lastName,
    required this.countryCode,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.birthYear,
    required this.onSave,
    required this.onMembershipChanged,
  });

  final String userId;
  final FirestoreRepository repository;
  final String initials;
  final String primaryName;
  final String email;
  final bool emailVerified;
  final String membership;
  final String membershipDescription;
  final String? firstName;
  final String? lastName;
  final String countryCode;
  final String? city;
  final String? region;
  final String? postalCode;
  final int? birthYear;
  final Future<void> Function(Map<String, dynamic> data,
      {String? successMessage}) onSave;
  final Future<void> Function(String? level) onMembershipChanged;

  @override
  State<_ProfileInfoCard> createState() => _ProfileInfoCardState();
}

class _ProfileInfoCardState extends State<_ProfileInfoCard> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _regionController;
  late final TextEditingController _postalController;
  late final TextEditingController _birthYearController;

  String _countryCode = 'US';
  bool _isDirty = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _cityController = TextEditingController();
    _regionController = TextEditingController();
    _postalController = TextEditingController();
    _birthYearController = TextEditingController();
    _hydrateFromWidget();
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _cityController,
      _regionController,
      _postalController,
      _birthYearController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDirty && _hasChanged(oldWidget)) {
      _hydrateFromWidget();
    }
  }

  bool _hasChanged(_ProfileInfoCard oldWidget) {
    return oldWidget.firstName != widget.firstName ||
        oldWidget.lastName != widget.lastName ||
        oldWidget.city != widget.city ||
        oldWidget.region != widget.region ||
        oldWidget.postalCode != widget.postalCode ||
        oldWidget.countryCode != widget.countryCode ||
        oldWidget.birthYear != widget.birthYear ||
        oldWidget.membership != widget.membership ||
        oldWidget.emailVerified != widget.emailVerified;
  }

  void _hydrateFromWidget() {
    _firstNameController.text = widget.firstName?.trim() ?? '';
    _lastNameController.text = widget.lastName?.trim() ?? '';
    _cityController.text = widget.city?.trim() ?? '';
    _regionController.text = widget.region?.trim() ?? '';
    _postalController.text = widget.postalCode?.trim() ?? '';
    _birthYearController.text =
        widget.birthYear != null ? widget.birthYear.toString() : '';
    _countryCode = widget.countryCode;
    _isDirty = false;
    _isSaving = false;
    if (mounted) setState(() {});
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  Future<void> _handleSignOut() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseAuth.instance.signOut();
      navigator.pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not sign out: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final data = <String, dynamic>{
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'city': _cityController.text.trim(),
      'region': _regionController.text.trim(),
      'postalCode': _postalController.text.trim(),
      'countryCode': _countryCode,
    };
    final birthYearText = _birthYearController.text.trim();
    if (birthYearText.isNotEmpty) {
      final parsed = int.tryParse(birthYearText);
      if (parsed != null) data['birthYear'] = parsed;
    }
    data.removeWhere((key, value) => value is String && value.isEmpty);
    try {
      await widget.onSave(data, successMessage: 'Profile updated.');
      _hydrateFromWidget();
      _showSnack('Profile saved.');
    } catch (e) {
      _showSnack('Could not save profile: ');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _revertChanges() {
    _hydrateFromWidget();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openMembershipManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MembershipManagementPage(
          initialMembership: widget.membership,
          onMembershipChanged: widget.onMembershipChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _firstNameController,
      _lastNameController,
      _cityController,
      _regionController,
      _postalController,
      _birthYearController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseNameStyle =
        textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final nameStyle = baseNameStyle.copyWith(
      fontSize: (baseNameStyle.fontSize ?? 16) * 1.5,
      color: AppColors.darkGreen,
      fontWeight: FontWeight.w600,
    );
    final nameParts = <String>[
      if (widget.firstName != null && widget.firstName!.trim().isNotEmpty)
        widget.firstName!.trim(),
      if (widget.lastName != null && widget.lastName!.trim().isNotEmpty)
        widget.lastName!.trim(),
    ];
    final resolvedName =
        nameParts.isEmpty ? widget.primaryName : nameParts.join(' ');

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
                  radius: 72,
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
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedName,
                        style: nameStyle,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openMembershipManagement,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(
                          'Membership Type: ${widget.membership}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.leatherDark,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Sign out',
                            onPressed: _handleSignOut,
                            icon: const Icon(Icons.logout_rounded),
                          ),
                          TextButton(
                            onPressed: _handleSignOut,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                            child: Text(
                              'Sign Out',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.leatherDark,
                                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 24),
            Row(
              children: [
                _FollowerStat(
                  userId: widget.userId,
                  repository: widget.repository,
                ),
                const SizedBox(width: 16),
                _FollowingStat(
                  userId: widget.userId,
                  repository: widget.repository,
                ),
                const SizedBox(width: 16),
                _PostCountSummary(
                  userId: widget.userId,
                  repository: widget.repository,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileInfoRow(
              label: 'Email',
              value: widget.email,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ProfileEditableField(
                    label: 'First name',
                    controller: _firstNameController,
                    keyboardType: TextInputType.name,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileEditableField(
                    label: 'Last name',
                    controller: _lastNameController,
                    keyboardType: TextInputType.name,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _countryCode,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final option in countryOptions)
                  DropdownMenuItem(
                    value: option.code,
                    child: Text(option.name),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _countryCode = value;
                  _isDirty = true;
                });
              },
            ),
            const SizedBox(height: 12),
            _ProfileEditableField(
              label: 'City',
              controller: _cityController,
            ),
            const SizedBox(height: 12),
            _ProfileEditableField(
              label: 'Region/State',
              controller: _regionController,
            ),
            const SizedBox(height: 12),
            _ProfileEditableField(
              label: 'Postal code',
              controller: _postalController,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            _ProfileEditableField(
              label: 'Birth year',
              controller: _birthYearController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isDirty && !_isSaving ? _revertChanges : null,
                  child: const Text('Revert changes'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isDirty && !_isSaving ? _saveProfile : null,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowerStat extends StatelessWidget {
  const _FollowerStat({
    required this.userId,
    required this.repository,
  });

  final String userId;
  final FirestoreRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.followersStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ProfileStatLabel(label: 'Followers unavailable');
        }
        final docs = snapshot.data?.docs ?? [];
        final count = docs.length;
        final label = count == 1 ? '1 follower' : '$count followers';
        return _ProfileStatLabel(
          label: label,
          onTap: () => _showConnectionsSheet(
            context,
            title: 'Followers',
            docs: docs,
            emptyMessage: 'No one follows this member yet.',
            showFollowActions: true,
            currentUserId: userId,
          ),
        );
      },
    );
  }
}

class _FollowingStat extends StatelessWidget {
  const _FollowingStat({
    required this.userId,
    required this.repository,
  });

  final String userId;
  final FirestoreRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.followingStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ProfileStatLabel(label: 'Following unavailable');
        }
        final docs = snapshot.data?.docs ?? [];
        final count = docs.length;
        final label = count == 1 ? '1 following' : '$count following';
        return _ProfileStatLabel(
          label: label,
          onTap: () => _showConnectionsSheet(
            context,
            title: 'Following',
            docs: docs,
            emptyMessage: 'This member is not following anyone yet.',
            showUnfollowActions: true,
            currentUserId: userId,
          ),
        );
      },
    );
  }
}

class _PostCountSummary extends StatelessWidget {
  const _PostCountSummary({
    required this.userId,
    required this.repository,
  });

  final String userId;
  final FirestoreRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.userPostsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _ProfileStatLabel(label: 'Posts unavailable');
        }
        final count = snapshot.data?.docs.length ?? 0;
        final label = count == 1 ? '1 post' : '$count posts';
        return _ProfileStatLabel(label: label);
      },
    );
  }
}

Future<void> _showConnectionsSheet(
  BuildContext context, {
  required String title,
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  required String emptyMessage,
  bool showFollowActions = false,
  bool showUnfollowActions = false,
  String? currentUserId,
}) async {
  final entries = docs.map(_ProfileConnectionEntry.fromSnapshot).toList()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  final messenger = ScaffoldMessenger.maybeOf(context);
  final friendService = FriendService();
  final pendingUserIds = <String>{};
  var allowFollowActions = showFollowActions && currentUserId != null;
  var allowUnfollowActions = showUnfollowActions && currentUserId != null;
  var followingIds = <String>{};
  var searchQuery = '';

  if (allowUnfollowActions) {
    followingIds = entries.map((entry) => entry.userId).toSet();
  }

  if (allowFollowActions) {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .get();
      followingIds = snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      allowFollowActions = false;
      messenger?.showSnackBar(
        SnackBar(content: Text('Could not load following data: $e')),
      );
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final surfaceColor = Theme.of(sheetContext).colorScheme.surface;
      return FractionallySizedBox(
        heightFactor: 0.5,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: surfaceColor,
            child: SafeArea(
              top: false,
              child: StatefulBuilder(
                builder: (context, setState) {
                  final followLabelStyle =
                      Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.neutralMid.withOpacity(0.6),
                              ) ??
                          TextStyle(
                            color: AppColors.neutralMid.withOpacity(0.6),
                          );
                  final filteredEntries = searchQuery.isEmpty
                      ? entries
                      : entries
                          .where((entry) =>
                              entry.title.toLowerCase().contains(searchQuery))
                          .toList();
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.neutralMid,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppColors.darkGreen),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (entries.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search members...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              isDense: true,
                            ),
                            onChanged: (value) => setState(
                              () => searchQuery = value.trim().toLowerCase(),
                            ),
                          ),
                        ),
                      Expanded(
                        child: entries.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Text(
                                    emptyMessage,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : filteredEntries.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: Text(
                                        'No members match your search.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    itemCount: filteredEntries.length,
                                    itemBuilder: (_, index) {
                                      final entry = filteredEntries[index];
                                      final alreadyFollowing =
                                          followingIds.contains(entry.userId);
                                      final canFollow = allowFollowActions &&
                                          entry.userId != currentUserId;
                                      final isPending =
                                          pendingUserIds.contains(entry.userId);
                                      Widget? trailing;
                                      if (allowUnfollowActions &&
                                          alreadyFollowing) {
                                        trailing = TextButton(
                                          onPressed: isPending ||
                                                  entry.userId == currentUserId
                                              ? null
                                              : () async {
                                                  setState(() {
                                                    pendingUserIds
                                                        .add(entry.userId);
                                                  });
                                                  try {
                                                    await friendService
                                                        .removeFriend(
                                                            entry.userId);
                                                    setState(() {
                                                      pendingUserIds
                                                          .remove(entry.userId);
                                                      followingIds
                                                          .remove(entry.userId);
                                                      entries.removeWhere(
                                                        (item) =>
                                                            item.userId ==
                                                            entry.userId,
                                                      );
                                                    });
                                                    messenger?.showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Unfollowed ${entry.title}.',
                                                        ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    setState(() {
                                                      pendingUserIds
                                                          .remove(entry.userId);
                                                    });
                                                    messenger?.showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Unable to unfollow: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: isPending
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text('Unfollow'),
                                        );
                                      } else if (canFollow &&
                                          !alreadyFollowing) {
                                        trailing = TextButton(
                                          onPressed: isPending
                                              ? null
                                              : () async {
                                                  setState(() {
                                                    pendingUserIds
                                                        .add(entry.userId);
                                                  });
                                                  try {
                                                    await friendService
                                                        .addFriend(
                                                            entry.userId);
                                                    setState(() {
                                                      pendingUserIds
                                                          .remove(entry.userId);
                                                      followingIds
                                                          .add(entry.userId);
                                                    });
                                                    messenger?.showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Now following ${entry.title}.',
                                                        ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    setState(() {
                                                      pendingUserIds
                                                          .remove(entry.userId);
                                                    });
                                                    messenger?.showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Unable to follow: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: isPending
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : const Text('Follow'),
                                        );
                                      } else if (alreadyFollowing) {
                                        trailing = Text(
                                          'Following',
                                          style: followLabelStyle,
                                        );
                                      }
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(entry.title),
                                        trailing: trailing,
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 12),
                                  ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ProfileConnectionEntry {
  const _ProfileConnectionEntry({
    required this.userId,
    required this.title,
  });

  final String userId;
  final String title;

  factory _ProfileConnectionEntry.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final displayName = (data['displayName'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim();

    final resolvedTitle = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (email != null && email.isNotEmpty)
            ? email
            : doc.id;

    return _ProfileConnectionEntry(
      userId: doc.id,
      title: resolvedTitle,
    );
  }
}

class _ProfileStatLabel extends StatelessWidget {
  const _ProfileStatLabel({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.leatherDark, fontWeight: FontWeight.w600) ??
          const TextStyle(
              color: AppColors.leatherDark, fontWeight: FontWeight.w600),
    );

    if (onTap == null) return text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: text,
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    this.value,
    this.allowCopy = false,
  });

  final String label;
  final String? value;
  final bool allowCopy;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = (value == null || value!.trim().isEmpty)
        ? 'Not provided'
        : value!.trim();
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.leatherDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                resolvedValue,
                style: textTheme.titleMedium,
              ),
            ],
          ),
        ),
        if (allowCopy && value != null && value!.trim().isNotEmpty)
          IconButton(
            tooltip: 'Copy ',
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: resolvedValue));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(' copied.')),
              );
            },
          ),
      ],
    );
  }
}

class _ProfileEditableField extends StatelessWidget {
  const _ProfileEditableField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

class MembershipManagementPage extends StatefulWidget {
  const MembershipManagementPage({
    super.key,
    required this.initialMembership,
    required this.onMembershipChanged,
  });

  final String initialMembership;
  final Future<void> Function(String? level) onMembershipChanged;

  @override
  State<MembershipManagementPage> createState() =>
      _MembershipManagementPageState();
}

class _MembershipManagementPageState extends State<MembershipManagementPage> {
  late String _selectedLevel;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialMembership;
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onMembershipChanged(_selectedLevel);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not update: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description =
        membershipDescriptions[_selectedLevel] ?? 'Exclusive experiences.';
    final canSave = _selectedLevel != widget.initialMembership;

    return Scaffold(
      appBar: AppBar(title: const Text('Update membership')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your membership type',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Membership level',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final option in membershipLevels)
                  DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedLevel = value;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.leatherDark,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.redAccent,
                ),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: canSave && !_isSaving ? _handleSave : null,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save changes'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
