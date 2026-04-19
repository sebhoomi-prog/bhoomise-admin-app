import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

/// Collection [admin_phones] — document ID = Firebase Auth [User.phoneNumber] (E.164, e.g. `+91XXXXXXXXXX`).
/// Create rows in Firebase Console (or Admin SDK); no admin numbers in app source.
const String kFirestoreAdminPhonesCollection = 'admin_phones';

/// Admin if custom claim `admin == true` **or** a document exists at
/// `admin_phones/{currentUser.phoneNumber}`.
Future<bool> isFirebaseUserFirestoreAdmin(firebase_auth.User? user) async {
  if (user == null) return false;
  try {
    await user.reload();
  } on Object catch (_) {}
  final fresh = firebase_auth.FirebaseAuth.instance.currentUser ?? user;
  final token = await fresh.getIdTokenResult(true);
  final claims = token.claims;
  if (claims != null && claims['admin'] == true) return true;

  final phone = fresh.phoneNumber;
  if (phone == null || phone.isEmpty) return false;

  final snap = await FirebaseFirestore.instance
      .collection(kFirestoreAdminPhonesCollection)
      .doc(phone)
      .get();
  final ok = snap.exists;
  if (kDebugMode && !ok) {
    debugPrint(
      'FirestoreAdmin: no doc at $kFirestoreAdminPhonesCollection/$phone '
      '(add this document ID in Console for admin access).',
    );
  }
  return ok;
}
