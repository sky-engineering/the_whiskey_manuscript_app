part of 'package:the_whiskey_manuscript_app/main.dart';

class LibraryDatabasePage extends StatefulWidget {
  const LibraryDatabasePage({super.key, this.initialTab = 0})
      : assert(initialTab >= 0 && initialTab < 3);

  final int initialTab;

  @override
  State<LibraryDatabasePage> createState() => _LibraryDatabasePageState();
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

typedef MerchandiseItemTapCallback = Future<void> Function(
  BuildContext context,
  Map<String, dynamic> data,
  String documentId,
);

class _MerchandiseFeed extends StatelessWidget {
  const _MerchandiseFeed({this.onItemTap});

  final MerchandiseItemTapCallback? onItemTap;

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
              Builder(
                builder: (context) {
                  final data = Map<String, dynamic>.from(doc.data());
                  data.putIfAbsent('id', () => doc.id);
                  return _MerchCard.fromData(
                    data: data,
                    authorLabel: data['userName'] as String? ?? 'Curator',
                    timestamp: _coerceTimestamp(data['createdAt']),
                    onTap: onItemTap == null
                        ? null
                        : () => onItemTap!(context, data, doc.id),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _LibraryDatabasePageState extends State<LibraryDatabasePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next != _query) setState(() => _query = next);
    });
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The TWM Database'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search bottles, distilleries, or essays...',
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: AppColors.darkGreen,
            unselectedLabelColor: AppColors.darkGreen.withOpacity(0.35),
            indicator: const BoxDecoration(),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Whiskeys'),
              Tab(text: 'Producers and Places'),
              Tab(text: 'Articles'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DatabaseWhiskeyList(
                  query: _query,
                  membership: 'All',
                  enableEditing: false,
                ),
                _DatabaseDistilleryList(
                  query: _query,
                  membership: 'All',
                  enableEditing: false,
                ),
                _DatabaseArticleList(
                  query: _query,
                  membership: 'All',
                  enableEditing: false,
                ),
              ],
            ),
          ),
        ],
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
            Expanded(
              child: _DatabaseWhiskeyList(
                query: _query,
                membership: 'All',
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
  final String _membershipFilter = 'All';

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
        title: const Text('TWM Producers and Places Database'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddDistillery,
        icon: const Icon(Icons.factory_rounded),
        label: const Text('Add Producer or Place'),
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
                hintText: 'Search producers and places by name or location...',
              ),
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
  const _DatabaseWhiskeyList({
    required this.query,
    required this.membership,
    this.enableEditing = true,
  });

  final String query;
  final String membership;
  final bool enableEditing;

  bool _matches(Map<String, dynamic> data) {
    final q = query.toLowerCase();
    final description =
        (data['shortDescription'] as String? ?? data['notes'] as String? ?? '')
            .toLowerCase();
    final tagBlob = (data['tags'] as List?)?.join(' ') ?? '';
    final target =
        '${data['name'] ?? ''} ${data['brand'] ?? ''} ${data['category'] ?? data['style'] ?? ''} ${data['subCategory'] ?? ''} ${data['region'] ?? ''} ${data['userName'] ?? ''} $description $tagBlob'
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
      itemBuilder: (context, doc) {
        final data = doc.data();
        return _DatabaseWhiskeyCard(
          name: (data['name'] as String? ?? 'Untitled Bottle').trim(),
          brand: (data['brand'] as String? ?? '').trim(),
          category: (data['category'] as String? ??
                  data['style'] as String? ??
                  'Special Release')
              .trim(),
          subCategory: (data['subCategory'] as String? ?? '').trim(),
          imageUrl: data['imageUrl'] as String?,
          onTap: () => enableEditing
              ? _openEditDialog(context, doc)
              : _openDetailSheet(context, data),
        );
      },
      filter: _matches,
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final result = await showDialog<_WhiskeyDialogOutcome>(
      context: context,
      builder: (_) => _EditWhiskeyDialog(
        whiskeyId: doc.id,
        data: doc.data(),
      ),
    );
    if (!context.mounted || result == null) return;
    final message = result == _WhiskeyDialogOutcome.deleted
        ? 'Whiskey deleted.'
        : 'Whiskey updated.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openDetailSheet(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final detailData = _featuredWhiskeyDataFromMap(data);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WhiskeyDetailSheet(data: detailData),
    );
  }
}

class _FeaturedWhiskeyCard extends StatelessWidget {
  const _FeaturedWhiskeyCard({required this.data, this.onTap});

