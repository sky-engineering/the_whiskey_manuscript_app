import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_whiskey_manuscript_app/src/repositories/firestore_repository.dart';

void main() {
  group('FirestoreRepository stream caching', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreRepository(firestore: firestore);
    });

    test('reuses the global posts feed stream', () {
      final first = repository.postsFeedStream();
      final second = repository.postsFeedStream();

      expect(identical(first, second), isTrue);
    });

    test('creates unique user post streams per userId', () {
      final alphaFirst = repository.userPostsStream('alpha');
      final alphaSecond = repository.userPostsStream('alpha');
      final betaStream = repository.userPostsStream('beta');

      expect(identical(alphaFirst, alphaSecond), isTrue);
      expect(identical(alphaFirst, betaStream), isFalse);
    });

    test('creates unique follower/following streams per userId', () {
      final followerA = repository.followersStream('person-a');
      final followerB = repository.followersStream('person-b');
      final followerASecond = repository.followersStream('person-a');

      final followingA = repository.followingStream('person-a');
      final followingB = repository.followingStream('person-b');
      final followingASecond = repository.followingStream('person-a');

      expect(identical(followerA, followerASecond), isTrue);
      expect(identical(followerA, followerB), isFalse);

      expect(identical(followingA, followingASecond), isTrue);
      expect(identical(followingA, followingB), isFalse);
    });
  });
}
