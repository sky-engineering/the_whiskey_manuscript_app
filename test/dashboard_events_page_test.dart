import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_whiskey_manuscript_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventsPage', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    testWidgets('shows the empty state when there are no events',
        (tester) async {
      final query = firestore.collection('events').orderBy('date');

      await tester.pumpWidget(
        MaterialApp(home: EventsPage(eventsQuery: query)),
      );

      await tester.pump();

      expect(
        find.text('No events planned yet. Add one from your profile.'),
        findsOneWidget,
      );
    });

    testWidgets('renders event cards from Firestore data', (tester) async {
      final query = firestore.collection('events').orderBy('date');
      await firestore.collection('events').add({
        'title': 'Vault Tasting',
        'location': 'Chicago, IL',
        'details': 'Private barrel pick',
        'date': Timestamp.fromDate(DateTime(2030, 1, 1)),
      });

      await tester.pumpWidget(
        MaterialApp(home: EventsPage(eventsQuery: query)),
      );

      await tester.pump();

      expect(find.text('Vault Tasting'), findsOneWidget);
      expect(find.textContaining('Chicago'), findsOneWidget);
    });
  });
}