  final _FeaturedWhiskeyData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 150,
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutralMid),
        color: AppColors.lightNeutral,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
              child: Stack(
                children: [
                  Positioned.fill(child: _buildImage()),
                  if (data.actions.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton<_ShowcaseAction>(
                        tooltip: 'Add to library',
                        icon: const Icon(
                          Icons.add_circle_rounded,
                          color: AppColors.leather,
                          size: 36,
                        ),
                        color: Colors.white,
                        onSelected: (action) => action.onSelected(context),
                        itemBuilder: (context) => [
                          for (final action in data.actions)
                            PopupMenuItem<_ShowcaseAction>(
                              value: action,
                              child: Row(
                                children: [
                                  if (action.icon != null) ...[
                                    Icon(action.icon,
                                        size: 18, color: AppColors.leatherDark),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(action.label),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.lightNeutral,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(19)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGreen,
                      height: 1.1,
                    ),
                  ),
                  if (data.brand.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.leatherDark,
                        fontSize: 13,
                        height: 1.1,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    data.categoryLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.leatherDark,
                      fontSize: 12,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }

  Widget _buildImage() {
    if (data.imageUrl == null || data.imageUrl!.isEmpty) {
      return Container(
        color: AppColors.neutralLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_bar_rounded,
          color: AppColors.leatherDark,
          size: 40,
        ),
      );
    }
    return Image.network(
      data.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.neutralLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.leatherDark,
        ),
      ),
    );
  }
}

class _FeaturedWhiskeyData {
  const _FeaturedWhiskeyData({
    required this.title,
    required this.brand,
    required this.category,
    required this.subCategory,
    this.imageUrl,
    this.actions = const [],
    this.region,
    this.shortDescription,
    this.tags = const [],
    this.abv,
    this.proof,
    this.ageStatement,
    this.releaseType,
    this.priceLow,
    this.priceHigh,
    this.msrp,
    this.distillery,
    this.rarity,
    this.availability,
    this.membership,
    this.id,
  });

  final String title;
  final String brand;
  final String category;
  final String subCategory;
  final String? imageUrl;
  final List<_ShowcaseAction> actions;
  final String? region;
  final String? shortDescription;
  final List<String> tags;
  final double? abv;
  final double? proof;
  final String? ageStatement;
  final String? releaseType;
  final double? priceLow;
  final double? priceHigh;
  final double? msrp;
  final String? distillery;
  final String? rarity;
  final String? availability;
  final String? membership;
  final String? id;

  String get categoryLine =>
      subCategory.trim().isEmpty ? category : '$category - $subCategory';
}

class _ProducerPlaceCardData {
  const _ProducerPlaceCardData({
    required this.name,
    required this.type,
    required this.location,
    this.imageUrl,
    this.shortDescription,
    this.styles = const [],
    this.tags = const [],
    this.websiteUrl,
    this.isVisitAble,
    this.signaturePour,
    this.membership,
  });

  final String name;
  final String type;
  final String location;
  final String? imageUrl;
  final String? shortDescription;
  final List<String> styles;
  final List<String> tags;
  final String? websiteUrl;
  final bool? isVisitAble;
  final String? signaturePour;
  final String? membership;
}

_FeaturedWhiskeyData _featuredWhiskeyDataFromMap(
  Map<String, dynamic> data, {
  String? docId,
}) {
  final name = (data['name'] as String? ?? 'Untitled Bottle').trim();
  final brand = (data['brand'] as String? ?? '').trim();
  final category = (data['category'] as String? ??
          data['style'] as String? ??
          'Special Release')
      .trim();
  final subCategory = (data['subCategory'] as String? ?? '').trim();
  final tags = _stringListFrom(data['tags']);
  return _FeaturedWhiskeyData(
    title: name.isEmpty ? 'Untitled Bottle' : name,
    brand: brand,
    category: category,
    subCategory: subCategory,
    imageUrl: (data['imageUrl'] as String?)?.trim(),
    actions: const [],
    region:
        (data['region'] as String? ?? data['country'] as String? ?? '').trim(),
    shortDescription:
        (data['shortDescription'] as String? ?? 'Tasting notes coming soon.')
            .trim(),
    tags: tags,
    abv: (data['abv'] as num?)?.toDouble(),
    proof: (data['proof'] as num?)?.toDouble(),
    ageStatement: (data['ageStatement'] as String?)?.trim(),
    releaseType: (data['releaseType'] as String?)?.trim(),
    priceLow: (data['priceLow'] as num?)?.toDouble(),
    priceHigh: (data['priceHigh'] as num?)?.toDouble(),
    msrp: (data['msrp'] as num?)?.toDouble(),
    distillery: (data['distilleryName'] as String?)?.trim(),
    rarity: (data['rarityLevel'] as String?)?.trim(),
    availability: (data['availabilityStatus'] as String?)?.trim(),
    membership: (data['membershipLevel'] as String?)?.trim(),
    id: docId,
  );
}

_ProducerPlaceCardData _producerPlaceDataFromMap(
  Map<String, dynamic> data,
) {
  final typeLabel = (data['type'] as String? ?? '').trim();
  return _ProducerPlaceCardData(
    name: (data['name'] as String? ?? 'Untitled Producer or Place').trim(),
    type: typeLabel.isEmpty ? 'Producer or Place' : typeLabel,
    location: _composeProducerLocationLabel(data),
    imageUrl: (data['imageUrl'] as String?)?.trim(),
    shortDescription:
        (data['shortDescription'] as String? ?? 'Details coming soon.').trim(),
    styles: _stringListFrom(data['primaryStyles']),
    tags: _stringListFrom(data['tags']),
    websiteUrl: (data['websiteUrl'] as String?)?.trim(),
    isVisitAble: data['isVisitAble'] as bool?,
    signaturePour: (data['signaturePour'] as String?)?.trim(),
    membership: (data['membershipLevel'] as String?)?.trim(),
  );
}

class _ProducerPlaceCard extends StatelessWidget {
  const _ProducerPlaceCard({
    required this.data,
    this.onTap,
    this.isFavorited = false,
    this.onToggleFavorite,
  });

  final _ProducerPlaceCardData data;
  final VoidCallback? onTap;
  final bool isFavorited;
  final Future<void> Function()? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 240,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutralMid),
        color: AppColors.lightNeutral,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
              child: Stack(
                children: [
                  Positioned.fill(child: _buildImage()),
                  if (onToggleFavorite != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        iconSize: 26,
                        color: isFavorited ? AppColors.leather : Colors.white,
                        icon: Icon(
                          isFavorited
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                        ),
                        onPressed: () => onToggleFavorite?.call(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.lightNeutral,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(19)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGreen,
                      height: 1.1,
                    ),
                  ),
                  if (data.type.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.leatherDark,
                        fontSize: 13,
                        height: 1.1,
                      ),
                    ),
                  ],
                  if (data.location.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      data.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.leatherDark,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }

  Widget _buildImage() {
    if (data.imageUrl == null || data.imageUrl!.isEmpty) {
      return Container(
        color: AppColors.neutralLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.location_city_rounded,
          color: AppColors.leatherDark,
          size: 40,
        ),
      );
    }
    return Image.network(
      data.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.neutralLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppColors.leatherDark,
        ),
      ),
    );
  }
}

