import 'package:hive_flutter/hive_flutter.dart';

import '../../config/backend_config.dart';
import '../../modules/admin/data/cart_line.dart';

/// Hive-backed local persistence: cart lines + dirty flag for remote sync.
///
/// [SharedPreferences] remains for auth/session keys; structured data lives here.
class LocalStorage {
  LocalStorage(this._box);

  final Box<dynamic> _box;

  static const _cartKey = 'cart_lines_v1';
  static const _cartDirtyKey = 'cart_needs_remote_sync_v1';

  Future<List<CartLine>> loadCart() async {
    final raw = _box.get(_cartKey);
    if (raw is! List) return [];
    final out = <CartLine>[];
    for (final e in raw) {
      if (e is Map) {
        try {
          out.add(CartLine.fromJson(Map<String, dynamic>.from(e)));
        } on Object {
          continue;
        }
      }
    }
    return out;
  }

  Future<void> saveCart(List<CartLine> lines) async {
    await _box.put(
      _cartKey,
      lines.map((e) => e.toJson()).toList(growable: false),
    );
    await _box.put(_cartDirtyKey, true);
  }

  bool get cartNeedsRemoteSync =>
      _box.get(_cartDirtyKey, defaultValue: false) == true;

  Future<void> markCartRemoteSynced() async {
    await _box.put(_cartDirtyKey, false);
  }

  /// When online and REST is configured, push local cart; otherwise mark clean.
  Future<void> flushCartRemoteIfNeeded() async {
    if (!cartNeedsRemoteSync) return;
    if (BackendConfig.hasRestApi) {
      // Wire to [ApiClient] + `POST /cart` when the server contract exists.
    }
    await markCartRemoteSynced();
  }
}
