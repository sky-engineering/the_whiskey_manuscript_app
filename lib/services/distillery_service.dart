import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DistilleryService {
  DistilleryService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> addDistillery({
    required String name,
    required String type,
    required String country,
    required String region,
    required String stateOrProvince,
    required String city,
    required bool isVisitAble,
    required List<String> primaryStyles,
    required String shortDescription,
    List<String> tags = const [],
    String? websiteUrl,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final membership = await _userMembershipLevel(user.uid);
    final payload = _buildDistilleryPayload(
      user: user,
      membership: membership,
      name: name,
      type: type,
      country: country,
      region: region,
      stateOrProvince: stateOrProvince,
      city: city,
      isVisitAble: isVisitAble,
      primaryStyles: primaryStyles,
      shortDescription: shortDescription,
      tags: tags,
      websiteUrl: websiteUrl,
      imageUrl: imageUrl,
    );

    await _firestore.collection('distilleries').add({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDistillery(
    String distilleryId, {
    required String name,
    required String type,
    required String country,
    required String region,
    required String stateOrProvince,
    required String city,
    required bool isVisitAble,
    required List<String> primaryStyles,
    required String shortDescription,
    List<String> tags = const [],
    String? websiteUrl,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final docRef = _firestore.collection('distilleries').doc(distilleryId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw StateError('Producer/place not found.');
    }
    final ownerId = snapshot.data()?['userId'] as String?;
    if (ownerId != user.uid) {
      throw Exception('You can only edit your own producers or places.');
    }

    final membership = await _userMembershipLevel(user.uid);
    final payload = _buildDistilleryPayload(
      user: user,
      membership: membership,
      name: name,
      type: type,
      country: country,
      region: region,
      stateOrProvince: stateOrProvince,
      city: city,
      isVisitAble: isVisitAble,
      primaryStyles: primaryStyles,
      shortDescription: shortDescription,
      tags: tags,
      websiteUrl: websiteUrl,
      imageUrl: imageUrl,
    );

    await docRef.update({
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _userMembershipLevel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['membershipLevel'] as String?;
  }

  Future<void> deleteDistillery(String distilleryId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final docRef = _firestore.collection('distilleries').doc(distilleryId);
    final snapshot = await docRef.get();
    final ownerId = snapshot.data()?['userId'] as String?;
    if (!snapshot.exists || ownerId != user.uid) {
      throw Exception('You can only delete your own producers or places.');
    }

    await docRef.delete();
  }

  Map<String, dynamic> _buildDistilleryPayload({
    required User user,
    required String? membership,
    required String name,
    required String type,
    required String country,
    required String region,
    required String stateOrProvince,
    required String city,
    required bool isVisitAble,
    required List<String> primaryStyles,
    required String shortDescription,
    List<String> tags = const [],
    String? websiteUrl,
    String? imageUrl,
  }) {
    final normalizedTags = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    final normalizedStyles = [
      for (final style in primaryStyles)
        if (style.trim().isNotEmpty) style.trim(),
    ];
    final normalizedCountry = country.trim();
    final normalizedRegion = region.trim();
    final normalizedState = stateOrProvince.trim();
    final normalizedCity = city.trim();
    final summary = shortDescription.trim().isEmpty
        ? 'Details coming soon.'
        : shortDescription.trim();
    final locationParts = [
      if (normalizedCity.isNotEmpty) normalizedCity,
      if (normalizedState.isNotEmpty) normalizedState,
      if (normalizedRegion.isNotEmpty) normalizedRegion,
      if (normalizedCountry.isNotEmpty) normalizedCountry,
    ];
    final locationLabel = locationParts.isEmpty
        ? 'Location coming soon'
        : locationParts.join(', ');
    final specialtyLabel = normalizedStyles.isEmpty
        ? 'Signature pour TBD'
        : 'Specialties: ${normalizedStyles.join(', ')}';

    return {
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Explorer',
      'userEmail': user.email,
      'membershipLevel': membership,
      'name': name.trim(),
      'type': type.trim(),
      'country': normalizedCountry,
      'region': normalizedRegion,
      'stateOrProvince': normalizedState,
      'city': normalizedCity,
      'isVisitAble': isVisitAble,
      'primaryStyles': normalizedStyles,
      'shortDescription': summary,
      'websiteUrl': _normalizeOptional(websiteUrl),
      'imageUrl': imageUrl,
      'tags': normalizedTags,
      'location': locationLabel,
      'story': summary,
      'signaturePour': specialtyLabel,
    };
  }

  String? _normalizeOptional(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