class _DatabaseWhiskeyCard extends StatelessWidget {
  const _DatabaseWhiskeyCard({
    required this.name,
    required this.brand,
    required this.category,
    required this.subCategory,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String brand;
  final String category;
  final String subCategory;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoryLine =
        subCategory.isNotEmpty ? '$category · $subCategory' : category;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.neutralLight.withValues(alpha: 0.6)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DatabaseWhiskeyThumbnail(imageUrl: imageUrl, label: name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleMedium
                            ?.copyWith(color: AppColors.darkGreen),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (brand.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          brand,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.leatherDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (categoryLine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          categoryLine,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.leatherDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatabaseWhiskeyThumbnail extends StatelessWidget {
  const _DatabaseWhiskeyThumbnail(
      {required this.imageUrl, required this.label});

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label.isNotEmpty ? label.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkGreen,
        ),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: 48,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 48,
            height: 60,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProducerPlaceDatabaseTile extends StatelessWidget {
  const _ProducerPlaceDatabaseTile({
    required this.name,
    required this.typeLabel,
    required this.locationLabel,
    this.imageUrl,
    this.onTap,
  });

  final String name;
  final String typeLabel;
  final String locationLabel;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.neutralLight.withValues(alpha: 0.6)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DatabaseWhiskeyThumbnail(imageUrl: imageUrl, label: name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        typeLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.leatherDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.leatherDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProducerPlaceDialog extends StatelessWidget {
  const _EditProducerPlaceDialog(
      {required this.distilleryId, required this.data});

  final String distilleryId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _ProducerPlaceForm.editDialog(
          distilleryId: distilleryId,
          initialData: data,
        ),
      ),
    );
  }
}

enum _WhiskeyDialogOutcome { updated, deleted }

class _EditWhiskeyDialog extends StatelessWidget {
  const _EditWhiskeyDialog({required this.whiskeyId, required this.data});

  final String whiskeyId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _WhiskeyForm.editDialog(
          whiskeyId: whiskeyId,
          initialData: data,
        ),
      ),
    );
  }
}

class _DatabaseDistilleryList extends StatelessWidget {
  const _DatabaseDistilleryList({
    required this.query,
    required this.membership,
    this.enableEditing = true,
  });

  final String query;
  final String membership;
  final bool enableEditing;

  bool _matches(Map<String, dynamic> data) {
    final q = query.toLowerCase();
    final description =
        (data['shortDescription'] as String? ?? data['story'] as String? ?? '')
            .toLowerCase();
    final tagBlob = ((data['tags'] as List?)?.join(' ') ?? '').toLowerCase();
    final styleBlob =
        ((data['primaryStyles'] as List?)?.join(' ') ?? '').toLowerCase();
    final target =
        '${data['name'] ?? ''} ${data['type'] ?? ''} ${data['region'] ?? ''} ${data['city'] ?? ''} ${data['userName'] ?? ''} $description $tagBlob $styleBlob'
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
      emptyMessage: 'No producers or places match your filters yet.',
      itemBuilder: (context, doc) {
        final data = doc.data();
        final typeLabel = (data['type'] as String? ?? '').trim();
        return _ProducerPlaceDatabaseTile(
          imageUrl: data['imageUrl'] as String?,
          name: data['name'] as String? ?? 'Untitled Producer or Place',
          typeLabel: typeLabel.isEmpty ? 'Experience' : typeLabel,
          locationLabel: _composeProducerLocationLabel(data),
          onTap: () => enableEditing
              ? _openEditDialog(context, doc)
              : _openDetailSheet(context, data),
        );
      },
      filter: _matches,
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final result = await showDialog<_ProducerPlaceDialogOutcome>(
      context: context,
      builder: (_) => _EditProducerPlaceDialog(
        distilleryId: doc.id,
        data: doc.data(),
      ),
    );
    if (!context.mounted || result == null) return;
    final message = result == _ProducerPlaceDialogOutcome.deleted
        ? 'Producer/place deleted.'
        : 'Producer/place updated.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openDetailSheet(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final detailData = _producerPlaceDataFromMap(data);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProducerPlaceDetailSheet(data: detailData),
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
            Expanded(
              child: _DatabaseArticleList(
                query: _query,
                membership: 'All',
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

class FeaturedWhiskeyAdminPage extends StatefulWidget {
  const FeaturedWhiskeyAdminPage({super.key});

  @override
  State<FeaturedWhiskeyAdminPage> createState() =>
      _FeaturedWhiskeyAdminPageState();
}

class _FeaturedWhiskeyAdminPageState extends State<FeaturedWhiskeyAdminPage> {
  static const List<String> _rarityCategories = [
    'Everyday',
    'Limited',
    'Annual',
    'Ultra-Rare',
  ];

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('whiskeys')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Featured Whiskeys'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _FeedMessage(
              message: 'We could not load featured whiskeys.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final grouped = <String, List<_FeaturedWhiskeyData>>{
            for (final label in _rarityCategories)
              label: <_FeaturedWhiskeyData>[]
          };

          for (final doc in docs) {
            final data = doc.data();
            final isHighlighted = data['isHighlighted'] as bool? ?? false;
            if (!isHighlighted) continue;
            final rarityLabel =
                _resolveRarity((data['rarityLevel'] as String? ?? '').trim());
            if (rarityLabel == null) continue;
            final list = grouped[rarityLabel]!;
            if (list.length >= 4) continue;
            list.add(_featuredWhiskeyDataFromMap(data, docId: doc.id));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              Text(
                'Highlighted bottles by rarity',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.darkGreen),
              ),
              const SizedBox(height: 16),
              for (final label in _rarityCategories)
                _FeaturedWhiskeyCategoryRow(
                  label: label,
                  items: grouped[label] ?? const [],
                  onUnfeature: _handleUnfeature,
                  onAdd: _handleFeatureWhiskey,
                  onTap: _showWhiskeyDetail,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleUnfeature(_FeaturedWhiskeyData data) async {
    final docId = data.id;
    if (docId == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove from featured?'),
            content: Text(
              'Are you sure you want to remove ${data.title} from the featured list?',
            ),
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
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('whiskeys')
          .doc(docId)
          .update({'isHighlighted': false});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${data.title} removed from featured.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  Future<void> _handleFeatureWhiskey(String rarity) async {
    final searchController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final query = FirebaseFirestore.instance
            .collection('whiskeys')
            .where('rarityLevel', isEqualTo: rarity);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Feature $rarity whiskeys'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search whiskeys...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: query.snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Unable to load whiskeys.'),
                            );
                          }
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Text('No whiskeys found.'),
                            );
                          }
                          final filter =
                              searchController.text.trim().toLowerCase();
                          final filteredDocs = filter.isEmpty
                              ? docs
                              : docs.where((doc) {
                                  final data = doc.data();
                                  final title = (data['name'] as String? ??
                                          'Untitled Bottle')
                                      .trim()
                                      .toLowerCase();
                                  final brand = (data['brand'] as String? ?? '')
                                      .trim()
                                      .toLowerCase();
                                  return title.contains(filter) ||
                                      brand.contains(filter);
                                }).toList();
                          if (filteredDocs.isEmpty) {
                            return const Center(
                              child: Text('No whiskeys match your search.'),
                            );
                          }
                          return ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data();
                              final title =
                                  (data['name'] as String? ?? 'Untitled Bottle')
                                      .trim();
                              final brand =
                                  (data['brand'] as String? ?? '').trim();
                              final alreadyFeatured =
                                  (data['isHighlighted'] as bool? ?? false);
                              final label =
                                  brand.isEmpty ? title : '$title - $brand';
                              final labelStyle = Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: alreadyFeatured
                                        ? AppColors.neutralMid
                                        : AppColors.leatherDark,
                                  );
                              return ListTile(
                                dense: true,
                                title: Text(label, style: labelStyle),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: alreadyFeatured
                                      ? AppColors.neutralMid
                                      : AppColors.darkGreen,
                                  onPressed: alreadyFeatured
                                      ? null
                                      : () => _featureWhiskey(doc.id, title),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  Future<void> _featureWhiskey(String docId, String title) async {
    try {
      await FirebaseFirestore.instance
          .collection('whiskeys')
          .doc(docId)
          .update({'isHighlighted': true});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title featured.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update: $e')),
      );
    }
  }

  void _showWhiskeyDetail(BuildContext context, _FeaturedWhiskeyData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WhiskeyDetailSheet(data: data),
    );
  }

  String? _resolveRarity(String raw) {
    if (raw.isEmpty) return null;
    final lower = raw.toLowerCase();
    for (final label in _rarityCategories) {
      if (label.toLowerCase() == lower) return label;
    }
    return null;
  }
}

class _FeaturedWhiskeyCategoryRow extends StatelessWidget {
  const _FeaturedWhiskeyCategoryRow({
    required this.label,
    required this.items,
    required this.onUnfeature,
    required this.onAdd,
    this.onTap,
  });

  final String label;
  final List<_FeaturedWhiskeyData> items;
  final Future<void> Function(_FeaturedWhiskeyData data) onUnfeature;
  final Future<void> Function(String rarity) onAdd;
  final void Function(BuildContext context, _FeaturedWhiskeyData data)? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                textTheme.titleMedium?.copyWith(color: AppColors.leatherDark),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                for (var index = 0; index < 4; index++) ...[
                  Expanded(
                    child: _FeaturedWhiskeySquare(
                      data: index < items.length ? items[index] : null,
                      onUnfeature: index < items.length
                          ? () => onUnfeature(items[index])
                          : null,
                      onAdd: index >= items.length ? () => onAdd(label) : null,
                      onTap: index < items.length && onTap != null
                          ? () => onTap!(context, items[index])
                          : null,
                    ),
                  ),
                  if (index < 3) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedWhiskeySquare extends StatelessWidget {
  const _FeaturedWhiskeySquare(
      {this.data, this.onUnfeature, this.onAdd, this.onTap});

  final _FeaturedWhiskeyData? data;
  final Future<void> Function()? onUnfeature;
  final Future<void> Function()? onAdd;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    Widget content;
    if (data == null) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.neutralMid),
          color: AppColors.neutralLight,
        ),
        child: const Center(
          child: Icon(Icons.local_drink_rounded, color: AppColors.neutralMid),
        ),
      );
    } else {
      final imageUrl = data!.imageUrl;
      content = Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: AppColors.neutralLight,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl == null || imageUrl.isEmpty
            ? const Center(
                child: Icon(Icons.local_drink_rounded,
                    color: AppColors.leatherDark),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.leatherDark),
                ),
              ),
      );
    }

    Widget square = AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(child: content),
          if (data != null && onUnfeature != null)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onUnfeature!(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.remove, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (data == null && onAdd != null)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: AppColors.darkGreen,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onAdd!(),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (data == null && onAdd != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () => onAdd!(),
          child: square,
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: square,
        ),
      );
    }

    return square;
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

  Future<void> _openEditMerchSheet(
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
            Expanded(
              child: _MerchandiseFeed(onItemTap: _openEditMerchSheet),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatabaseArticleList extends StatelessWidget {
  const _DatabaseArticleList({
    required this.query,
    required this.membership,
    this.enableEditing = true,
  });

  final String query;
  final String membership;
  final bool enableEditing;

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
      itemBuilder: (context, doc) {
        final data = doc.data();
        final rawTitle =
            (data['title'] as String? ?? 'Untitled Article').trim();
        final title = rawTitle.isEmpty ? 'Untitled Article' : rawTitle;
        return _DatabaseArticleCard(
          title: title,
          category: (data['category'] as String? ?? 'Story').trim(),
          authorLabel: (data['userName'] as String? ?? 'Contributor').trim(),
          membership: (data['membershipLevel'] as String?)?.trim(),
          iconUrl: (data['iconUrl'] as String?)?.trim(),
          tags: _stringListFrom(data['tags']),
          createdAt: _coerceTimestamp(data['createdAt']),
          onTap: () => enableEditing
              ? _openEditDialog(context, doc.id, data)
              : _openArticleDetail(context, data),
        );
      },
      filter: _matches,
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    String articleId,
    Map<String, dynamic> data,
  ) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditArticleDialog(articleId: articleId, data: data),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article updated.')),
      );
    }
  }

  void _openArticleDetail(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final markdown = (data['markdownFilename'] as String?)?.trim();
    if (markdown == null || markdown.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article file missing.')),
      );
      return;
    }
    final title = (data['title'] as String? ?? 'Article').trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailPage(
          title: title.isEmpty ? 'Article' : title,
          markdownFileName: markdown,
        ),
      ),
    );
  }
}

