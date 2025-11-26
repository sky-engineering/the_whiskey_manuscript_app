part of 'package:the_whiskey_manuscript_app/main.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({
    super.key,
    Query<Map<String, dynamic>>? eventsQuery,
    FirestoreRepository? repository,
  })  : _eventsQuery = eventsQuery,
        _repository = repository;

  final Query<Map<String, dynamic>>? _eventsQuery;
  final FirestoreRepository? _repository;

  @override
  Widget build(BuildContext context) {
    final stream = _eventsQuery != null
        ? _eventsQuery.snapshots()
        : (_repository ?? FirestoreRepository()).eventsStream();

    return Padding(
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Events Calendar',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppColors.darkGreen),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track releases, tastings, and meetups hosted by Whiskey Manuscript members.',
                style: TextStyle(color: AppColors.leatherDark),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const Expanded(
                  child: _FeedMessage(
                    message:
                        'No events planned yet. Add one from your profile.',
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final title =
                          (data['title'] as String? ?? 'Private Event').trim();
                      final location =
                          (data['location'] as String? ?? 'TBD').trim();
                      final details = (data['details'] as String? ?? '').trim();
                      final date = _coerceTimestamp(data['date']);
                      return _EventCard(
                        title: title,
                        location: location,
                        details: details,
                        date: date,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
