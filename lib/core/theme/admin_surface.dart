import 'package:flutter/material.dart';

/// Admin / partner ops surfaces (see `global_supply_dashboard.json` + Hub).
abstract final class AdminSurface {
  AdminSurface._();

  static const Color background = Color(0xFFF5FBF5);
  static const Color headline = Color(0xFF012D1D);
  static const Color eyebrow = Color(0xFF855232);
  static const Color networkCard = Color(0xFFEAEFE9);
  static const Color limeAccent = Color(0xFFC6F24B);
  static const Color darkCard = Color(0xFF1B4332);
  static const Color darkGreenText = Color(0xFF1E2A00);
  static const Color onDarkMuted = Color(0xFFC1ECD0);
  static const Color border = Color(0xFFE0E8E4);

  /// Horizontal padding + bottom inset above role bottom nav.
  static EdgeInsets pagePadding(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(20, 12, 20, 88 + bottom);
  }

  static EdgeInsets pagePaddingList(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.fromLTRB(20, 8, 20, 88 + bottom);
  }
}
