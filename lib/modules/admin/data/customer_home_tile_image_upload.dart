import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads category tile raster bytes to Firebase Storage [`customer_home/…`].
/// Matches [storage.rules] `customer_home/{fileName}` — public read, admin write.
class CustomerHomeTileImageUploader {
  CustomerHomeTileImageUploader({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static String extensionForMime(String? mimeType) {
    final m = (mimeType ?? '').toLowerCase();
    if (m.contains('png')) return 'png';
    if (m.contains('webp')) return 'webp';
    return 'jpg';
  }

  static String contentTypeForMime(String? mimeType) {
    final m = (mimeType ?? '').toLowerCase();
    if (m.contains('png')) return 'image/png';
    if (m.contains('webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<String> uploadTileImage({
    required Uint8List bytes,
    required String mimeTypeHint,
    required int tileIndex,
  }) async {
    final ct = contentTypeForMime(mimeTypeHint);
    final ext = extensionForMime(mimeTypeHint);
    final name =
        'tile_${tileIndex}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('customer_home').child(name);
    await ref.putData(bytes, SettableMetadata(contentType: ct));
    return ref.getDownloadURL();
  }
}
