/// Bhoomise Storefront — design file reference and screen inventory.
///
/// **Source of truth:** Figma file
/// [Bhoomise](https://www.figma.com/design/kWtQ8RReUVoZ7BoABTOe3q/Bhoomise).
///
/// Live MCP scans (`get_metadata` / `get_design_context`) may be unavailable on
/// rate-limited plans; this module and `assets/mock_api/ui/` mirror the
/// agreed tokens and copy for implementation.
library;

/// Figma file key (URL segment after `/design/`).
const String kFigmaBhoomiseFileKey = 'kWtQ8RReUVoZ7BoABTOe3q';

/// Frames implemented in this app (node ids as in Figma REST / Dev Mode).
abstract final class FigmaFrames {
  /// Customer Home — search, hero, categories, fresh arrivals (`9:3`).
  static const String customerHome = '9:3';

  /// Phone login, role segment, OTP entry, SSO row (`9:675`).
  static const String login = '9:675';
}

/// Primary routes ↔ Figma-aligned surfaces (customer B2C + partner ops).
abstract final class FigmaScreenMap {
  static const List<String> customer = [
    'Login / role selection — node ${FigmaFrames.login}',
    'OTP verification — follows login system',
    'Customer shell — Home · Search · Basket · Profile',
    'Home tab — node ${FigmaFrames.customerHome}',
    'Catalog, product detail, cart',
    'Profile / addresses',
  ];

  static const List<String> partner = [
    'Partner shell — Cultivate · Products · Orders (account via header)',
    'Cultivator Console, Curated Collections (Products), Incoming Harvest Requests (Orders), Add Cultivation',
    'Legacy stock: /store/inventory · legacy B2B orders: /admin/supply-orders',
    'Admin / global supply (where routed)',
  ];
}
