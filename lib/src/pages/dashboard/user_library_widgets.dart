part of 'package:the_whiskey_manuscript_app/main.dart';

const double _kLibraryPreviewSize = 64;

class _SavedWhiskeyImagePreview extends StatelessWidget {
  const _SavedWhiskeyImagePreview({
    this.imageUrl,
    this.whiskeyId,
  });

  final String? imageUrl;
  final String? whiskeyId;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _LibraryImageFrame(
        size: _kLibraryPreviewSize,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _libraryPlaceholderIcon(Icons.local_drink_rounded),
        ),
      );
    }
    if (whiskeyId == null || whiskeyId!.isEmpty) {
      return _LibraryImageFrame(
        size: _kLibraryPreviewSize,
        child: _libraryPlaceholderIcon(Icons.local_drink_rounded),
      );
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('whiskeys')
          .doc(whiskeyId)
          .get(),
      builder: (context, snapshot) {
        final url = (snapshot.data?.data()?['imageUrl'] as String?)?.trim();
        if (url != null && url.isNotEmpty) {
          return _LibraryImageFrame(
            size: _kLibraryPreviewSize,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _libraryPlaceholderIcon(Icons.local_drink_rounded),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasError) {
          return _LibraryImageFrame(
            size: _kLibraryPreviewSize,
            child: const _LibraryImageLoadingIndicator(),
          );
        }
        return _LibraryImageFrame(
          size: _kLibraryPreviewSize,
          child: _libraryPlaceholderIcon(Icons.local_drink_rounded),
        );
      },
    );
  }
}

class _SavedWhiskeyListPage extends StatelessWidget {
  const _SavedWhiskeyListPage({
    required this.userId,
    required this.collectionName,
    required this.title,
    required this.emptyMessage,
  });

  final String userId;
  final String collectionName;
  final String title;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .orderBy('addedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _FeedMessage(
              message: 'We could not load your saved bottles.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _FeedMessage(message: emptyMessage);
          }

