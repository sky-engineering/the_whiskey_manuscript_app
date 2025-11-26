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
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
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
                      Text(
                        widget.membershipDescription,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.leatherDark.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
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
