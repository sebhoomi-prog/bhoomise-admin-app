import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../storage/local_storage.dart';

/// Listens for network changes; when the device is online, flushes pending local data
/// (e.g. cart) toward the remote API when configured.
class ConnectivitySyncService extends GetxService {
  ConnectivitySyncService(this._local);

  final LocalStorage _local;
  final Connectivity _connectivity = Connectivity();

  /// Reactive — use for offline banners (e.g. [connectivity_plus]).
  final RxBool isOnline = true.obs;

  static bool _online(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void onInit() {
    super.onInit();
    _connectivity.onConnectivityChanged.listen(_onConnectivity);
    _bootstrap();
  }

  void _bootstrap() {
    _connectivity.checkConnectivity().then(_onConnectivity);
  }

  Future<void> _onConnectivity(List<ConnectivityResult> results) async {
    isOnline.value = _online(results);
    if (!isOnline.value) return;
    await _local.flushCartRemoteIfNeeded();
  }
}