          final textTheme = Theme.of(context).textTheme;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final rawName = (data['name'] as String? ?? '').trim();
              final name = rawName.isEmpty ? 'Whiskey' : rawName;
              final subtitle = _savedWhiskeySubtitle(data);
              final addedAt =
                  _formatEventDate(_coerceTimestamp(data['addedAt']));
              final imageUrl = (data['imageUrl'] as String?)?.trim();
              final whiskeyId = (data['whiskeyId'] as String?)?.trim();
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openWhiskeyDetail(
                    context,
                    whiskeyId: whiskeyId,
                    fallbackData: data,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SavedWhiskeyImagePreview(
                          imageUrl: imageUrl,
                          whiskeyId: whiskeyId,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: textTheme.titleMedium
                                    ?.copyWith(color: AppColors.darkGreen),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.leatherDark,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                'Added $addedAt',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.leatherDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: AppColors.leatherDark,
                          onPressed: () => _removeSavedWhiskeyEntry(
                            context,
                            doc,
                            collectionName,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openWhiskeyDetail(
    BuildContext context, {
    required String? whiskeyId,
    required Map<String, dynamic> fallbackData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WhiskeyDetailPage(
          whiskeyId: whiskeyId,
          fallbackData: fallbackData,
        ),
      ),
    );
  }
}

String? _savedWhiskeySubtitle(Map<String, dynamic> data) {
  final style = (data['style'] as String? ?? '').trim();
  final region = (data['region'] as String? ?? '').trim();
  final parts = [style, region].where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' - ');
}

Future<void> _removeSavedWhiskeyEntry(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
  String collectionName,
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

class _FavoriteDistilleriesPage extends StatelessWidget {
  const _FavoriteDistilleriesPage({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoriteDistilleries')
        .orderBy('addedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Producers & Places')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _FeedMessage(
              message: 'We could not load favorite producers and places.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _FeedMessage(
              message:
                  'Your Producers and Places list is blank.\nVisit the Content tab and mark your first favorite.',
            );
          }

          final textTheme = Theme.of(context).textTheme;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name =
                  (data['name'] as String? ?? 'Producer or Place').trim();
              final subtitle = _buildFavoriteDistillerySubtitle(data);
              final addedAt =
                  _formatEventDate(_coerceTimestamp(data['addedAt']));
              final imageUrl = (data['imageUrl'] as String?)?.trim();
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openDistilleryDetail(
                    context,
                    distilleryId: doc.id,
                    fallbackData: data,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FavoriteDistilleryImagePreview(
                          distilleryId: doc.id,
                          imageUrl: imageUrl,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'Producer or Place' : name,
                                style: textTheme.titleMedium
                                    ?.copyWith(color: AppColors.darkGreen),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.leatherDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Added $addedAt',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.leatherDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openDistilleryDetail(
    BuildContext context, {
    required String distilleryId,
    required Map<String, dynamic> fallbackData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FavoriteDistilleryDetailPage(
          distilleryId: distilleryId,
          fallbackData: fallbackData,
        ),
      ),
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

class _FavoriteArticlesPage extends StatelessWidget {
  const _FavoriteArticlesPage({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favoriteArticles')
        .orderBy('addedAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Articles')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _FeedMessage(
              message: 'We could not load favorite articles.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _FeedMessage(
              message:
                  'Your Article Library is empty.\nFind something in Content and add it here.',
            );
          }

          final textTheme = Theme.of(context).textTheme;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final rawTitle = (data['title'] as String? ?? '').trim();
              final title = rawTitle.isEmpty ? 'Article' : rawTitle;
              final subtitle = _buildFavoriteArticleSubtitle(data);
              final addedAt =
                  _formatEventDate(_coerceTimestamp(data['addedAt']));
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openArticleDetail(
                    context,
                    articleId: doc.id,
                    fallbackTitle: title,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FavoriteArticleImagePreview(articleId: doc.id),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: textTheme.titleMedium
                                    ?.copyWith(color: AppColors.darkGreen),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.leatherDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Saved $addedAt',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.leatherDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openArticleDetail(
    BuildContext context, {
    required String articleId,
    required String fallbackTitle,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FavoriteArticleDetailLoader(
          articleId: articleId,
          fallbackTitle: fallbackTitle,
        ),
      ),
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

class _WhiskeyDetailPage extends StatelessWidget {
  const _WhiskeyDetailPage({
    required this.fallbackData,
    this.whiskeyId,
  });

  final Map<String, dynamic> fallbackData;
  final String? whiskeyId;

  @override
  Widget build(BuildContext context) {
    final trimmedId = whiskeyId?.trim();
    if (trimmedId == null || trimmedId.isEmpty) {
      return _WhiskeyDetailScaffold(data: fallbackData);
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('whiskeys')
          .doc(trimmedId)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final combined = {
          ...fallbackData,
          if (data != null) ...data,
        };
        if (snapshot.hasError && data == null) {
          return _WhiskeyDetailScaffold(
            data: combined,
            errorMessage: 'We could not load the latest details.',
          );
        }
        return _WhiskeyDetailScaffold(
          data: combined,
          isLoading: snapshot.connectionState == ConnectionState.waiting &&
              data == null,
        );
      },
    );
  }
}

class _WhiskeyDetailScaffold extends StatelessWidget {
  const _WhiskeyDetailScaffold({
    required this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  final Map<String, dynamic> data;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final title = ((data['name'] as String?) ?? 'Whiskey').trim();
    final imageUrl = (data['imageUrl'] as String?)?.trim();
    final description = ((data['shortDescription'] as String?) ??
            (data['notes'] as String?) ??
            '')
        .trim();
    final tags = _coerceStringList(data['tags']);
    final infoEntries = _buildWhiskeyEntries(data);

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'Whiskey' : title),
      ),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: AppColors.neutralLight,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported,
                              color: AppColors.leatherDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.leather.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: AppColors.leatherDark),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: AppColors.leatherDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (infoEntries.isNotEmpty) ...[
                    for (final entry in infoEntries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child:
                            _DetailRow(label: entry.label, value: entry.value),
                      ),
                    const SizedBox(height: 8),
                  ],
                  if (tags.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags)
                          Chip(
                            label: Text(tag),
                            backgroundColor: AppColors.neutralLight,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_DetailEntry> _buildWhiskeyEntries(Map<String, dynamic> data) {
    final entries = <_DetailEntry>[];
    void addText(String label, String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      entries.add(_DetailEntry(label, trimmed));
    }

    String? formatNumber(num? value, {String suffix = ''}) {
      if (value == null) return null;
      final asDouble = value.toDouble();
      final decimals = asDouble == asDouble.roundToDouble() ? 0 : 1;
      return '${asDouble.toStringAsFixed(decimals)}$suffix';
    }

    addText('Brand', data['brand'] as String?);
    addText('Category',
        (data['category'] as String? ?? data['style'] as String?) ?? '');
    addText('Subcategory', data['subCategory'] as String?);
    addText(
        'Region', (data['region'] as String?) ?? data['country'] as String?);
    addText('Distillery', data['distilleryName'] as String?);
    addText('Release Type', data['releaseType'] as String?);
    addText('Age Statement', data['ageStatement'] as String?);
    addText(
        'Rarity', data['rarityLevel'] as String? ?? data['rarity'] as String?);
    addText(
        'Availability',
        data['availabilityStatus'] as String? ??
            data['availability'] as String?);
    addText('Membership Tier', data['membershipLevel'] as String?);

    final abvText = formatNumber(data['abv'] as num?, suffix: '% ABV');
    addText('ABV', abvText);
    final proofText = formatNumber(data['proof'] as num?);
    addText('Proof', proofText);

    final msrp = (data['msrp'] as num?)?.toDouble();
    if (msrp != null) {
      addText('MSRP', _formatCurrencyValue(msrp));
    }
    final priceLow = (data['priceLow'] as num?)?.toDouble();
    final priceHigh = (data['priceHigh'] as num?)?.toDouble();
    if (priceLow != null && priceHigh != null) {
      addText('Typical Price',
          '${_formatCurrencyValue(priceLow)} - ${_formatCurrencyValue(priceHigh)}');
    }

    return entries;
  }
}

class _FavoriteDistilleryDetailPage extends StatelessWidget {
  const _FavoriteDistilleryDetailPage({
    required this.distilleryId,
    required this.fallbackData,
  });

  final String distilleryId;
  final Map<String, dynamic> fallbackData;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('distilleries')
          .doc(distilleryId)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final combined = {
          ...fallbackData,
          if (data != null) ...data,
        };
        if (snapshot.hasError && data == null) {
          return _DistilleryDetailScaffold(
            data: combined,
            errorMessage: 'We could not load this producer right now.',
          );
        }
        return _DistilleryDetailScaffold(
          data: combined,
          isLoading: snapshot.connectionState == ConnectionState.waiting &&
              data == null,
        );
      },
    );
  }
}

class _DistilleryDetailScaffold extends StatelessWidget {
  const _DistilleryDetailScaffold({
    required this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  final Map<String, dynamic> data;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final name = ((data['name'] as String?) ?? 'Producer or Place').trim();
    final imageUrl = (data['imageUrl'] as String?)?.trim();
    final description = ((data['shortDescription'] as String?) ??
            (data['story'] as String?) ??
            '')
        .trim();
    final location = (data['location'] as String? ?? '').trim();
    final styles = _coerceStringList(data['primaryStyles']);
    final tags = _coerceStringList(data['tags']);
    final signaturePour = (data['signaturePour'] as String?)?.trim();
    final visitAble = data['isVisitAble'] as bool?;
    final website = (data['websiteUrl'] as String?)?.trim();

    final infoEntries = <_DetailEntry>[];
    void addEntry(String label, String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      infoEntries.add(_DetailEntry(label, trimmed));
    }

    addEntry('Type', data['type'] as String?);
    addEntry('Location', location.isEmpty ? null : location);
    addEntry('Signature Pour', signaturePour);
    addEntry('Membership Tier', data['membershipLevel'] as String?);
    if (visitAble != null) {
      addEntry('Visitor Friendly', visitAble ? 'Yes' : 'Not yet');
    }
    if (website != null && website.isNotEmpty) {
      addEntry('Website', website);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name.isEmpty ? 'Producer or Place' : name),
      ),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: AppColors.neutralLight,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported,
                              color: AppColors.leatherDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.leather.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: AppColors.leatherDark),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (description.isNotEmpty) ...[
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: AppColors.leatherDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (styles.isNotEmpty) ...[
                    const Text(
                      'Primary Styles',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final style in styles)
                          Chip(
                            label: Text(style),
                            backgroundColor: AppColors.neutralLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (infoEntries.isNotEmpty) ...[
                    for (final entry in infoEntries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child:
                            _DetailRow(label: entry.label, value: entry.value),
                      ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags)
                          Chip(
                            label: Text(tag),
                            backgroundColor: AppColors.neutralLight,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteArticleDetailLoader extends StatelessWidget {
  const _FavoriteArticleDetailLoader({
    required this.articleId,
    required this.fallbackTitle,
  });

  final String articleId;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('articles')
          .doc(articleId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(fallbackTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(fallbackTitle)),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('We could not load this article.'),
              ),
            ),
          );
        }
        final data = snapshot.data?.data();
        final markdown = (data?['markdownFilename'] as String?)?.trim();
        final title = (data?['title'] as String? ?? fallbackTitle).trim();
        if (markdown == null || markdown.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(title.isEmpty ? fallbackTitle : title)),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('This article is currently unavailable.'),
              ),
            ),
          );
        }
        return ArticleDetailPage(
          title: title.isEmpty ? fallbackTitle : title,
          markdownFileName: markdown,
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.darkGreen,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.leatherDark),
          ),
        ),
      ],
    );
  }
}

