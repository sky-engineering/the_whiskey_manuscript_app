part of 'package:the_whiskey_manuscript_app/main.dart';

class _AddWhiskeySheet extends StatelessWidget {
  const _AddWhiskeySheet();

  @override
  Widget build(BuildContext context) {
    return const _WhiskeyForm.addSheet();
  }
}

enum _WhiskeyFormMode { add, edit }

enum _WhiskeyFormLayout { sheet, dialog }

class _WhiskeyForm extends StatefulWidget {
  const _WhiskeyForm.addSheet()
      : mode = _WhiskeyFormMode.add,
        layout = _WhiskeyFormLayout.sheet,
        whiskeyId = null,
        initialData = const <String, dynamic>{};

  const _WhiskeyForm.editDialog({
    required this.whiskeyId,
    required this.initialData,
  })  : mode = _WhiskeyFormMode.edit,
        layout = _WhiskeyFormLayout.dialog;

  final _WhiskeyFormMode mode;
  final _WhiskeyFormLayout layout;
  final String? whiskeyId;
  final Map<String, dynamic> initialData;

  @override
  State<_WhiskeyForm> createState() => _WhiskeyFormState();
}

class _WhiskeyFormState extends State<_WhiskeyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _regionController = TextEditingController();
  final _ageController = TextEditingController(text: 'NAS');
  final _abvController = TextEditingController();
  final _proofController = TextEditingController();
  final _vintageController = TextEditingController();
  final _yearController = TextEditingController();
  final _msrpController = TextEditingController();
  final _priceLowController = TextEditingController();
  final _priceHighController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final PostUploader _uploader = PostUploader();

  late final Future<List<_DistilleryOption>> _distilleryFuture;

  String _selectedCategory = whiskeyCategories.first;
  String _selectedSubCategory = whiskeySubCategories.first;
  String _releaseType = whiskeyReleaseTypes.first;
  String _rarityLevel = whiskeyRarityLevels.first;
  String _availabilityStatus = whiskeyAvailabilityStatuses.first;
  String _countryCode = countryOptions.first.code;
  String? _selectedDistilleryId;
  String? _selectedDistilleryName;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isDeleting = false;
  bool _isHighlighted = false;
  String? _imageUrl;
  @override
  void initState() {
    super.initState();
    _distilleryFuture = _loadDistilleries();
    _abvController.addListener(_handleAbvChanged);
    _applyInitialData();
  }

  @override
  void dispose() {
    _abvController.removeListener(_handleAbvChanged);
    _nameController.dispose();
    _brandController.dispose();
    _regionController.dispose();
    _ageController.dispose();
    _abvController.dispose();
    _proofController.dispose();
    _vintageController.dispose();
    _yearController.dispose();
    _msrpController.dispose();
    _priceLowController.dispose();
    _priceHighController.dispose();
    _shortDescriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _handleAbvChanged() {
    final parsed = double.tryParse(_abvController.text.trim());
    if (parsed == null) {
      _proofController.text = '';
      return;
    }
    _proofController.text = (parsed * 2).toStringAsFixed(1);
  }

  Future<List<_DistilleryOption>> _loadDistilleries() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('distilleries')
        .orderBy('name')
        .limit(100)
        .get();
    return snapshot.docs
        .map((doc) => _DistilleryOption(
              id: doc.id,
              name: (doc.data()['name'] as String? ??
                      'Untitled Producer or Place')
                  .trim(),
            ))
        .toList();
  }

  Future<void> _handleImageUpload() async {
    setState(() {
      _isUploadingImage = true;
    });
    try {
      final url = await _uploader.pickAndUploadImage(
        destinationFolder: 'whiskeys',
        processingOptions: ImageProcessingOptions.whiskeyDefault,
      );
      if (!mounted) return;
      if (url != null) {
        setState(() {
          _imageUrl = url;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
    });
  }

  Future<void> _confirmDelete() async {
    if (widget.mode != _WhiskeyFormMode.edit || widget.whiskeyId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete whiskey?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.leatherDark,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    await _deleteWhiskey();
  }

  Future<void> _deleteWhiskey() async {
    if (_isDeleting || widget.whiskeyId == null) return;
    setState(() => _isDeleting = true);
    try {
      await WhiskeyService().deleteWhiskey(widget.whiskeyId!);
      if (!mounted) return;
      Navigator.of(context).pop(_WhiskeyDialogOutcome.deleted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete whiskey: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _applyInitialData() {
    final data = widget.initialData;
    if (data.isEmpty) return;

    _nameController.text = (data['name'] as String? ?? '').trim();
    _brandController.text = (data['brand'] as String? ?? '').trim();
    _regionController.text = (data['region'] as String? ?? '').trim();
    final age = (data['ageStatement'] as String? ?? 'NAS').trim();
    _ageController.text = age.isEmpty ? 'NAS' : age;
    _abvController.text = _formatNumber(data['abv'] as num?);
    _proofController.text = _formatNumber(data['proof'] as num?);
    _vintageController.text = (data['vintageOrBatch'] as String? ?? '').trim();
    final yearReleased = (data['yearReleased'] as num?)?.toInt();
    _yearController.text = yearReleased?.toString() ?? '';
    _msrpController.text = _formatNumber(data['msrp'] as num?);
    _priceLowController.text = _formatNumber(data['priceLow'] as num?);
    _priceHighController.text = _formatNumber(data['priceHigh'] as num?);
    _shortDescriptionController.text =
        (data['shortDescription'] as String? ?? data['notes'] as String? ?? '')
            .trim();
    final tags = (data['tags'] as List?)?.whereType<String>().toList() ?? [];
    _tagsController.text = tags.join(', ');
    _selectedCategory =
        _coerceOption(whiskeyCategories, data['category'] as String?);
    _selectedSubCategory =
        _coerceOption(whiskeySubCategories, data['subCategory'] as String?);
    _releaseType =
        _coerceOption(whiskeyReleaseTypes, data['releaseType'] as String?);
    _rarityLevel =
        _coerceOption(whiskeyRarityLevels, data['rarityLevel'] as String?);
    _availabilityStatus = _coerceOption(
        whiskeyAvailabilityStatuses, data['availabilityStatus'] as String?);
    _countryCode = _determineCountryCode(data);
    _selectedDistilleryId = data['distilleryId'] as String?;
    final rawDistilleryName = (data['distilleryName'] as String? ?? '').trim();
    _selectedDistilleryName =
        rawDistilleryName.isEmpty ? null : rawDistilleryName;
    _isHighlighted = data['isHighlighted'] as bool? ?? false;
    _imageUrl = data['imageUrl'] as String?;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final abv = double.parse(_abvController.text.trim());
    final msrp = double.parse(_msrpController.text.trim());
    final priceLow = double.parse(_priceLowController.text.trim());
    final priceHigh = double.parse(_priceHighController.text.trim());
    final yearReleased = _yearController.text.trim().isEmpty
        ? null
        : int.tryParse(_yearController.text.trim());
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    setState(() {
      _isSaving = true;
    });
    try {
      final service = WhiskeyService();
      final name = _nameController.text.trim();
      final brand = _brandController.text.trim();
      final distilleryId = _selectedDistilleryId;
      final distilleryName = _selectedDistilleryName;
      final country = _resolveCountryName(_countryCode);
      final countryCode = _countryCode;
      final region = _regionController.text.trim();
      final category = _selectedCategory;
      final subCategory = _selectedSubCategory;
      final ageStatement = _ageController.text.trim();
      final proof = double.tryParse(_proofController.text.trim());
      final releaseType = _releaseType;
      final vintageOrBatch = _vintageController.text.trim().isEmpty
          ? null
          : _vintageController.text.trim();
      final shortDescription = _shortDescriptionController.text.trim();
      final imageUrl = _imageUrl;

      if (widget.mode == _WhiskeyFormMode.add) {
        await service.addWhiskey(
          name: name,
          brand: brand,
          distilleryId: distilleryId,
          distilleryName: distilleryName,
          country: country,
          countryCode: countryCode,
          region: region,
          category: category,
          subCategory: subCategory,
          ageStatement: ageStatement,
          abv: abv,
          proof: proof,
          releaseType: releaseType,
          vintageOrBatch: vintageOrBatch,
          yearReleased: yearReleased,
          msrp: msrp,
          priceLow: priceLow,
          priceHigh: priceHigh,
          rarityLevel: _rarityLevel,
          availabilityStatus: _availabilityStatus,
          shortDescription: shortDescription,
          tags: tags,
          isHighlighted: _isHighlighted,
          imageUrl: imageUrl,
        );
      } else {
        await service.updateWhiskey(
          widget.whiskeyId!,
          name: name,
          brand: brand,
          distilleryId: distilleryId,
          distilleryName: distilleryName,
          country: country,
          countryCode: countryCode,
          region: region,
          category: category,
          subCategory: subCategory,
          ageStatement: ageStatement,
          abv: abv,
          proof: proof,
          releaseType: releaseType,
          vintageOrBatch: vintageOrBatch,
          yearReleased: yearReleased,
          msrp: msrp,
          priceLow: priceLow,
          priceHigh: priceHigh,
          rarityLevel: _rarityLevel,
          availabilityStatus: _availabilityStatus,
          shortDescription: shortDescription,
          tags: tags,
          isHighlighted: _isHighlighted,
          imageUrl: imageUrl,
        );
      }
      if (!mounted) return;
      final result = widget.mode == _WhiskeyFormMode.add
          ? true
          : _WhiskeyDialogOutcome.updated;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save whiskey: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancel() {
    if (_isSaving || _isDeleting) return;
    final result = widget.mode == _WhiskeyFormMode.edit ? null : false;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == _WhiskeyFormMode.add
        ? 'Create a Whiskey Profile'
        : 'Edit Whiskey';
    final submitLabel = widget.mode == _WhiskeyFormMode.add ? 'Add' : 'Update';
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final padding = widget.layout == _WhiskeyFormLayout.sheet
        ? EdgeInsets.only(
            bottom: viewInsets,
            left: 24,
            right: 24,
            top: 24,
          )
        : EdgeInsets.fromLTRB(24, 24, 24, 24 + viewInsets);

    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.darkGreen),
                    ),
                  ),
                  if (widget.mode == _WhiskeyFormMode.edit)
                    IconButton(
                      tooltip: 'Delete whiskey',
                      onPressed:
                          (_isSaving || _isDeleting) ? null : _confirmDelete,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.delete_outline,
                              color: AppColors.leatherDark,
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 16),
              _FormSectionCard(
                title: 'Bottle Basics',
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        const InputDecoration(labelText: 'Whiskey Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  TextFormField(
                    controller: _brandController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Brand'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  _buildDistilleryDropdown(),
                  _buildTwoColumnRow(
                    _buildCountryDropdown(),
                    TextFormField(
                      controller: _regionController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Region'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                  ),
                  _buildTwoColumnRow(
                    _buildDropdown(
                      label: 'Category',
                      value: _selectedCategory,
                      items: whiskeyCategories,
                      onChanged: (value) => setState(
                          () => _selectedCategory = value ?? _selectedCategory),
                    ),
                    _buildDropdown(
                      label: 'Sub-category',
                      value: _selectedSubCategory,
                      items: whiskeySubCategories,
                      onChanged: (value) => setState(() =>
                          _selectedSubCategory = value ?? _selectedSubCategory),
                    ),
                  ),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                        labelText: 'Age Statement or NAS'),
                  ),
                ],
              ),
              _FormSectionCard(
                title: 'Production Details',
                children: [
                  _buildTwoColumnRow(
                    _buildNumberField(
                      label: 'ABV %',
                      controller: _abvController,
                    ),
                    TextFormField(
                      controller: _proofController,
                      readOnly: true,
                      decoration:
                          const InputDecoration(labelText: 'Proof (auto)'),
                    ),
                  ),
                  _buildDropdown(
                    label: 'Release Type',
                    value: _releaseType,
                    items: whiskeyReleaseTypes,
                    onChanged: (value) =>
                        setState(() => _releaseType = value ?? _releaseType),
                  ),
                  _buildTwoColumnRow(
                    TextFormField(
                      controller: _vintageController,
                      decoration: const InputDecoration(
                          labelText: 'Vintage or Batch (optional)'),
                    ),
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Year Released (optional)'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
                    ),
                  ),
                ],
              ),
              _FormSectionCard(
                title: 'Market Data',
                children: [
                  _buildNumberField(
                    label: 'MSRP',
                    controller: _msrpController,
                  ),
                  _buildTwoColumnRow(
                    _buildNumberField(
                      label: 'Typical Low',
                      controller: _priceLowController,
                    ),
                    _buildNumberField(
                      label: 'Typical High',
                      controller: _priceHighController,
                    ),
                  ),
                ],
              ),
              _FormSectionCard(
                title: 'Positioning',
                children: [
                  _buildTwoColumnRow(
                    _buildDropdown(
                      label: 'Rarity Level',
                      value: _rarityLevel,
                      items: whiskeyRarityLevels,
                      onChanged: (value) =>
                          setState(() => _rarityLevel = value ?? _rarityLevel),
                    ),
                    _buildDropdown(
                      label: 'Availability',
                      value: _availabilityStatus,
                      items: whiskeyAvailabilityStatuses,
                      onChanged: (value) => setState(() =>
                          _availabilityStatus = value ?? _availabilityStatus),
                    ),
                  ),
                  TextFormField(
                    controller: _shortDescriptionController,
                    maxLines: 3,
                    maxLength: 150,
                    decoration:
                        const InputDecoration(labelText: 'Short Description'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  TextFormField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                        labelText: 'Tags',
                        helperText: 'Separate tags with commas'),
                  ),
                ],
              ),
              _FormSectionCard(
                title: 'Highlighting',
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isHighlighted,
                    onChanged: (value) =>
                        setState(() => _isHighlighted = value),
                    title: const Text('Highlighted'),
                    subtitle: const Text(
                      'Toggle on to mark this whiskey as highlighted.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(submitLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bottle Image',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: _imageUrl == null || _isUploadingImage
                      ? null
                      : _removeImage,
                  child: const Text('Remove'),
                ),
              ],
            ),
            if (_imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCachedImage(
                  _imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isUploadingImage ? null : _handleImageUpload,
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(_imageUrl == null ? 'Upload image' : 'Replace image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistilleryDropdown() {
    return FutureBuilder<List<_DistilleryOption>>(
      future: _distilleryFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'We could not load your producers and places right now.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const LinearProgressIndicator();
        }
        final options = snapshot.data ?? const <_DistilleryOption>[];
        return DropdownButtonFormField<String?>(
          initialValue: _selectedDistilleryId,
          decoration:
              const InputDecoration(labelText: 'Producer or Place (optional)'),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Independent / No producer or place'),
            ),
            for (final option in options)
              DropdownMenuItem<String?>(
                value: option.id,
                child: Text(option.name),
              ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDistilleryId = value;
              if (value == null) {
                _selectedDistilleryName = null;
              } else {
                final match = options.where((opt) => opt.id == value).toList();
                _selectedDistilleryName =
                    match.isEmpty ? null : match.first.name;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _countryCode,
      decoration: const InputDecoration(labelText: 'Country'),
      isExpanded: true,
      items: [
        for (final option in countryOptions)
          DropdownMenuItem<String>(
            value: option.code,
            child: Text(option.name),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _countryCode = value;
        });
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in items)
          DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(labelText: label),
      validator: _requireNumber,
    );
  }

  Widget _buildTwoColumnRow(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  String _coerceOption(List<String> options, String? value) {
    if (value != null && options.contains(value)) {
      return value;
    }
    return options.first;
  }

  String _determineCountryCode(Map<String, dynamic> data) {
    final incomingCode = data['countryCode'] as String?;
    if (incomingCode != null &&
        countryOptions.any((option) => option.code == incomingCode)) {
      return incomingCode;
    }
    final incomingName = (data['country'] as String? ?? '').toLowerCase();
    final match = countryOptions.firstWhere(
      (option) => option.name.toLowerCase() == incomingName,
      orElse: () => countryOptions.first,
    );
    return match.code;
  }

  String _formatNumber(num? value) {
    if (value == null) return '';
    final doubleValue = value.toDouble();
    if (doubleValue == doubleValue.roundToDouble()) {
      return doubleValue.toStringAsFixed(0);
    }
    return doubleValue.toString();
  }

  String _resolveCountryName(String code) {
    return countryOptions
        .firstWhere(
          (option) => option.code == code,
          orElse: () => countryOptions.first,
        )
        .name;
  }

  String? _requireNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return double.tryParse(value.trim()) == null ? 'Enter a number' : null;
  }
}

class _DistilleryOption {
  const _DistilleryOption({required this.id, required this.name});

  final String id;
  final String name;
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddDistillerySheet extends StatelessWidget {
  const _AddDistillerySheet();

  @override
  Widget build(BuildContext context) {
    return const _ProducerPlaceForm.addSheet();
  }
}

enum _ProducerPlaceFormMode { add, edit }

enum _ProducerPlaceFormLayout { sheet, dialog }

enum _ProducerPlaceDialogOutcome { updated, deleted }

class _ProducerPlaceForm extends StatefulWidget {
  const _ProducerPlaceForm.addSheet()
      : mode = _ProducerPlaceFormMode.add,
        layout = _ProducerPlaceFormLayout.sheet,
        distilleryId = null,
        initialData = const <String, dynamic>{};

  const _ProducerPlaceForm.editDialog({
    required this.distilleryId,
    required this.initialData,
  })  : mode = _ProducerPlaceFormMode.edit,
        layout = _ProducerPlaceFormLayout.dialog;

  final _ProducerPlaceFormMode mode;
  final _ProducerPlaceFormLayout layout;
  final String? distilleryId;
  final Map<String, dynamic> initialData;

  @override
  State<_ProducerPlaceForm> createState() => _ProducerPlaceFormState();
}

class _ProducerPlaceFormState extends State<_ProducerPlaceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _primaryStylesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _websiteController = TextEditingController();
  final PostUploader _uploader = PostUploader();

  String _selectedType = producerPlaceTypes.first;
  String _countryCode = countryOptions.first.code;
  bool _isVisitAble = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _isDeleting = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _applyInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _shortDescriptionController.dispose();
    _primaryStylesController.dispose();
    _tagsController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.layout == _ProducerPlaceFormLayout.sheet
        ? EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          )
        : EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          );
    final title = widget.mode == _ProducerPlaceFormMode.add
        ? 'Add a Producer or Place'
        : 'Edit Producer or Place';

    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.darkGreen),
                    ),
                  ),
                  if (widget.mode == _ProducerPlaceFormMode.edit)
                    IconButton(
                      tooltip: 'Delete producer or place',
                      onPressed:
                          _isDeleting || _isSaving ? null : _confirmDelete,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                title: 'Overview',
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving && !_isDeleting,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Producer or Place Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [
                      for (final type in producerPlaceTypes)
                        DropdownMenuItem(value: type, child: Text(type)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedType = value);
                    },
                  ),
                  _buildImagePicker(),
                ],
              ),
              _FormSectionCard(
                title: 'Story',
                children: [
                  TextFormField(
                    controller: _shortDescriptionController,
                    enabled: !_isSaving && !_isDeleting,
                    maxLines: 3,
                    maxLength: 280,
                    decoration: const InputDecoration(
                      labelText: 'Short Description',
                      helperText: 'Share a brief 1-2 sentence overview.',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  TextFormField(
                    controller: _websiteController,
                    enabled: !_isSaving && !_isDeleting,
                    decoration: const InputDecoration(
                      labelText: 'Website URL',
                      hintText: 'https://example.com',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
              _FormSectionCard(
                title: 'Location',
                children: [
                  _buildTwoColumnRow(
                    _buildCountryDropdown(),
                    TextFormField(
                      controller: _regionController,
                      enabled: !_isSaving && !_isDeleting,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Region'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                  ),
                  _buildTwoColumnRow(
                    TextFormField(
                      controller: _stateController,
                      enabled: !_isSaving && !_isDeleting,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'State / Province'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    TextFormField(
                      controller: _cityController,
                      enabled: !_isSaving && !_isDeleting,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isVisitAble,
                    onChanged: (value) {
                      setState(() => _isVisitAble = value);
                    },
                    title: const Text('Visitors welcome'),
                    subtitle:
                        const Text('Toggle off if this is not a public venue.'),
                  ),
                ],
              ),
              _FormSectionCard(
                title: 'Experience',
                children: [
                  TextFormField(
                    controller: _primaryStylesController,
                    enabled: !_isSaving && !_isDeleting,
                    decoration: const InputDecoration(
                      labelText: 'Primary Whiskey Styles',
                      helperText: 'Separate styles with commas',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  TextFormField(
                    controller: _tagsController,
                    enabled: !_isSaving && !_isDeleting,
                    decoration: const InputDecoration(
                      labelText: 'Tags',
                      helperText: 'Add descriptors separated by commas',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => _handleCancel(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving || _isDeleting ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.mode == _ProducerPlaceFormMode.add
                              ? 'Add'
                              : 'Update'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImageUpload() async {
    setState(() {
      _isUploadingImage = true;
    });
    try {
      final url = await _uploader.pickAndUploadImage(
        destinationFolder: 'distilleries',
        processingOptions: ImageProcessingOptions.producerDefault,
      );
      if (!mounted) return;
      if (url != null) {
        setState(() {
          _imageUrl = url;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final primaryStyles = _parseList(_primaryStylesController.text);
    final tags = _parseList(_tagsController.text);
    final websiteUrl = _websiteController.text.trim();

    setState(() => _isSaving = true);
    try {
      final service = DistilleryService();
      if (widget.mode == _ProducerPlaceFormMode.add) {
        await service.addDistillery(
          name: _nameController.text.trim(),
          type: _selectedType,
          country: _resolveCountryName(_countryCode),
          region: _regionController.text.trim(),
          stateOrProvince: _stateController.text.trim(),
          city: _cityController.text.trim(),
          isVisitAble: _isVisitAble,
          primaryStyles: primaryStyles,
          shortDescription: _shortDescriptionController.text.trim(),
          tags: tags,
          websiteUrl: websiteUrl.isEmpty ? null : websiteUrl,
          imageUrl: _imageUrl,
        );
        if (mounted) Navigator.of(context).pop(true);
      } else {
        await service.updateDistillery(
          widget.distilleryId!,
          name: _nameController.text.trim(),
          type: _selectedType,
          country: _resolveCountryName(_countryCode),
          region: _regionController.text.trim(),
          stateOrProvince: _stateController.text.trim(),
          city: _cityController.text.trim(),
          isVisitAble: _isVisitAble,
          primaryStyles: primaryStyles,
          shortDescription: _shortDescriptionController.text.trim(),
          tags: tags,
          websiteUrl: websiteUrl.isEmpty ? null : websiteUrl,
          imageUrl: _imageUrl,
        );
        if (mounted) {
          Navigator.of(context).pop(_ProducerPlaceDialogOutcome.updated);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final action =
          widget.mode == _ProducerPlaceFormMode.add ? 'add' : 'update';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not $action producer/place: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (widget.mode != _ProducerPlaceFormMode.edit ||
        widget.distilleryId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete producer or place?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.leatherDark,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    await _deleteProducerPlace();
  }

  Future<void> _deleteProducerPlace() async {
    if (widget.distilleryId == null) return;
    setState(() => _isDeleting = true);
    try {
      await DistilleryService().deleteDistillery(widget.distilleryId!);
      if (!mounted) return;
      Navigator.of(context).pop(_ProducerPlaceDialogOutcome.deleted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete producer/place: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _handleCancel(BuildContext context) {
    if (widget.mode == _ProducerPlaceFormMode.add) {
      Navigator.of(context).pop(false);
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildImagePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Primary Photo',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: _imageUrl == null || _isUploadingImage
                      ? null
                      : _removeImage,
                  child: const Text('Remove'),
                ),
              ],
            ),
            if (_imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildCachedImage(
                  _imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isUploadingImage ? null : _handleImageUpload,
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(
                _imageUrl == null ? 'Upload image' : 'Replace image',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _countryCode,
      decoration: const InputDecoration(labelText: 'Country'),
      isExpanded: true,
      items: [
        for (final option in countryOptions)
          DropdownMenuItem<String>(
            value: option.code,
            child: Text(option.name),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _countryCode = value);
      },
    );
  }

  Widget _buildTwoColumnRow(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              first,
              const SizedBox(height: 12),
              second,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  void _applyInitialData() {
    if (widget.mode != _ProducerPlaceFormMode.edit) return;
    final data = widget.initialData;
    _nameController.text = (data['name'] as String? ?? '').trim();
    _regionController.text = (data['region'] as String? ?? '').trim();
    _stateController.text = (data['stateOrProvince'] as String? ?? '').trim();
    _cityController.text = (data['city'] as String? ?? '').trim();
    final summary =
        (data['shortDescription'] as String? ?? data['story'] as String? ?? '')
            .trim();
    _shortDescriptionController.text = summary;
    final styles =
        (data['primaryStyles'] as List?)?.whereType<String>().toList() ?? [];
    _primaryStylesController.text = styles.join(', ');
    final tags = (data['tags'] as List?)?.whereType<String>().toList() ?? [];
    _tagsController.text = tags.join(', ');
    _websiteController.text = (data['websiteUrl'] as String? ?? '').trim();
    _selectedType = _coerceProducerType(data['type'] as String?);
    _countryCode = _determineCountryCode(data);
    _isVisitAble = data['isVisitAble'] as bool? ?? true;
    _imageUrl = data['imageUrl'] as String?;
  }

  List<String> _parseList(String raw) {
    final values = raw.split(',');
    return [
      for (final value in values)
        if (value.trim().isNotEmpty) value.trim(),
    ];
  }

  String _resolveCountryName(String code) {
    return countryOptions
        .firstWhere(
          (option) => option.code == code,
          orElse: () => countryOptions.first,
        )
        .name;
  }

  String _determineCountryCode(Map<String, dynamic> data) {
    final incomingCode = data['countryCode'] as String?;
    if (incomingCode != null &&
        countryOptions.any((option) => option.code == incomingCode)) {
      return incomingCode;
    }
    final incomingName = (data['country'] as String? ?? '').toLowerCase();
    final match = countryOptions.firstWhere(
      (option) => option.name.toLowerCase() == incomingName,
      orElse: () => countryOptions.first,
    );
    return match.code;
  }

  String _coerceProducerType(String? type) {
    if (type != null && producerPlaceTypes.contains(type)) {
      return type;
    }
    return producerPlaceTypes.first;
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
  final _subtitleController = TextEditingController();
  final _tagsController = TextEditingController();
  final _markdownController = TextEditingController();
  final _imageController = TextEditingController();
  final PostUploader _iconUploader = PostUploader();
  String _category = articleCategories.first;
  String? _iconUrl;
  bool _isUploadingIcon = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _tagsController.dispose();
    _markdownController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final subtitleText = _subtitleController.text.trim();
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
      final markdownFilename =
          _stripAssetPrefix(_markdownController.text, 'assets/articles/');
      final imageFilename = _stripAssetPrefix(
        _imageController.text,
        'assets/images/articles/',
      );

      await ArticleService().addArticle(
        title: _titleController.text.trim(),
        subtitle: subtitleText.isEmpty ? null : subtitleText,
        category: _category,
        markdownFilename: markdownFilename,
        tags: tags,
        imageFilename: imageFilename.isEmpty ? null : imageFilename,
        iconUrl: _iconUrl,
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

  String _stripAssetPrefix(String value, String prefix) {
    var sanitized = value.trim().replaceAll('\\', '/');
    final normalizedPrefix = prefix.toLowerCase();
    if (sanitized.toLowerCase().startsWith(normalizedPrefix)) {
      sanitized = sanitized.substring(prefix.length);
    }
    if (sanitized.startsWith('/')) {
      sanitized = sanitized.substring(1);
    }
    return sanitized;
  }

  Future<void> _uploadIcon() async {
    setState(() => _isUploadingIcon = true);
    try {
      final url = await _iconUploader.pickAndUploadImage(
        destinationFolder: 'articles/icons',
        processingOptions:
            const ImageProcessingOptions(maxDimension: 900, jpegQuality: 80),
      );
      if (!mounted) return;
      if (url != null) {
        setState(() => _iconUrl = url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload icon: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingIcon = false);
    }
  }

  void _removeIcon() {
    setState(() => _iconUrl = null);
  }

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
      left: 24,
      right: 24,
      top: 24,
    );

    return Padding(
      padding: padding,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Article',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: AppColors.darkGreen),
              ),
              const SizedBox(height: 16),
              _FormSectionCard(
                title: 'Details',
                children: [
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  TextFormField(
                    controller: _subtitleController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle (optional)',
                    ),
                  ),
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
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _category = value);
                          },
                  ),
                ],
              ),
              _FormSectionCard(
                title: 'Presentation',
                children: [
                  _ArticleIconField(
                    iconUrl: _iconUrl,
                    isUploading: _isUploadingIcon,
                    onUpload:
                        (_isSaving || _isUploadingIcon) ? null : _uploadIcon,
                    onRemove: _isSaving || _isUploadingIcon || _iconUrl == null
                        ? null
                        : _removeIcon,
                  ),
                ],
              ),
              _FormSectionCard(
                title: 'Publishing',
                children: [
                  TextFormField(
                    controller: _tagsController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Tags (optional)',
                      helperText:
                          'Comma-separated list such as education, rye, feature',
                    ),
                  ),
                  TextFormField(
                    controller: _markdownController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Markdown filename',
                      helperText: 'Only the file name, e.g. whiskey-101.md',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  TextFormField(
                    controller: _imageController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Image filename (optional)',
                      helperText:
                          'Files will be read from assets/images/articles/',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                      : const Text('Create Article'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
              Builder(
                builder: (context) {
                  final data = Map<String, dynamic>.from(doc.data());
                  data.putIfAbsent('id', () => doc.id);
                  return _MerchCard.fromData(
                    data: data,
                    authorLabel: 'You',
                    timestamp: _coerceTimestamp(data['createdAt']),
                    showAuthor: false,
                    onDelete: () => _deleteMerch(
                      context,
                      doc.id,
                      data['title'] as String?,
                    ),
                    onTap: () => _editMerch(context, data, doc.id),
                  );
                },
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

  Future<void> _editMerch(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) async {
    final payload = {
      ...data,
      'id': _stringOrNull(data['id']) ?? docId,
    };
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddMerchSheet(initialData: payload),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merchandise item updated.')),
      );
    }
  }
}

class _MerchCard extends StatelessWidget {
  const _MerchCard({
    required this.title,
    required this.category,
    required this.price,
    required this.priceCurrency,
    required this.authorLabel,
    required this.timestamp,
    required this.isActive,
    this.subtitle,
    this.description,
    this.brand,
    this.compareAtPrice,
    this.purchaseLink,
    this.membershipExclusiveTier,
    this.membershipDiscounts,
    this.tags = const [],
    this.variants = const [],
    this.thumbnailUrl,
    this.showAuthor = true,
    this.onDelete,
    this.onTap,
  });

  factory _MerchCard.fromData({
    required Map<String, dynamic> data,
    required String authorLabel,
    required DateTime timestamp,
    bool showAuthor = true,
    VoidCallback? onDelete,
    VoidCallback? onTap,
  }) {
    final priceField = data['price'];
    final priceMap =
        priceField is Map<String, dynamic> ? priceField : <String, dynamic>{};
    final priceValue = (priceField is num)
        ? priceField.toDouble()
        : (priceMap['base'] as num? ?? 0).toDouble();
    final compareAtValue = (priceMap['compareAt'] as num?)?.toDouble();
    final currencyValue = priceField is Map<String, dynamic>
        ? (priceMap['currency'] as String? ?? 'USD').toUpperCase()
        : 'USD';
    final variants = _variantListFromDynamic(data['variants']);
    final membershipDiscounts =
        _doubleMapFromDynamic(data['membershipDiscounts']);
    final purchaseLinkRaw =
        data.containsKey('purchaseLink') ? data['purchaseLink'] : data['link'];
    return _MerchCard(
      title: _stringOrNull(data['title']) ?? 'Untitled Item',
      category: _stringOrNull(data['category']) ?? 'other',
      price: priceValue,
      priceCurrency: currencyValue,
      authorLabel: authorLabel,
      timestamp: timestamp,
      isActive: data['isActive'] as bool? ?? true,
      subtitle: _stringOrNull(data['subtitle']),
      description: _stringOrNull(data['description']),
      brand: _stringOrNull(data['brand']),
      compareAtPrice: compareAtValue,
      purchaseLink: _stringOrNull(purchaseLinkRaw),
      membershipExclusiveTier: _stringOrNull(data['membershipExclusiveTier']),
      membershipDiscounts:
          membershipDiscounts.isEmpty ? null : membershipDiscounts,
      tags: _stringListFromDynamic(data['tags']),
      variants: variants,
      thumbnailUrl: _stringOrNull(data['thumbnailUrl']),
      showAuthor: showAuthor,
      onDelete: onDelete,
      onTap: onTap,
    );
  }

  final String title;
  final String category;
  final double price;
  final String priceCurrency;
  final String authorLabel;
  final DateTime timestamp;
  final bool isActive;
  final String? subtitle;
  final String? description;
  final String? brand;
  final double? compareAtPrice;
  final String? purchaseLink;
  final String? membershipExclusiveTier;
  final Map<String, double>? membershipDiscounts;
  final List<String> tags;
  final List<Map<String, dynamic>> variants;
  final String? thumbnailUrl;
  final bool showAuthor;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final descriptionStyle =
        theme.textTheme.bodyMedium?.copyWith(color: AppColors.leatherDark);
    final priceLine = _buildPriceLine();
    final chips = <Widget>[];
    if (!isActive) {
      chips.add(const Chip(label: Text('Inactive')));
    }
    if (membershipExclusiveTier != null &&
        membershipExclusiveTier!.trim().isNotEmpty) {
      chips.add(
        Chip(
          label: Text(_titleize(membershipExclusiveTier!)),
          backgroundColor: AppColors.neutralLight,
        ),
      );
    }

    final borderRadius = BorderRadius.circular(12);
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildCachedImage(
                        thumbnailUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (thumbnailUrl != null && thumbnailUrl!.trim().isNotEmpty)
                    const SizedBox(width: 12),
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
                        if (subtitle != null && subtitle!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$priceLine | ${_titleize(category)}${brand != null && brand!.trim().isNotEmpty ? ' - ${brand!.trim()}' : ''}',
                            style: descriptionStyle,
                          ),
                        ),
                        if (chips.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: chips,
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
              if (description != null && description!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    description!,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: AppColors.darkGreen),
                  ),
                ),
              if (membershipDiscounts != null &&
                  membershipDiscounts!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final entry in membershipDiscounts!.entries)
                        Chip(
                          label: Text(
                              '${_titleize(entry.key)} ${(entry.value * 100).toStringAsFixed(0)}% off'),
                        ),
                    ],
                  ),
                ),
              if (variants.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Variants (${variants.length})',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 4),
                      for (final variant in variants.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _VariantSummaryRow(variant: variant),
                        ),
                    ],
                  ),
                ),
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final tag in tags)
                        Chip(
                          label: Text(tag),
                          backgroundColor: AppColors.neutralLight,
                        ),
                    ],
                  ),
                ),
              if (purchaseLink != null && purchaseLink!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    purchaseLink!,
                    style: const TextStyle(
                      color: AppColors.leather,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              if (showAuthor)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Shared by $authorLabel on ${timestamp.month}/${timestamp.day}/${timestamp.year}',
                    style: descriptionStyle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildPriceLine() {
    final buffer = StringBuffer()
      ..write(priceCurrency.toUpperCase())
      ..write(' ')
      ..write(price.toStringAsFixed(2));
    if (compareAtPrice != null) {
      buffer
        ..write(' (')
        ..write(compareAtPrice!.toStringAsFixed(2))
        ..write(')');
    }
    return buffer.toString();
  }
}

class _VariantSummaryRow extends StatelessWidget {
  const _VariantSummaryRow({required this.variant});

  final Map<String, dynamic> variant;

  @override
  Widget build(BuildContext context) {
    final name = (variant['name'] as String?)?.trim();
    final variantId = variant['variantId'] as String?;
    final color = (variant['color'] as String?)?.trim();
    final size = (variant['size'] as String?)?.trim();
    final inventory = variant['inventory'] as Map<String, dynamic>?;
    final qty = inventory != null
        ? (inventory['quantityAvailable'] as num? ?? 0).toInt()
        : 0;
    final chips = <String>[];
    if (color != null && color.isNotEmpty) chips.add(color);
    if (size != null && size.isNotEmpty) chips.add(size);
    return Row(
      children: [
        Expanded(
          child: Text(
            name?.isNotEmpty == true ? name! : (variantId ?? 'Variant'),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.darkGreen),
          ),
        ),
        if (chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              chips.join(' | '),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.leatherDark),
            ),
          ),
        Text(
          'Qty $qty',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.leatherDark),
        ),
      ],
    );
  }
}

List<String> _stringListFromDynamic(dynamic value) {
  if (value is Iterable) {
    return value
        .map((element) => element is String ? element : element?.toString())
        .whereType<String>()
        .map((element) => element.trim())
        .where((element) => element.isNotEmpty)
        .toList();
  }
  return <String>[];
}

Map<String, double> _doubleMapFromDynamic(dynamic value) {
  if (value is Map) {
    final result = <String, double>{};
    value.forEach((key, dynamic raw) {
      final mapKey = key?.toString();
      if (mapKey == null) return;
      if (raw is num) {
        result[mapKey] = raw.toDouble();
      } else if (raw is String) {
        final parsed = double.tryParse(raw);
        if (parsed != null) result[mapKey] = parsed;
      }
    });
    return result;
  }
  return <String, double>{};
}

List<Map<String, dynamic>> _variantListFromDynamic(dynamic value) {
  if (value is Iterable) {
    return value
        .whereType<Map<String, dynamic>>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }
  return <Map<String, dynamic>>[];
}

String? _stringOrNull(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

class _AddMerchSheet extends StatefulWidget {
  const _AddMerchSheet({this.initialData});

  final Map<String, dynamic>? initialData;

  @override
  State<_AddMerchSheet> createState() => _AddMerchSheetState();
}

class _AddMerchSheetState extends State<_AddMerchSheet> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _imagesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _purchaseLinkController = TextEditingController();
  final _priceBaseController = TextEditingController();
  final _priceCompareAtController = TextEditingController();
  final _priceCurrencyController = TextEditingController(text: 'USD');
  final _priceTaxCategoryController = TextEditingController();
  late final Map<String, TextEditingController> _membershipDiscountControllers;
  late final List<_VariantFormData> _variants;
  String _category = merchCategories.first;
  String? _membershipExclusiveTier;
  bool _isActive = true;
  bool _isSaving = false;
  bool get _isEditing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    _membershipDiscountControllers = {
      for (final tier in merchandiseMembershipTiers)
        tier: TextEditingController(),
    };
    if (widget.initialData != null) {
      _variants = _buildVariantForms(widget.initialData!);
      _hydrateFromInitialData(widget.initialData!);
    } else {
      _variants = [_VariantFormData()];
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _thumbnailController.dispose();
    _imagesController.dispose();
    _tagsController.dispose();
    _purchaseLinkController.dispose();
    _priceBaseController.dispose();
    _priceCompareAtController.dispose();
    _priceCurrencyController.dispose();
    _priceTaxCategoryController.dispose();
    for (final controller in _membershipDiscountControllers.values) {
      controller.dispose();
    }
    for (final variant in _variants) {
      variant.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one variant.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await MerchandiseService().saveItem(_buildPayload());
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

  Map<String, dynamic> _buildPayload() {
    final membershipDiscounts = <String, double>{};
    _membershipDiscountControllers.forEach((tier, controller) {
      final value = controller.text.trim();
      if (value.isEmpty) return;
      final parsed = double.tryParse(value);
      if (parsed != null) membershipDiscounts[tier] = parsed;
    });

    final payload = <String, dynamic>{
      'id': _effectiveItemId(),
      'title': _titleController.text.trim(),
      'subtitle': _nullable(_subtitleController.text),
      'description': _nullable(_descriptionController.text),
      'category': _category,
      'brand': _nullable(_brandController.text),
      'images': _splitListInput(_imagesController.text),
      'thumbnailUrl': _nullable(_thumbnailController.text),
      'isActive': _isActive,
      'tags': _splitListInput(_tagsController.text),
      'membershipExclusiveTier': _membershipExclusiveTier,
      'membershipDiscounts':
          membershipDiscounts.isEmpty ? null : membershipDiscounts,
      'purchaseLink': _nullable(_purchaseLinkController.text),
      'price': {
        'base': double.parse(_priceBaseController.text.trim()),
        'compareAt': _tryParseDouble(_priceCompareAtController.text),
        'currency': _priceCurrencyController.text.trim().isEmpty
            ? 'USD'
            : _priceCurrencyController.text.trim().toUpperCase(),
        'taxCategory': _nullable(_priceTaxCategoryController.text),
      },
      'variants': _variants.map(_variantToMap).toList(),
    };
    return payload;
  }

  String _effectiveItemId() {
    final entered = _idController.text.trim();
    if (entered.isNotEmpty) return entered;
    final existing = widget.initialData != null
        ? (_stringOrNull(widget.initialData!['id']) ?? '')
        : '';
    return existing;
  }

  void _hydrateFromInitialData(Map<String, dynamic> data) {
    _setControllerText(_idController, _stringOrNull(data['id']));
    _setControllerText(_titleController, _stringOrNull(data['title']));
    _setControllerText(_subtitleController, _stringOrNull(data['subtitle']));
    _setControllerText(
        _descriptionController, _stringOrNull(data['description']));
    _setControllerText(_brandController, _stringOrNull(data['brand']));
    _setControllerText(
        _thumbnailController, _stringOrNull(data['thumbnailUrl']));
    _setControllerText(
      _purchaseLinkController,
      _stringOrNull(data['purchaseLink']) ?? _stringOrNull(data['link']),
    );
    final images = _stringListFromDynamic(data['images']);
    if (images.isNotEmpty) _imagesController.text = images.join('\n');
    final tags = _stringListFromDynamic(data['tags']);
    if (tags.isNotEmpty) _tagsController.text = tags.join('\n');
    final priceField = data['price'];
    final priceMap =
        priceField is Map<String, dynamic> ? priceField : <String, dynamic>{};
    final basePrice = priceField is num
        ? priceField.toDouble()
        : (priceMap['base'] as num?)?.toDouble();
    if (basePrice != null) {
      _priceBaseController.text = basePrice.toString();
    }
    final compareAt = (priceMap['compareAt'] as num?)?.toDouble();
    if (compareAt != null) {
      _priceCompareAtController.text = compareAt.toString();
    }
    final currency = priceField is Map<String, dynamic>
        ? _stringOrNull(priceMap['currency'])
        : null;
    final resolvedCurrency =
        (currency != null && currency.isNotEmpty) ? currency : 'USD';
    _priceCurrencyController.text = resolvedCurrency;
    _setControllerText(
      _priceTaxCategoryController,
      _stringOrNull(priceMap['taxCategory']),
    );
    _category = _categoryFromData(_stringOrNull(data['category']));
    _isActive = data['isActive'] as bool? ?? _isActive;
    final tier = _stringOrNull(data['membershipExclusiveTier']);
    _membershipExclusiveTier = tier?.toLowerCase();
    final membershipDiscounts =
        _doubleMapFromDynamic(data['membershipDiscounts']);
    membershipDiscounts.forEach((tierKey, discount) {
      final controller = _membershipDiscountControllers[tierKey];
      if (controller != null) controller.text = discount.toString();
    });
  }

  List<_VariantFormData> _buildVariantForms(Map<String, dynamic> data) {
    final variants = _variantListFromDynamic(data['variants']);
    if (variants.isEmpty) return [_VariantFormData()];
    return variants.map(_VariantFormData.fromMap).toList();
  }

  String _categoryFromData(String? raw) {
    if (raw == null) return merchCategories.first;
    final normalized = raw.toLowerCase().replaceAll(' ', '_');
    return merchCategories.contains(normalized)
        ? normalized
        : merchCategories.first;
  }

  void _setControllerText(TextEditingController controller, String? value) {
    if (value == null) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    controller.text = trimmed;
  }

  Map<String, dynamic> _variantToMap(_VariantFormData data) {
    return {
      'variantId': data.variantIdController.text.trim(),
      'name': data.nameController.text.trim(),
      'size': _nullable(data.sizeController.text),
      'color': _nullable(data.colorController.text),
      'sku': _nullable(data.skuController.text),
      'barcode': _nullable(data.barcodeController.text),
      'priceOverride': _tryParseDouble(data.priceOverrideController.text),
      'inventory': {
        'quantityAvailable': _tryParseInt(data.quantityController.text) ?? 0,
        'isTracking': data.trackInventory,
        'allowBackorder': data.allowBackorder,
      },
      'weightGrams': _tryParseInt(data.weightController.text),
      'dimensions': _dimensionsFor(data),
      'shippingProfileId': _nullable(data.shippingProfileController.text),
      'isShippable': data.isShippable,
      'isPhysicalProduct': data.isPhysicalProduct,
      'maxPurchaseLimit': _tryParseInt(data.maxPurchaseLimitController.text),
      'relatedProductIds': _splitListInput(data.relatedProductsController.text),
      'rating': {
        'average': _tryParseDouble(data.ratingAverageController.text),
        'count': _tryParseInt(data.ratingCountController.text) ?? 0,
      },
      'searchKeywords': _splitListInput(data.searchKeywordsController.text),
    };
  }

  Map<String, double>? _dimensionsFor(_VariantFormData data) {
    final height = _tryParseDouble(data.heightController.text);
    final width = _tryParseDouble(data.widthController.text);
    final depth = _tryParseDouble(data.depthController.text);
    if (height == null && width == null && depth == null) return null;
    return {
      if (height != null) 'height': height,
      if (width != null) 'width': width,
      if (depth != null) 'depth': depth,
    };
  }

  List<String> _splitListInput(String value) {
    return value
        .split(RegExp(r'[\n,]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  double? _tryParseDouble(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  int? _tryParseInt(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  String? _nullable(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Merchandise' : 'Add Merchandise',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.darkGreen),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  'Basics',
                  [
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Merchandise ID',
                        helperText: 'Leave blank to auto-generate',
                      ),
                    ),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(labelText: 'Subtitle'),
                    ),
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(labelText: 'Brand'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final category in merchCategories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(_titleize(category)),
                          )
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _category = value);
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                  ],
                ),
                _buildSection(
                  context,
                  'Media & Tags',
                  [
                    TextFormField(
                      controller: _thumbnailController,
                      decoration:
                          const InputDecoration(labelText: 'Thumbnail URL'),
                    ),
                    TextFormField(
                      controller: _imagesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Image URLs',
                        helperText: 'Comma or newline separated URLs',
                      ),
                    ),
                    TextFormField(
                      controller: _tagsController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        helperText: 'Comma or newline separated tags',
                      ),
                    ),
                    TextFormField(
                      controller: _purchaseLinkController,
                      decoration:
                          const InputDecoration(labelText: 'Purchase Link'),
                    ),
                  ],
                ),
                _buildSection(
                  context,
                  'Status & Membership',
                  [
                    SwitchListTile.adaptive(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      subtitle: const Text('Inactive items stay hidden'),
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: _membershipExclusiveTier,
                      decoration: const InputDecoration(
                        labelText: 'Membership Exclusive Tier',
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('None')),
                        for (final tier in merchandiseMembershipTiers)
                          DropdownMenuItem(
                            value: tier,
                            child: Text(_titleize(tier)),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _membershipExclusiveTier = value),
                    ),
                    for (final tier in merchandiseMembershipTiers)
                      TextFormField(
                        controller: _membershipDiscountControllers[tier]!,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: '${_titleize(tier)} Discount',
                          helperText: 'Decimal value (0.15 for 15%)',
                        ),
                      ),
                  ],
                ),
                _buildSection(
                  context,
                  'Pricing',
                  [
                    TextFormField(
                      controller: _priceBaseController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Base Price'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return double.tryParse(value.trim()) == null
                            ? 'Enter a valid number'
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: _priceCompareAtController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Compare At Price'),
                    ),
                    TextFormField(
                      controller: _priceCurrencyController,
                      decoration: const InputDecoration(labelText: 'Currency'),
                    ),
                    TextFormField(
                      controller: _priceTaxCategoryController,
                      decoration:
                          const InputDecoration(labelText: 'Tax Category'),
                    ),
                  ],
                ),
                _buildVariantsSection(context),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isEditing ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.darkGreen),
            ),
            const SizedBox(height: 12),
            ..._withSpacing(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> children) {
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i != children.length - 1) {
        spaced.add(const SizedBox(height: 12));
      }
    }
    return spaced;
  }

  Widget _buildVariantsSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Variants (${_variants.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.darkGreen),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _variants.add(_VariantFormData()));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Variant'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _variants.length; i++)
              _buildVariantCard(context, i),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantCard(BuildContext context, int index) {
    final variant = _variants[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.neutralLight.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Variant ${index + 1}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.darkGreen),
                ),
                if (_variants.length > 1)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        final removed = _variants.removeAt(index);
                        removed.dispose();
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: variant.variantIdController,
              decoration: const InputDecoration(labelText: 'Variant ID'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: variant.nameController,
              decoration: const InputDecoration(labelText: 'Variant Name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: variant.sizeController,
                    decoration: const InputDecoration(labelText: 'Size'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: variant.colorController,
                    decoration: const InputDecoration(labelText: 'Color'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: variant.skuController,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: variant.barcodeController,
                    decoration: const InputDecoration(labelText: 'Barcode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: variant.priceOverrideController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Price Override (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: variant.quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity Available',
              ),
            ),
            SwitchListTile.adaptive(
              value: variant.trackInventory,
              onChanged: (value) =>
                  setState(() => variant.trackInventory = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Track Inventory'),
            ),
            SwitchListTile.adaptive(
              value: variant.allowBackorder,
              onChanged: (value) =>
                  setState(() => variant.allowBackorder = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow Backorder'),
            ),
            SwitchListTile.adaptive(
              value: variant.isShippable,
              onChanged: (value) => setState(() => variant.isShippable = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Is Shippable'),
            ),
            SwitchListTile.adaptive(
              value: variant.isPhysicalProduct,
              onChanged: (value) =>
                  setState(() => variant.isPhysicalProduct = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Physical Product'),
            ),
            TextFormField(
              controller: variant.weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (grams)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: variant.heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: variant.widthController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Width (cm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: variant.depthController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Depth (cm)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: variant.shippingProfileController,
              decoration:
                  const InputDecoration(labelText: 'Shipping Profile ID'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: variant.maxPurchaseLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Purchase Limit',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: variant.relatedProductsController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Related Product IDs',
                helperText: 'Comma or newline separated IDs',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: variant.ratingAverageController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Rating Average',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: variant.ratingCountController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Rating Count'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: variant.searchKeywordsController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Search Keywords',
                helperText: 'Comma or newline separated keywords',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantFormData {
  _VariantFormData()
      : variantIdController = TextEditingController(),
        nameController = TextEditingController(),
        sizeController = TextEditingController(),
        colorController = TextEditingController(),
        skuController = TextEditingController(),
        barcodeController = TextEditingController(),
        priceOverrideController = TextEditingController(),
        quantityController = TextEditingController(text: '0'),
        weightController = TextEditingController(),
        heightController = TextEditingController(),
        widthController = TextEditingController(),
        depthController = TextEditingController(),
        shippingProfileController = TextEditingController(),
        maxPurchaseLimitController = TextEditingController(),
        relatedProductsController = TextEditingController(),
        ratingAverageController = TextEditingController(),
        ratingCountController = TextEditingController(text: '0'),
        searchKeywordsController = TextEditingController();

  factory _VariantFormData.fromMap(Map<String, dynamic> data) {
    final form = _VariantFormData();
    form.variantIdController.text =
        _stringOrNull(data['variantId']) ?? form.variantIdController.text;
    form.nameController.text =
        _stringOrNull(data['name']) ?? form.nameController.text;
    form.sizeController.text =
        _stringOrNull(data['size']) ?? form.sizeController.text;
    form.colorController.text =
        _stringOrNull(data['color']) ?? form.colorController.text;
    form.skuController.text =
        _stringOrNull(data['sku']) ?? form.skuController.text;
    form.barcodeController.text =
        _stringOrNull(data['barcode']) ?? form.barcodeController.text;
    final priceOverride = (data['priceOverride'] as num?)?.toDouble();
    if (priceOverride != null) {
      form.priceOverrideController.text = priceOverride.toString();
    }
    final inventory =
        data['inventory'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final qty = (inventory['quantityAvailable'] as num?)?.toInt();
    if (qty != null) {
      form.quantityController.text = qty.toString();
    }
    form.trackInventory =
        inventory['isTracking'] as bool? ?? form.trackInventory;
    form.allowBackorder =
        inventory['allowBackorder'] as bool? ?? form.allowBackorder;
    form.isShippable = data['isShippable'] as bool? ?? form.isShippable;
    form.isPhysicalProduct =
        data['isPhysicalProduct'] as bool? ?? form.isPhysicalProduct;
    final weight = (data['weightGrams'] as num?)?.toInt();
    if (weight != null) {
      form.weightController.text = weight.toString();
    }
    final dimensions =
        data['dimensions'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final height = (dimensions['height'] as num?)?.toDouble();
    final width = (dimensions['width'] as num?)?.toDouble();
    final depth = (dimensions['depth'] as num?)?.toDouble();
    if (height != null) form.heightController.text = height.toString();
    if (width != null) form.widthController.text = width.toString();
    if (depth != null) form.depthController.text = depth.toString();
    form.shippingProfileController.text =
        _stringOrNull(data['shippingProfileId']) ??
            form.shippingProfileController.text;
    final maxPurchase = (data['maxPurchaseLimit'] as num?)?.toInt();
    if (maxPurchase != null) {
      form.maxPurchaseLimitController.text = maxPurchase.toString();
    }
    final relatedProducts = _stringListFromDynamic(data['relatedProductIds']);
    if (relatedProducts.isNotEmpty) {
      form.relatedProductsController.text = relatedProducts.join('\n');
    }
    final rating =
        data['rating'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final average = (rating['average'] as num?)?.toDouble();
    if (average != null) {
      form.ratingAverageController.text = average.toString();
    }
    final count = (rating['count'] as num?)?.toInt();
    if (count != null) {
      form.ratingCountController.text = count.toString();
    }
    final keywords = _stringListFromDynamic(data['searchKeywords']);
    if (keywords.isNotEmpty) {
      form.searchKeywordsController.text = keywords.join('\n');
    }
    return form;
  }

  final TextEditingController variantIdController;
  final TextEditingController nameController;
  final TextEditingController sizeController;
  final TextEditingController colorController;
  final TextEditingController skuController;
  final TextEditingController barcodeController;
  final TextEditingController priceOverrideController;
  final TextEditingController quantityController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController widthController;
  final TextEditingController depthController;
  final TextEditingController shippingProfileController;
  final TextEditingController maxPurchaseLimitController;
  final TextEditingController relatedProductsController;
  final TextEditingController ratingAverageController;
  final TextEditingController ratingCountController;
  final TextEditingController searchKeywordsController;

  bool trackInventory = true;
  bool allowBackorder = false;
  bool isShippable = true;
  bool isPhysicalProduct = true;

  void dispose() {
    variantIdController.dispose();
    nameController.dispose();
    sizeController.dispose();
    colorController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    priceOverrideController.dispose();
    quantityController.dispose();
    weightController.dispose();
    heightController.dispose();
    widthController.dispose();
    depthController.dispose();
    shippingProfileController.dispose();
    maxPurchaseLimitController.dispose();
    relatedProductsController.dispose();
    ratingAverageController.dispose();
    ratingCountController.dispose();
    searchKeywordsController.dispose();
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

Widget _buildCachedImage(
  String imageUrl, {
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
}) {
  return CachedNetworkImage(
    imageUrl: imageUrl,
    height: height,
    width: width,
    fit: fit,
    placeholder: (context, _) => SizedBox(
      height: height,
      width: width,
      child: const Center(child: CircularProgressIndicator()),
    ),
    errorWidget: (_, __, ___) => Container(
      height: height,
      width: width,
      color: AppColors.neutralLight,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined),
    ),
  );
}
