import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared Firestore gateway for app-level documents (`app/{docId}`).
class SharedAppFirestoreRepository {
  SharedAppFirestoreRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> appDoc(String docId) =>
      _db.collection('app').doc(docId);
}