class _WhiskeyDetailSheet extends StatelessWidget {
  const _WhiskeyDetailSheet({required this.data});

  final _FeaturedWhiskeyData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final infoChips = _buildInfoChips();
    final description = data.shortDescription?.trim() ?? '';
    final hasDescription = description.isNotEmpty;
    final tagWidgets = data.tags
        .map((tag) => Chip(
              label: Text(tag),
              backgroundColor: AppColors.neutralLight,
            ))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const _SheetHandle(),
              _DetailHeroImage(imageUrl: data.imageUrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                                data.title,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(color: AppColors.darkGreen),
                              ),
                              if (data.brand.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    data.brand,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.leatherDark),
                                  ),
                                ),
                              if ((data.distillery ?? '').trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Producer • ${data.distillery!.trim()}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.leatherDark),
                                  ),
                                ),
                              if ((data.region ?? '').trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    data.region!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.leatherDark),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if ((data.membership ?? '').trim().isNotEmpty)
                          Chip(
                            label: Text(data.membership!),
                            backgroundColor: AppColors.neutralLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (hasDescription) ...[
                      Text(
                        description,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (infoChips.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final label in infoChips)
                            _DetailChip(label: label),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (tagWidgets.isNotEmpty) ...[
                      Text(
                        'Flavor cues',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tagWidgets,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildInfoChips() {
    final chips = <String>[];
    void add(String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      chips.add(trimmed);
    }

    add(data.subCategory);
    add(data.ageStatement);
    if (data.abv != null) {
      chips.add('${data.abv!.toStringAsFixed(1)}% ABV');
    }
    if (data.proof != null) {
      chips.add('${data.proof!.toStringAsFixed(1)} proof');
    }
    add(data.releaseType);
    add(_buildPriceLabel());
    add(data.rarity);
    add(data.availability);
    return chips;
  }

  String? _buildPriceLabel() {
    final segments = <String>[];
    if (data.msrp != null) {
      segments.add('MSRP ${_formatCurrency(data.msrp!)}');
    }
    if (data.priceLow != null && data.priceHigh != null) {
      segments.add(
          'Typical ${_formatCurrency(data.priceLow!)} - ${_formatCurrency(data.priceHigh!)}');
    }
    if (segments.isEmpty) return null;
    return segments.join(' • ');
  }

  String _formatCurrency(double value) {
    final decimals = value == value.roundToDouble() ? 0 : 2;
    return '\$${value.toStringAsFixed(decimals)}';
  }
}

class _ProducerPlaceDetailSheet extends StatelessWidget {
  const _ProducerPlaceDetailSheet({required this.data});

  final _ProducerPlaceCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = data.shortDescription?.trim() ?? '';
    final hasDescription = description.isNotEmpty;
    final tagWidgets = data.tags
        .map((tag) => Chip(
              label: Text(tag),
              backgroundColor: AppColors.neutralLight,
            ))
        .toList();
    final styleWidgets = data.styles
        .map((style) => Chip(
              label: Text(style),
              backgroundColor: AppColors.neutralLight,
            ))
        .toList();
    final visitLabel = data.isVisitAble == false
        ? 'Visits by appointment'
        : 'Visitors welcome';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const _SheetHandle(),
              _DetailHeroImage(imageUrl: data.imageUrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                                data.name,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(color: AppColors.darkGreen),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.type,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.leatherDark),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data.location,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.leatherDark),
                              ),
                            ],
                          ),
                        ),
                        if ((data.membership ?? '').trim().isNotEmpty)
                          Chip(
                            label: Text(data.membership!),
                            backgroundColor: AppColors.neutralLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.leatherDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            visitLabel,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.leatherDark),
                          ),
                        ),
                      ],
                    ),
                    if ((data.websiteUrl ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.link, color: AppColors.leatherDark),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.websiteUrl!,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.leatherDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if ((data.signaturePour ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        data.signaturePour!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.leatherDark),
                      ),
                    ],
                    if (hasDescription) ...[
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: AppColors.darkGreen),
                      ),
                    ],
                    if (styleWidgets.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Specialties',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: styleWidgets,
                      ),
                    ],
                    if (tagWidgets.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Notable notes',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: AppColors.darkGreen),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tagWidgets,
                      ),
                    ],
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.neutralMid,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _DetailHeroImage extends StatelessWidget {
  const _DetailHeroImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.neutralLight,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.leatherDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.leatherDark),
      ),
    );
  }
}