class _DetailEntry {
  const _DetailEntry(this.label, this.value);

  final String label;
  final String value;
}

class _FavoriteDistilleryImagePreview extends StatelessWidget {
  const _FavoriteDistilleryImagePreview({
    required this.distilleryId,
    this.imageUrl,
  });

  final String distilleryId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _LibraryImageFrame(
        size: _kLibraryPreviewSize,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _libraryPlaceholderIcon(Icons.map_rounded),
        ),
      );
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('distilleries')
          .doc(distilleryId)
          .get(),
      builder: (context, snapshot) {
        final url = (snapshot.data?.data()?['imageUrl'] as String?)?.trim();
        if (url != null && url.isNotEmpty) {
          return _LibraryImageFrame(
            size: _kLibraryPreviewSize,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _libraryPlaceholderIcon(Icons.map_rounded),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasError) {
          return _LibraryImageFrame(
            size: _kLibraryPreviewSize,
            child: const _LibraryImageLoadingIndicator(),
          );
        }
        return _LibraryImageFrame(
          size: _kLibraryPreviewSize,
          child: _libraryPlaceholderIcon(Icons.map_rounded),
        );
      },
    );
  }
}

class _FavoriteArticleImagePreview extends StatelessWidget {
  const _FavoriteArticleImagePreview({
    required this.articleId,
  });

