/// Notification model for in-app notifications.
class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.recipientUid,
    required this.title,
    required this.body,
    this.kind,
    this.relatedId,
    this.createdAt,
  });

  final String id;
  final String recipientUid;
  final String title;
  final String body;
  final String? kind;
  final String? relatedId;
  final DateTime? createdAt;
}

/// Stub implementation for in-app notifications.
/// Currently returns empty streams as notifications are not implemented via API yet.
class InAppNotifications {
  InAppNotifications();

  static const collection = 'notifications';
  static const adminBroadcastRecipient = 'ADMIN_BROADCAST';

  Future<void> notifyAdminsNewListing({
    required String submissionId,
    required String title,
    required String storeId,
  }) async {
    // TODO: Implement via API when notification endpoint is available
  }

  Future<void> notifyVendorListingDecision({
    required String vendorUid,
    required String submissionId,
    required bool approved,
    String? rejectionReason,
  }) async {
    // TODO: Implement via API when notification endpoint is available
  }

  Stream<List<InAppNotification>> watchAdminFeed({int limit = 40}) {
    return Stream.value([]);
  }

  Stream<List<InAppNotification>> watchForUser(
    String uid, {
    int limit = 30,
  }) {
    return Stream.value([]);
  }
}
