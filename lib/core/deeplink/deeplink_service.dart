import 'deeplink_handler.dart';

/// Listens for incoming links (mobile: add `uni_links` / `app_links` when needed).
class DeeplinkService {
  DeeplinkService(this._handler);

  final DeeplinkHandler _handler;

  void init() {
    // Wire platform stream here when deep-link packages are added.
  }

  void handleIncoming(String link) => _handler.handle(link);
}