  final String articleId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('articles')
          .doc(articleId)
          .get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final iconUrl = (data?['iconUrl'] as String?)?.trim();
        final imageUrl = (data?['imageUrl'] as String?)?.trim();
        final imagePath = (data?['imagePath'] as String?)?.trim();
        if (iconUrl != null && iconUrl.isNotEmpty) {
          return _LibraryImageFrame(
            size: _kLibraryPreviewSize,
            child: Image.network(
              iconUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _libraryPlaceholderIcon(Icons.article_rounded),
            ),
          );
        }
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return _LibraryImageFrame(
            size: _kLibraryPreviewSize,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _libraryPlaceholderIcon(Icons.article_rounded),
            ),
          );
        }
        if (imagePath != null && imagePath.isNotEmpty) {
          return _LibraryImageFrame(
            size: _kLibraryPreviewSize,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _libraryPlaceholderIcon(Icons.article_rounded),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasError) {
          return _LibraryImageFrame(
            size: _kLibraryPreviewSize,
            child: const _LibraryImageLoadingIndicator(),
          );
        }
        return _LibraryImageFrame(
          size: _kLibraryPreviewSize,
          child: _libraryPlaceholderIcon(Icons.article_rounded),
        );
      },
    );
  }
}

class _LibraryImageFrame extends StatelessWidget {
  const _LibraryImageFrame({required this.child, this.size = 64});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: AppColors.neutralLight,
        child: child,
      ),
    );
  }
}

class _LibraryImageLoadingIndicator extends StatelessWidget {
  const _LibraryImageLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

Widget _libraryPlaceholderIcon(IconData icon) {
  return Center(
    child: Icon(
      icon,
      color: AppColors.leatherDark,
      size: 28,
    ),
  );
}

List<String> _coerceStringList(dynamic raw) {
  if (raw is Iterable) {
    return raw
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }
  return const [];
}

String _formatCurrencyValue(double value) {
  final decimals = value == value.roundToDouble() ? 0 : 2;
  return '\$${value.toStringAsFixed(decimals)}';
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
