import 'package:flutter/material.dart';

import 'admin_surface.dart';

/// **Vendor / store (retailer)** surfaces — same palette family as
/// [AdminSurface]; UI differentiates with `STORE` badge and retailer-first copy.
abstract final class VendorSurface {
  VendorSurface._();

  static const Color background = AdminSurface.background;
  static const Color headline = AdminSurface.headline;
  static const Color eyebrow = AdminSurface.eyebrow;
  static const Color limeAccent = AdminSurface.limeAccent;
  static const Color darkCard = AdminSurface.darkCard;
  static const Color onDarkMuted = AdminSurface.onDarkMuted;
  static const Color networkCard = AdminSurface.networkCard;
  static const Color border = AdminSurface.border;
}