class _ArticleShowcaseCardData {
  const _ArticleShowcaseCardData({
    required this.title,
    required this.category,
    required this.author,
    this.iconUrl,
    this.badge,
    this.actions = const [],
    this.onTap,
  });

  final String title;
  final String category;
  final String author;
  final String? iconUrl;
  final String? badge;
  final List<_ShowcaseAction> actions;
  final VoidCallback? onTap;
}

class _ArticleShowcaseCard extends StatelessWidget {
  const _ArticleShowcaseCard({
    required this.data,
    this.isFavorited = false,
    this.onToggleFavorite,
  });

  final _ArticleShowcaseCardData data;
  final bool isFavorited;
  final Future<void> Function()? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutralMid),
        color: AppColors.lightNeutral,
      ),
      child: Row(
        children: [
          _ArticleIconAvatar(iconUrl: data.iconUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.leatherDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onToggleFavorite != null)
            IconButton(
              icon: Icon(
                isFavorited
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: isFavorited ? AppColors.leather : AppColors.leatherDark,
              ),
              onPressed: () => onToggleFavorite?.call(),
            )
          else if (data.actions.isNotEmpty)
            PopupMenuButton<_ShowcaseAction>(
              tooltip: 'Save article',
              icon: const Icon(
                Icons.bookmark_outline_rounded,
                color: AppColors.leatherDark,
              ),
              onSelected: (action) => action.onSelected(context),
              itemBuilder: (context) => [
                for (final action in data.actions)
                  PopupMenuItem<_ShowcaseAction>(
                    value: action,
                    child: Row(
                      children: [
                        if (action.icon != null) ...[
                          Icon(action.icon,
                              size: 18, color: AppColors.leatherDark),
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
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}

class _DatabaseArticleCard extends StatelessWidget {
  const _DatabaseArticleCard({
    required this.title,
    required this.category,
    required this.authorLabel,
    required this.membership,
    required this.createdAt,
    this.tags = const [],
    this.iconUrl,
    this.onTap,
  });

  final String title;
  final String category;
  final String authorLabel;
  final String? membership;
  final DateTime createdAt;
  final List<String> tags;
  final String? iconUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formattedTags = tags.isEmpty ? null : tags.take(3).join(' • ');
    final dateLabel = '${createdAt.month}/${createdAt.day}/${createdAt.year}';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.neutralLight.withValues(alpha: 0.6)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _DatabaseArticleThumbnail(
                  iconUrl: iconUrl,
                  title: title,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium
                            ?.copyWith(color: AppColors.darkGreen),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.leatherDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.leatherDark),
                      ),
                      if (formattedTags != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          formattedTags,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.leatherDark,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatabaseArticleThumbnail extends StatelessWidget {
  const _DatabaseArticleThumbnail({required this.iconUrl, required this.title});

  final String? iconUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.neutralLight,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title.substring(0, 1).toUpperCase() : 'A',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkGreen,
        ),
      ),
    );

    if (iconUrl == null || iconUrl!.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        iconUrl!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _EditArticleDialog extends StatefulWidget {
  const _EditArticleDialog({required this.articleId, required this.data});

  final String articleId;
  final Map<String, dynamic> data;

  @override
  State<_EditArticleDialog> createState() => _EditArticleDialogState();
}

class _EditArticleDialogState extends State<_EditArticleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _tagsController;
  late final TextEditingController _markdownController;
  late final TextEditingController _imageController;
  final PostUploader _iconUploader = PostUploader();
  late String _category;
  String? _iconUrl;
  bool _isUploadingIcon = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    _titleController =
        TextEditingController(text: (data['title'] as String? ?? '').trim());
    _subtitleController =
        TextEditingController(text: (data['subtitle'] as String? ?? '').trim());
    _tagsController = TextEditingController(
      text: _stringListFrom(data['tags']).join(', '),
    );
    _markdownController = TextEditingController(
      text: (data['markdownFilename'] as String? ?? '').trim(),
    );
    _imageController = TextEditingController(
      text: (data['imageFilename'] as String? ?? '').trim(),
    );
    final initialCategory = (data['category'] as String? ?? '').trim();
    _category = articleCategories.contains(initialCategory)
        ? initialCategory
        : articleCategories.first;
    _iconUrl = (data['iconUrl'] as String?)?.trim();
  }

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

      await ArticleService().updateArticle(
        widget.articleId,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update article: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Article'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: [
                  for (final category in articleCategories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _category = value);
                      },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              _ArticleIconField(
                iconUrl: _iconUrl,
                isUploading: _isUploadingIcon,
                onUpload: (_isSaving || _isUploadingIcon) ? null : _uploadIcon,
                onRemove: _isSaving || _isUploadingIcon || _iconUrl == null
                    ? null
                    : _removeIcon,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  helperText: 'Comma-separated list',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _markdownController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Markdown filename',
                  helperText: 'Only the file name, e.g. whiskey-101.md',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Image filename',
                  helperText:
                      'Optional hero image from assets/images/articles/',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
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
      if (url != null) setState(() => _iconUrl = url);
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
}

class _ArticleIconField extends StatelessWidget {
  const _ArticleIconField({
    required this.iconUrl,
    required this.isUploading,
    required this.onUpload,
    required this.onRemove,
  });

  final String? iconUrl;
  final bool isUploading;
  final VoidCallback? onUpload;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon Image',
          style:
              theme.textTheme.titleSmall?.copyWith(color: AppColors.darkGreen),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.neutralLight,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: iconUrl == null
                  ? const Icon(Icons.article_outlined,
                      color: AppColors.leatherDark)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        iconUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.leatherDark,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload a square image to represent this article across the app.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.leatherDark),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: onUpload,
                        icon: isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_outlined),
                        label: Text(isUploading ? 'Uploading...' : 'Upload'),
                      ),
                      if (iconUrl != null)
                        TextButton.icon(
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArticleIconAvatar extends StatelessWidget {
  const _ArticleIconAvatar({this.iconUrl});

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 72,
        height: 72,
        color: AppColors.neutralLight,
        alignment: Alignment.center,
        child: iconUrl == null || iconUrl!.isEmpty
            ? const Icon(Icons.article_outlined, color: AppColors.leatherDark)
            : Image.network(
                iconUrl!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.leatherDark,
                ),
              ),
      ),
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
  final Widget Function(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) itemBuilder;
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
            for (final doc in filtered) itemBuilder(context, doc),
          ],
        );
      },
    );
  }
}

