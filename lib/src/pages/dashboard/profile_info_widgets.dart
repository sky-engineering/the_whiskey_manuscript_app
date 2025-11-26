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
  final FirestoreRepository repository;
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

class _ProfileInfoCardState extends State<_ProfileInfoCard> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _regionController;
  late final TextEditingController _postalController;
  late final TextEditingController _birthYearController;

  String _countryCode = 'US';
  bool _allowLocationFeatures = false;
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
        oldWidget.allowLocationBasedFeatures !=
            widget.allowLocationBasedFeatures ||
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
    _allowLocationFeatures = widget.allowLocationBasedFeatures;
    _isDirty = false;
    _isSaving = false;
    if (mounted) setState(() {});
  }

  void _markDirty() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
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
      'allowLocationBasedFeatures': _allowLocationFeatures,
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
    final memberSince = widget.memberSince;
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
                  radius: 36,
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: AppColors.onDark,
                  child: Text(
                    widget.initials,
                    style: const TextStyle(
                      fontSize: 28,
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
                        resolvedName,
                        style: textTheme.titleLarge
                            ?.copyWith(color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.email,
                              style: textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.leatherDark),
                            ),
                          ),
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: widget.emailVerified
                                ? Colors.green
                                : AppColors.leatherDark.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                      if (memberSince != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Member since //',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.leatherDark),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ProfileInfoRow(
                    label: 'Membership',
                    value: ' · ',
                  ),
                ),
                TextButton(
                  onPressed: _openMembershipDetails,
                  child: const Text('View details'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: widget.membership,
              decoration: const InputDecoration(
                labelText: 'Update level',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final option in membershipLevels)
                  DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ),
              ],
              onChanged: (value) => widget.onMembershipChanged(value),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _FollowerStat(
                  userId: widget.userId,
                  repository: widget.repository,
                ),
                _FollowingStat(
                  userId: widget.userId,
                  repository: widget.repository,
                ),
                _PostCountSummary(
                  userId: widget.userId,
                  repository: widget.repository,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileInfoRow(
              label: 'Primary Email',
              value: widget.email,
              allowCopy: true,
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow location-based features'),
              subtitle: const Text(
                'Enables experiences tailored to your location.',
              ),
              value: _allowLocationFeatures,
              onChanged: (value) {
                setState(() {
                  _allowLocationFeatures = value;
                  _isDirty = true;
                });
              },
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
          return const _ProfileStatChip(label: 'Followers unavailable');
        }
        final count = snapshot.data?.docs.length ?? 0;
        final label = count == 1 ? '1 follower' : ' followers';
        return _ProfileStatChip(label: label);
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
          return const _ProfileStatChip(label: 'Following unavailable');
        }
        final count = snapshot.data?.docs.length ?? 0;
        final label = count == 1 ? '1 following' : ' following';
        return _ProfileStatChip(label: label);
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
          return const _ProfileStatChip(label: 'Posts unavailable');
        }
        final count = snapshot.data?.docs.length ?? 0;
        final label = count == 1 ? '1 post' : ' posts';
        return _ProfileStatChip(label: label);
      },
    );
  }
}

class _ProfileStatChip extends StatelessWidget {
  const _ProfileStatChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.neutralLight,
        border: Border.all(
          color: AppColors.darkGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkGreen,
          fontWeight: FontWeight.w600,
        ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class MembershipDetailsPage extends StatelessWidget {
  const MembershipDetailsPage({
    super.key,
    required this.userId,
    required this.fallbackTier,
  });

  final String userId;
  final String fallbackTier;

  @override
  Widget build(BuildContext context) {
    final docStream =
        FirebaseFirestore.instance.collection('users').doc(userId);
    return Scaffold(
      appBar: AppBar(title: const Text('Membership details')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docStream.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load membership.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() ?? const <String, dynamic>{};
          final tier = (data['membershipLevel'] as String?) ?? fallbackTier;
          final description =
              membershipDescriptions[tier] ?? 'Exclusive experiences.';
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppColors.darkGreen),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.leatherDark),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
