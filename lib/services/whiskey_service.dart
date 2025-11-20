import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WhiskeyService {
  WhiskeyService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> addWhiskey({
    required String name,
    required String country,
    String? countryCode,
    required String region,
    required String category,
    required String subCategory,
    required String ageStatement,
    required double abv,
    double? proof,
    required String releaseType,
    String? brand,
    String? distilleryId,
    String? distilleryName,
    String? vintageOrBatch,
    int? yearReleased,
    required double msrp,
    required double priceLow,
    required double priceHigh,
    required String rarityLevel,
    required String availabilityStatus,
    required String shortDescription,
    required List<String> tags,
    required bool isHighlighted,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final membership = await _userMembershipLevel(user.uid);
    final payload = _buildWhiskeyPayload(
      user: user,
      membership: membership,
      name: name,
      country: country,
      countryCode: countryCode,
      region: region,
      category: category,
      subCategory: subCategory,
      ageStatement: ageStatement,
      abv: abv,
      proof: proof,
      releaseType: releaseType,
      brand: brand,
      distilleryId: distilleryId,
      distilleryName: distilleryName,
      vintageOrBatch: vintageOrBatch,
      yearReleased: yearReleased,
      msrp: msrp,
      priceLow: priceLow,
      priceHigh: priceHigh,
      rarityLevel: rarityLevel,
      availabilityStatus: availabilityStatus,
      shortDescription: shortDescription,
      tags: tags,
      isHighlighted: isHighlighted,
      imageUrl: imageUrl,
    );

    await _firestore.collection('whiskeys').add({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWhiskey(
    String whiskeyId, {
    required String name,
    required String country,
    String? countryCode,
    required String region,
    required String category,
    required String subCategory,
    required String ageStatement,
    required double abv,
    double? proof,
    required String releaseType,
    String? brand,
    String? distilleryId,
    String? distilleryName,
    String? vintageOrBatch,
    int? yearReleased,
    required double msrp,
    required double priceLow,
    required double priceHigh,
    required String rarityLevel,
    required String availabilityStatus,
    required String shortDescription,
    required List<String> tags,
    required bool isHighlighted,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final docRef = _firestore.collection('whiskeys').doc(whiskeyId);
    final existing = await docRef.get();
    if (!existing.exists) {
      throw Exception('Whiskey not found.');
    }
    final ownerId = existing.data()?['userId'] as String?;
    if (ownerId != user.uid) {
      throw Exception('You can only edit your own whiskeys.');
    }

    final membership = await _userMembershipLevel(user.uid);
    final payload = _buildWhiskeyPayload(
      user: user,
      membership: membership,
      name: name,
      country: country,
      countryCode: countryCode,
      region: region,
      category: category,
      subCategory: subCategory,
      ageStatement: ageStatement,
      abv: abv,
      proof: proof,
      releaseType: releaseType,
      brand: brand,
      distilleryId: distilleryId,
      distilleryName: distilleryName,
      vintageOrBatch: vintageOrBatch,
      yearReleased: yearReleased,
      msrp: msrp,
      priceLow: priceLow,
      priceHigh: priceHigh,
      rarityLevel: rarityLevel,
      availabilityStatus: availabilityStatus,
      shortDescription: shortDescription,
      tags: tags,
      isHighlighted: isHighlighted,
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

  Future<void> deleteWhiskey(String whiskeyId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final docRef = _firestore.collection('whiskeys').doc(whiskeyId);
    final snapshot = await docRef.get();
    final ownerId = snapshot.data()?['userId'] as String?;
    if (!snapshot.exists || ownerId != user.uid) {
      throw Exception('You can only delete your own whiskeys.');
    }

    await docRef.delete();
  }

  String? _normalizeOptional(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> _buildWhiskeyPayload({
    required User user,
    required String? membership,
    required String name,
    required String country,
    String? countryCode,
    required String region,
    required String category,
    required String subCategory,
    required String ageStatement,
    required double abv,
    double? proof,
    required String releaseType,
    String? brand,
    String? distilleryId,
    String? distilleryName,
    String? vintageOrBatch,
    int? yearReleased,
    required double msrp,
    required double priceLow,
    required double priceHigh,
    required String rarityLevel,
    required String availabilityStatus,
    required String shortDescription,
    required List<String> tags,
    required bool isHighlighted,
    String? imageUrl,
  }) {
    final normalizedBrand = _normalizeOptional(brand);
    final normalizedDistilleryName = _normalizeOptional(distilleryName);
    final normalizedVintage = _normalizeOptional(vintageOrBatch);
    final normalizedRegion = region.trim();
    final normalizedCountry = country.trim();
    final normalizedCategory = category.trim();
    final normalizedSubCategory = subCategory.trim();
    final normalizedAge =
        ageStatement.trim().isEmpty ? 'NAS' : ageStatement.trim();
    final cleanedDescription = shortDescription.trim();
    final normalizedTags = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    final resolvedProof = proof ?? (abv * 2);
    final styleLabel = normalizedSubCategory.isEmpty
        ? normalizedCategory
        : '$normalizedCategory - $normalizedSubCategory';

    return {
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Anonymous',
      'userEmail': user.email,
      'membershipLevel': membership,
      'name': name.trim(),
      'brand': normalizedBrand,
      'distilleryId': distilleryId,
      'distilleryName': normalizedDistilleryName,
      'country': normalizedCountry,
      'countryCode': countryCode,
      'region': normalizedRegion,
      'category': normalizedCategory,
      'subCategory': normalizedSubCategory,
      'ageStatement': normalizedAge,
      'abv': abv,
      'proof': resolvedProof,
      'releaseType': releaseType.trim(),
      'vintageOrBatch': normalizedVintage,
      'yearReleased': yearReleased,
      'msrp': msrp,
      'priceLow': priceLow,
      'priceHigh': priceHigh,
      'rarityLevel': rarityLevel.trim(),
      'availabilityStatus': availabilityStatus.trim(),
      'shortDescription': cleanedDescription,
      'notes': cleanedDescription,
      'tags': normalizedTags,
      'isHighlighted': isHighlighted,
      'imageUrl': imageUrl,
      'style': styleLabel,
    };
  }
}