class _GlobalWhiskeyFeed extends StatelessWidget {
  const _GlobalWhiskeyFeed({required this.positioning});

  final String positioning;

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

        final items = <_FeaturedWhiskeyData>[];
        for (final doc in docs) {
          final data = doc.data();
          final isHighlighted = data['isHighlighted'] as bool? ?? false;
          final rarity = (data['rarityLevel'] as String? ?? '').trim();
          if (!isHighlighted) continue;
          if (rarity.toLowerCase() != positioning.toLowerCase()) continue;
          final tags = _stringListFrom(data['tags']);
          final shortDescription = (data['shortDescription'] as String? ??
                  'Tasting notes coming soon.')
              .trim();
          items.add(
            _FeaturedWhiskeyData(
              id: doc.id,
              title: data['name'] as String? ?? 'Untitled Bottle',
              brand: (data['brand'] as String? ?? '').trim(),
              category: (data['category'] as String? ??
                      data['style'] as String? ??
                      'Special Release')
                  .trim(),
              subCategory: (data['subCategory'] as String? ?? '').trim(),
              imageUrl: data['imageUrl'] as String?,
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
              region: (data['region'] as String? ??
                      data['country'] as String? ??
                      '')
                  .trim(),
              shortDescription: shortDescription,
              tags: tags,
              abv: (data['abv'] as num?)?.toDouble(),
              proof: (data['proof'] as num?)?.toDouble(),
              ageStatement: (data['ageStatement'] as String?)?.trim(),
              releaseType: (data['releaseType'] as String?)?.trim(),
              priceLow: (data['priceLow'] as num?)?.toDouble(),
              priceHigh: (data['priceHigh'] as num?)?.toDouble(),
              msrp: (data['msrp'] as num?)?.toDouble(),
              distillery: (data['distilleryName'] as String?)?.trim(),
              rarity: rarity,
              availability: (data['availabilityStatus'] as String?)?.trim(),
              membership: (data['membershipLevel'] as String?)?.trim(),
            ),
          );
        }

