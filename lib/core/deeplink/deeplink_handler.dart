import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

/// Parses URLs and navigates only — no repositories.
class DeeplinkHandler {
  void handle(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return;

    final path = uri.path.isEmpty ? link : uri.path;

    if (path.contains('product')) {
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      final id = segments.isNotEmpty ? segments.last : uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        Get.toNamed(AppRoutes.productDetail, arguments: id);
      }
    } else if (path.contains('referral')) {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        Get.toNamed(AppRoutes.home, arguments: {'referral': code});
      }
    } else if (path.contains('order')) {
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      final id = segments.isNotEmpty ? segments.last : uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        Get.toNamed(AppRoutes.orderTrack, arguments: id);
      }
    }
  }
}
