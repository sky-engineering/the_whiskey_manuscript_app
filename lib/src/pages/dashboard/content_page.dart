part of 'package:the_whiskey_manuscript_app/main.dart';

class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  static const List<String> _positioningOptions = [
    'Everyday',
    'Limited',
    'Annual',
    'Ultra-Rare',
  ];

  String _selectedPositioning = _positioningOptions.first;

  void _openDatabaseSheet(BuildContext context) {
    _openLibraryDatabase(context, initialTab: 0);
  }

  void _handlePositioningChanged(String? value) {
    if (value == null || value == _selectedPositioning) return;
    setState(() => _selectedPositioning = value);
  }

  void _openWhiskeyDatabasePage(BuildContext context) {
    _openLibraryDatabase(context, initialTab: 0);
  }

  void _openDistilleryDatabasePage(BuildContext context) {
    _openLibraryDatabase(context, initialTab: 1);
  }

  void _openArticlesDatabasePage(BuildContext context) {
    _openLibraryDatabase(context, initialTab: 2);
  }

  void _openLibraryDatabase(BuildContext context, {required int initialTab}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LibraryDatabasePage(initialTab: initialTab),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mediaSize = MediaQuery.of(context).size;
    final databaseButtonWidth =
        (mediaSize.width * 0.95).clamp(0.0, mediaSize.width);
    return ListView(
      physics: const BouncingScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: GestureDetector(
              onTap: () => _openDatabaseSheet(context),
              child: SizedBox(
                width: databaseButtonWidth,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkGreen, width: 2),
                    color: AppColors.neutralLight,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'The Whiskey Manuscript Database',
                    style: textTheme.titleMedium
                        ?.copyWith(color: AppColors.darkGreen),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Featured Whiskeys',
                style:
                    textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
              ),
              const SizedBox(width: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.darkGreen, width: 1.2),
                  color: AppColors.neutralLight,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPositioning,
                    borderRadius: BorderRadius.zero,
                    isDense: true,
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    items: [
                      for (final option in _positioningOptions)
                        DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                    ],
                    onChanged: _handlePositioningChanged,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openWhiskeyDatabasePage(context),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _GlobalWhiskeyFeed(positioning: _selectedPositioning),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Producers and Places',
                style:
                    textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openDistilleryDatabasePage(context),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _GlobalDistilleryFeed(),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Recent Articles',
                style:
                    textTheme.titleLarge?.copyWith(color: AppColors.darkGreen),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openArticlesDatabasePage(context),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _GlobalArticleFeed(),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MerchandisePage()),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkGreen, width: 2),
                  color: AppColors.neutralLight,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkGreen.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_rounded,
                        color: AppColors.darkGreen),
                    const SizedBox(width: 12),
                    Text(
                      'Visit Merchandise',
                      style: textTheme.titleMedium
                          ?.copyWith(color: AppColors.darkGreen),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShowcaseAction {
  const _ShowcaseAction({
    required this.label,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Future<void> Function(BuildContext context) onSelected;
}

String _resolveActionErrorMessage(Object error) {
  final raw = error.toString();
  if (raw.startsWith('Exception: ')) {
    return raw.substring(11);
  }
  if (raw.startsWith('Bad state: ')) {
    return raw.substring(11);
  }
  return raw;
}

List<String> _stringListFrom(dynamic raw) {
  if (raw is Iterable) {
    return raw
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }
  return const [];
}

String _composeProducerLocationOnly(Map<String, dynamic> data) {
  final city = (data['city'] as String? ?? '').trim();
  final state = (data['stateOrProvince'] as String? ?? '').trim();
  final region = (data['region'] as String? ?? '').trim();
  final country = (data['country'] as String? ?? '').trim();
  final parts = [
    if (city.isNotEmpty) city,
    if (state.isNotEmpty) state,
    if (region.isNotEmpty) region,
    if (country.isNotEmpty) country,
  ];
  if (parts.isNotEmpty) return parts.join(', ');
  return (data['location'] as String? ?? '').trim();
}

String _composeProducerLocationLabel(Map<String, dynamic> data) {
  final type = (data['type'] as String? ?? '').trim();
  final location = _composeProducerLocationOnly(data);
  if (type.isEmpty && location.isEmpty) {
    return 'Location coming soon';
  }
  if (type.isEmpty) return location;
  if (location.isEmpty) return type;
  return '$type \u2022 $location';
}