        if (items.isEmpty) {
          return const _FeedMessage(
            message:
                'No highlighted whiskeys match this positioning yet. Check back soon!',
          );
        }

        final subset = items.take(4).toList();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: subset.length,
          itemBuilder: (context, index) => _FeaturedWhiskeyCard(
            data: subset[index],
            onTap: () => _showWhiskeyDetail(context, subset[index]),
          ),
        );
      },
    );
  }

  void _showWhiskeyDetail(BuildContext context, _FeaturedWhiskeyData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WhiskeyDetailSheet(data: data),
    );
  }
}

class _GlobalArticleFeed extends StatelessWidget {
  const _GlobalArticleFeed();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildArticleList(context, const <String>{});
    }
    final favoritesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favoriteArticles')
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: favoritesStream,
      builder: (context, snapshot) {
        final favoriteIds = snapshot.data == null
            ? <String>{}
            : snapshot.data!.docs.map((doc) => doc.id).toSet();
        return _buildArticleList(context, favoriteIds);
      },
    );
  }

  Widget _buildArticleList(BuildContext context, Set<String> favorites) {
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

        final cards = <_ArticleShowcaseCardData>[];
        for (final doc in docs) {
          final data = doc.data();
          final rawTitle =
              (data['title'] as String? ?? 'Untitled Article').trim();
          final title = rawTitle.isEmpty ? 'Untitled Article' : rawTitle;
          final markdownFilename =
              (data['markdownFilename'] as String? ?? '').trim();
          cards.add(
            _ArticleShowcaseCardData(
              title: title,
              category: (data['category'] as String? ?? 'Story').trim(),
              author: (data['userName'] as String? ?? 'Contributor').trim(),
              badge: (data['membershipLevel'] as String?)?.trim(),
              iconUrl: (data['iconUrl'] as String?)?.trim(),
              actions: const [],
              onTap: markdownFilename.isEmpty
                  ? null
                  : () => _openArticleDetail(context, title, markdownFilename),
            ),
          );
        }

        final limitedCards = cards.take(3).toList();
        final limitedDocs = docs.take(limitedCards.length).toList();
        return Column(
          children: [
            for (var i = 0; i < limitedCards.length; i++) ...[
              _ArticleShowcaseCard(
                data: limitedCards[i],
                isFavorited: favorites.contains(limitedDocs[i].id),
                onToggleFavorite: () => _toggleFavoriteArticle(
                  context,
                  limitedDocs[i],
                  favorites.contains(limitedDocs[i].id),
                ),
              ),
              if (i != limitedCards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Future<void> _toggleFavoriteArticle(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool isFavorited,
  ) async {
    final data = doc.data();
    final service = UserLibraryService();
    final rawTitle = (data['title'] as String? ?? 'Article').trim();
    final resolvedTitle = rawTitle.isEmpty ? 'This article' : rawTitle;
    try {
      if (isFavorited) {
        await service.removeFavoriteArticle(doc.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$resolvedTitle removed from favorites.')),
        );
        return;
      }
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
            content:
                Text('Could not update: ${_resolveActionErrorMessage(e)}')),
      );
    }
  }

  void _openArticleDetail(
    BuildContext context,
    String title,
    String markdownFilename,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleDetailPage(
          title: title,
          markdownFileName: markdownFilename,
        ),
      ),
    );
  }
}

