import 'package:cloud_firestore/cloud_firestore.dart';

class MembershipService {
  MembershipService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Set<String> _allowedTiers = {
    'free',
    'neat',
    'cask',
    'manuscript',
  };

  static const Set<String> _allowedStatuses = {
    'active',
    'grace',
    'paused',
    'canceled',
  };

  static const Set<String> _allowedBillingProviders = {
    'stripe',
    'apple',
    'google',
    'manual',
  };

  Future<Map<String, dynamic>> ensureMembershipProfile({
    required String userId,
    String? fallbackTier,
  }) async {
    final docRef = _firestore.collection('users').doc(userId);
    final snapshot = await docRef.get();
    final existingTierSource = fallbackTier ??
        snapshot.data()?['membershipLevel'] as String? ??
        'free';
    final normalizedFallback =
        _normalizeTier(existingTierSource) ?? 'free';

    if (!snapshot.exists) {
      final defaults = _defaultMembershipData(normalizedFallback);
      await docRef.set({'membership': defaults}, SetOptions(merge: true));
      return defaults;
    }

    final membership = Map<String, dynamic>.from(
      (snapshot.data()?['membership'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
    );

    bool updated = false;

    final resolvedTier =
        _normalizeTier(membership['tier'] as String?) ?? normalizedFallback;
    if (membership['tier'] != resolvedTier) {
      membership['tier'] = resolvedTier;
      updated = true;
    }

    final resolvedStatus = _normalizeStatus(membership['status'] as String?);
    if (membership['status'] != resolvedStatus) {
      membership['status'] = resolvedStatus;
      updated = true;
    }

    final resolvedProvider =
        _normalizeProvider(membership['billingProvider'] as String?);
    if (membership['billingProvider'] != resolvedProvider) {
      membership['billingProvider'] = resolvedProvider;
      updated = true;
    }

    final now = Timestamp.fromDate(DateTime.now());
    updated = _ensureValue(membership, 'startedAt', now) || updated;
    updated = _ensureValue(membership, 'renewsAt', now) || updated;
    updated = _ensureValue(membership, 'canceledAt', null) || updated;
    updated = _ensureValue(membership, 'billingCustomerId', null) || updated;
    updated = _ensureValue(membership, 'trialEndsAt', null) || updated;

    if (updated) {
      await docRef.set({'membership': membership}, SetOptions(merge: true));
    }

    return membership;
  }

  String? _normalizeTier(String? tier) {
    if (tier == null) return null;
    final normalized = tier.trim().toLowerCase();
    if (_allowedTiers.contains(normalized)) {
      return normalized;
    }
    return null;
  }

  String _normalizeStatus(String? status) {
    if (status == null) return 'active';
    final normalized = status.trim().toLowerCase();
    if (_allowedStatuses.contains(normalized)) {
      return normalized;
    }
    return 'active';
  }

  String _normalizeProvider(String? provider) {
    if (provider == null) return 'manual';
    final normalized = provider.trim().toLowerCase();
    if (_allowedBillingProviders.contains(normalized)) {
      return normalized;
    }
    return 'manual';
  }

  bool _ensureValue(
    Map<String, dynamic> membership,
    String key,
    dynamic value,
  ) {
    if (!membership.containsKey(key) || membership[key] == null) {
      membership[key] = value;
      return true;
    }
    return false;
  }

  Map<String, dynamic> _defaultMembershipData(String tier) {
    final now = Timestamp.fromDate(DateTime.now());
    return {
      'tier': tier,
      'status': 'active',
      'startedAt': now,
      'renewsAt': now,
      'canceledAt': null,
      'billingProvider': 'manual',
      'billingCustomerId': null,
      'trialEndsAt': null,
    };
  }
}
