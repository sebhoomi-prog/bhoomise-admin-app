import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../modules/customer/home/data/customer_home_defaults.dart';
import '../constants/firestore_admin.dart';

/// Auth restores persisted sessions asynchronously. At cold start, [User] is often still
/// `null` when this runs from [main] — the seed then incorrectly skips as "not admin".
Future<void> _waitForAuthRestoreIfNeeded({required bool seedExplicit}) async {
  if (FirebaseAuth.instance.currentUser != null) return;
  // Release + `--dart-define=SEED_FIRESTORE=true`: allow longer wait for token restore.
  final maxMs = seedExplicit ? 2500 : 500;
  const stepMs = 50;
  var elapsed = 0;
  while (FirebaseAuth.instance.currentUser == null && elapsed < maxMs) {
    await Future<void>.delayed(const Duration(milliseconds: stepMs));
    elapsed += stepMs;
  }
}

/// **TEMPORARY — remove before production.**
///
/// Pushes deterministic dummy documents to Firestore for manual testing (catalog,
/// store, inventory). **Only runs when the signed-in user is a Firestore admin**
/// ([isFirebaseUserFirestoreAdmin]) — same as [firestore.rules] `isAdmin()`.
/// Anonymous users are not admins; sign in with the admin phone first.
///
/// **Debug builds:** attempts seed once (unless `SKIP_SEED_FIRESTORE=true`).
///
/// **Profile / release:** set `--dart-define=SEED_FIRESTORE=true` to seed.
///
/// Re-run after clearing prefs + deleting `app/seed` doc, or:
/// ```bash
/// flutter run --dart-define=FORCE_SEED_FIRESTORE=true
/// ```
const _prefsKeySeeded = 'bhoomise_firestore_seeded_v1';