class _GlobalDistilleryFeed extends StatelessWidget {
  const _GlobalDistilleryFeed();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildDistilleryFeed(context, const <String>{});
    }
    final favoritesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favoriteDistilleries')
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: favoritesStream,
      builder: (context, snapshot) {
        final favoriteIds = snapshot.data == null
            ? <String>{}
            : snapshot.data!.docs.map((doc) => doc.id).toSet();
        return _buildDistilleryFeed(context, favoriteIds);
      },
    );
  }

  Widget _buildDistilleryFeed(
    BuildContext context,
    Set<String> favorites,
  ) {
    final stream = FirebaseFirestore.instance
        .collection('distilleries')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedMessage(
            message: 'We could not load producers and places yet.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _FeedMessage(
            message: 'No producers or places yet. Add one from your profile!',
          );
        }

        final items = <_ProducerPlaceCardData>[];
        for (final doc in docs) {
          final data = doc.data();
          final typeLabel = (data['type'] as String? ?? '').trim();
          final locationOnly = _composeProducerLocationOnly(data).trim();
          final locationLabel =
              locationOnly.isEmpty ? 'Location coming soon' : locationOnly;
          final styles = _stringListFrom(data['primaryStyles']);
          final tags = _stringListFrom(data['tags']);
          items.add(
            _ProducerPlaceCardData(
              name: data['name'] as String? ?? 'Untitled Producer or Place',
              type: typeLabel.isEmpty ? 'Producer or Place' : typeLabel,
              location: locationLabel,
              imageUrl: data['imageUrl'] as String?,
              shortDescription: (data['shortDescription'] as String? ??
                      'Details coming soon.')
                  .trim(),
              styles: styles,
              tags: tags,
              websiteUrl: (data['websiteUrl'] as String?)?.trim(),
              isVisitAble: data['isVisitAble'] as bool?,
              signaturePour: (data['signaturePour'] as String?)?.trim(),
              membership: (data['membershipLevel'] as String?)?.trim(),
            ),
          );
        }

        return SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final isFavorited = favorites.contains(doc.id);
              return _ProducerPlaceCard(
                data: items[index],
                onTap: () => _showProducerDetail(context, items[index]),
                isFavorited: isFavorited,
                onToggleFavorite: () =>
                    _toggleFavoriteDistillery(context, doc, isFavorited),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _toggleFavoriteDistillery(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool isFavorited,
  ) async {
    final data = doc.data();
    final service = UserLibraryService();
    final rawName = (data['name'] as String? ?? 'Producer or Place').trim();
    final resolvedName = rawName.isEmpty ? 'This producer or place' : rawName;
    try {
      if (isFavorited) {
        await service.removeFavoriteDistillery(doc.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$resolvedName removed from favorites.')),
        );
        return;
      }
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
          content: Text('Could not update: ${_resolveActionErrorMessage(e)}'),
        ),
      );
    }
  }

  void _showProducerDetail(
    BuildContext context,
    _ProducerPlaceCardData data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProducerPlaceDetailSheet(data: data),
    );
  }
}
