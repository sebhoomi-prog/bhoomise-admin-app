import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/firebase/repositories/shared_app_firestore_repository.dart';
import 'customer_home_defaults.dart';
import '../domain/customer_home_category.dart';

/// CMS document: `app/customer_home` — public read; admin write ([firestore.rules] `app/{docId}`).
///
/// Allowed image URLs:
/// - Unsplash CDN (`images.unsplash.com`) — [unsplashAsJpeg] forces JPEG on Android where needed.
/// - Firebase Storage download URLs from uploads under `customer_home/` (admin device uploads).
class CustomerHomeFirestoreDataSource {
  CustomerHomeFirestoreDataSource({
    SharedAppFirestoreRepository? appRepo,
    FirebaseFirestore? db,
  }) : _appRepo = appRepo ?? SharedAppFirestoreRepository(db);

  final SharedAppFirestoreRepository _appRepo;

  static const collection = 'app';
  static const docId = 'customer_home';

  /// Legacy / remote reference images from Unsplash.
  static const unsplashImagesHostPrefix = 'https://images.unsplash.com/';

  /// Firebase Storage HTTPS download URLs (includes `token=` query).
  static const _firebaseStorageDownloadHost = 'firebasestorage.googleapis.com';

  static bool isAllowedTileImageUrl(String url) {
    final u = url.trim().toLowerCase();
    if (u.startsWith(unsplashImagesHostPrefix)) return true;
    return u.startsWith('https://$_firebaseStorageDownloadHost/');
  }

  DocumentReference<Map<String, dynamic>> get _ref =>
      _appRepo.appDoc(docId);

  List<CustomerHomeCategory> _parseCategories(Map<String, dynamic>? data) {
    if (data == null) return defaultCustomerHomeCategories();
    final raw = data['categories'];
    if (raw is! List<dynamic>) return defaultCustomerHomeCategories();
    final parsed = <CustomerHomeCategory>[];
    for (final item in raw) {
      final c = CustomerHomeCategory.tryParse(item);
      if (c != null) parsed.add(c);
    }
    if (parsed.isEmpty) return defaultCustomerHomeCategories();
    parsed.sort((a, b) => a.order.compareTo(b.order));
    return parsed;
  }

  /// Live updates when an admin saves from Console or the admin app.
  Stream<List<CustomerHomeCategory>> watchCategories() {
    return _ref.snapshots().map((snap) => _parseCategories(snap.data()));
  }

  Future<List<CustomerHomeCategory>> fetchCategoriesOnce() async {
    final snap = await _ref.get();
    return _parseCategories(snap.data());
  }

  Future<void> saveCategories(List<CustomerHomeCategory> categories) async {
    for (final c in categories) {
      if (!isAllowedTileImageUrl(c.imageUrl)) {
        throw FormatException(
          'Image URL must be Unsplash ($unsplashImagesHostPrefix…) '
          'or a Firebase Storage download URL (upload from device on admin screen).',
          c.imageUrl,
        );
      }
    }
    await _ref.set(
      {
        'categories': categories.map((e) => e.toFirestoreMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
