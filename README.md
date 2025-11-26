# The Whiskey Manuscript App

Internal dashboard that lets members browse content, manage libraries, and chat
with their friends. The project is a standard Flutter application that targets
Android, iOS, web, and desktop via `flutter run`.

## Local Development

```bash
flutter pub get
flutter run -d chrome   # or any other connected device
```

### Required Firestore Indexes

Direct messages rely on a composite index so that each chat room can stream its
history ordered by `sentAt`. Deploy the index definition after creating your
Firebase project:

```bash
firebase deploy --only firestore:indexes
```

To see the exact configuration, check `firestore.indexes.json` in the repo.