/// Matches [ProductModel] / mock `products_index.json` shape for a future Firestore datasource.
Future<void> maybeSeedFirestoreForTesting(SharedPreferences prefs) async {
  const seedExplicit = bool.fromEnvironment('SEED_FIRESTORE', defaultValue: false);
  const skipAutoDebug = bool.fromEnvironment('SKIP_SEED_FIRESTORE', defaultValue: false);
  const force = bool.fromEnvironment('FORCE_SEED_FIRESTORE', defaultValue: false);

  // Debug + profile: auto-run once. Release needs `--dart-define=SEED_FIRESTORE=true`.
  final runSeed =
      seedExplicit || (((kDebugMode || kProfileMode) && !skipAutoDebug));

  if (!runSeed) {
    debugPrint(
      'FirestoreTestSeed: skipped (seed disabled for this build). '
      'Use debug/profile, or `flutter run --dart-define=SEED_FIRESTORE=true`.',
    );
    return;
  }
  if (!force && prefs.getBool(_prefsKeySeeded) == true) {
    debugPrint('FirestoreTestSeed: skipped (already seeded). Use FORCE_SEED_FIRESTORE=true to redo.');
    return;
  }

  await _waitForAuthRestoreIfNeeded(seedExplicit: seedExplicit);

  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (!await isFirebaseUserFirestoreAdmin(firebaseUser)) {
    debugPrint(
      'FirestoreTestSeed: skipped — not a Firestore admin. '
      'Add `admin_phones/{your E.164}` in Console (or admin claim), then sign in again.',
    );
    return;
  }

  try {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? firebaseUser!.uid;

    const storeId = 'store_demo_indiranagar';

    // --- App marker (idempotency + visibility in console)
    final seedRef = db.collection('app').doc('seed');
    batch.set(
      seedRef,
      {
        'version': 1,
        'purpose': 'bhoomise_test_seed',
        'seededAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // --- Customer home category tiles (same doc the app reads at runtime)
    batch.set(
      db.collection('app').doc('customer_home'),
      {
        'categories':
            defaultCustomerHomeCategories().map((e) => e.toFirestoreMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // --- Master products (admin-owned catalog; structure aligned with ProductModel.toJson)
    final products = _dummyProducts();
    for (final p in products) {
      final ref = db.collection('products').doc(p['id'] as String);
      batch.set(
        ref,
        {
          ...p,
          'published': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // --- Store profile (vendor / retailer)
    batch.set(
      db.collection('stores').doc(storeId),
      {
        'name': 'Bhoomise Hub — Indiranagar',
        'city': 'Bengaluru',
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // --- Per-store inventory (variant stock at this store)
    final inv = _dummyStoreInventory(storeId);
    for (final entry in inv.entries) {
      batch.set(
        db.collection('stores').doc(storeId).collection('inventory').doc(entry.key),
        {
          ...entry.value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    // --- Sample B2B / fulfillment order (vendor testing)
    // [customerId] matches signed-in admin so Firestore rules allow create.
    batch.set(
      db.collection('orders').doc('order_seed_so_24001'),
      {
        'customerId': uid,
        'type': 'supply',
        'status': 'in_transit',
        'storeId': storeId,
        'storeName': 'Bhoomise Hub — Indiranagar',
        'totalLabel': '₹42,800',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // --- Demo coupons (pack-aware rules mirror Blinkit-style promos)
    batch.set(
      db.collection('coupons').doc('BHOOMISE10'),
      {
        'code': 'BHOOMISE10',
        'percentOff': 10,
        'active': true,
        'maxRedemptions': 1000,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      db.collection('coupons').doc('BULK15'),
      {
        'code': 'BULK15',
        'percentOff': 15,
        'active': true,
        'eligiblePackGrams': [500, 1000, 2000, 10000],
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      db.collection('coupons').doc('MEGA12'),
      {
        'code': 'MEGA12',
        'percentOff': 12,
        'active': true,
        'eligiblePackGrams': [10000],
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    await prefs.setBool(_prefsKeySeeded, true);
    debugPrint('FirestoreTestSeed: completed (products, store, inventory, order, coupon).');
  } on Object catch (e, st) {
    debugPrint('FirestoreTestSeed: FAILED — $e\n$st');
    debugPrint(
      'If permission denied: temporarily allow writes for your test UID in rules, '
      'or sign in before seed runs.',
    );
  }
}

/// Dummy products: [priceMinor] = paise (INR × 100).
List<Map<String, dynamic>> _dummyProducts() {
  return [
    {
      'id': '1',
      'name': 'Fresh Oyster Mushrooms',
      'description': 'Grown locally, ideal for stir-fry and soups.',
      'image_url':
          'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?fm=jpg&fit=crop&w=1200&q=80',
      'variants': [
        {
          'id': '101',
          'label': '200 g',
          'totalGrams': 200,
          'priceMinor': 9000,
          'stock': 48,
          'lowStockThreshold': 10,
        },
        {
          'id': '102',
          'label': '500 g',
          'totalGrams': 500,
          'priceMinor': 20000,
          'stock': 28,
          'lowStockThreshold': 8,
        },
        {
          'id': '103',
          'label': '1 kg',
          'totalGrams': 1000,
          'priceMinor': 38000,
          'stock': 22,
          'lowStockThreshold': 5,
        },
        {
          'id': '104',
          'label': '2 kg',
          'totalGrams': 2000,
          'priceMinor': 72000,
          'stock': 12,
          'lowStockThreshold': 3,
        },
        {
          'id': '105',
          'label': '10 kg',
          'totalGrams': 10000,
          'priceMinor': 320000,
          'stock': 4,
          'lowStockThreshold': 2,
        },
      ],
    },
    {
      'id': '2',
      'name': 'Button Mushrooms',
      'description': 'Versatile white mushrooms for everyday cooking.',
      'image_url':
          'https://images.unsplash.com/photo-1567333506008-8be40c293909?fm=jpg&fit=crop&w=1200&q=80',
      'variants': [
        {
          'id': '201',
          'label': '250 g',
          'totalGrams': 250,
          'priceMinor': 9000,
          'stock': 0,
          'lowStockThreshold': 5,
        },
        {
          'id': '202',
          'label': '500 g',
          'totalGrams': 500,
          'priceMinor': 17000,
          'stock': 34,
          'lowStockThreshold': 8,
        },
      ],
    },
  ];
}

/// Keys: `{productId}_{variantId}` — store-level stock snapshot.
Map<String, Map<String, dynamic>> _dummyStoreInventory(String storeId) {
  return {
    '1_101': {
      'productId': '1',
      'variantId': '101',
      'productName': 'Fresh Oyster Mushrooms',
      'label': '200 g',
      'stock': 48,
      'storeId': storeId,
    },
    '1_102': {
      'productId': '1',
      'variantId': '102',
      'productName': 'Fresh Oyster Mushrooms',
      'label': '500 g',
      'stock': 28,
      'storeId': storeId,
    },
    '1_103': {
      'productId': '1',
      'variantId': '103',
      'productName': 'Fresh Oyster Mushrooms',
      'label': '1 kg',
      'stock': 22,
      'storeId': storeId,
    },
    '1_104': {
      'productId': '1',
      'variantId': '104',
      'productName': 'Fresh Oyster Mushrooms',
      'label': '2 kg',
      'stock': 12,
      'storeId': storeId,
    },
    '1_105': {
      'productId': '1',
      'variantId': '105',
      'productName': 'Fresh Oyster Mushrooms',
      'label': '10 kg',
      'stock': 4,
      'storeId': storeId,
    },
    '2_201': {
      'productId': '2',
      'variantId': '201',
      'productName': 'Button Mushrooms',
      'label': '250 g',
      'stock': 0,
      'storeId': storeId,
    },
  };
}
