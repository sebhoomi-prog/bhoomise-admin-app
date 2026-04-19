import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography aligned with [AppTheme] / Figma strategy (`bhoomise_theme.json`: Plus Jakarta Sans).
///
/// Use on customer surfaces for consistent hierarchy with design tokens.
abstract final class FigmaTypography {
  static TextStyle loginHeadline(Color brand) => GoogleFonts.plusJakartaSans(
        color: brand,
        fontWeight: FontWeight.w800,
        fontSize: 28,
        height: 1.2,
        letterSpacing: -0.75,
      );

  static TextStyle loginSubheadline(Color secondary) =>
      GoogleFonts.plusJakartaSans(
        color: secondary,
        fontWeight: FontWeight.w500,
        fontSize: 16,
        height: 1.5,
      );

  static TextStyle labelCaps(Color color, {double letterSpacing = 1.6}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: letterSpacing,
      );

  static TextStyle bodyStrong(Color color, {double fontSize = 16}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
      );

  static TextStyle bodyBold(Color color, {double fontSize = 16}) =>
      GoogleFonts.plusJakartaSans(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
      );

  static TextStyle cta(Color onGradient) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 24 / 16,
        color: onGradient,
      );

  static TextStyle appBarBrand(Color brand) => GoogleFonts.plusJakartaSans(
        color: brand,
        fontWeight: FontWeight.w800,
        fontSize: 16,
        letterSpacing: -0.35,
        height: 1.15,
      );

  static TextStyle homeTitleLarge(Color green) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.4,
        color: green,
      );

  static TextStyle heroDisplay(Color white) => GoogleFonts.plusJakartaSans(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: white,
      );

  static TextStyle categoryTitle(Color green) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: green,
      );

  static TextStyle sectionOverline(Color muted, {double letterSpacing = 2}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: letterSpacing,
        color: muted,
      );

  static TextStyle legalBody(Color muted) => GoogleFonts.plusJakartaSans(
        color: muted,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.55,
      );

  static TextStyle legalLink(Color brand) => GoogleFonts.plusJakartaSans(
        color: brand,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        height: 1.55,
      );

  static TextStyle vendorAdminLink(Color brand) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: brand,
      );

  /// Search pill placeholder — muted green-gray from Customer Home spec.
  static TextStyle searchHint([Color hint = const Color(0xFF6E7B6C)]) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        color: hint,
      );

  // —— Customer Home (Inter + Manrope per Figma/CSS) ——

  static TextStyle customerDeliverLabel() => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 15 / 10,
        letterSpacing: 1,
        color: const Color(0xFF64748B),
      );

  static TextStyle customerDeliverCity(Color green) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 22 / 18,
        color: green,
      );

  /// Center brand — Manrope 20 / 28, −0.5 tracking.
  static TextStyle customerBrandMark(Color green) => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 28 / 20,
        letterSpacing: -0.5,
        color: green,
      );

  static TextStyle customerSectionH3(Color ink) => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 32 / 24,
        letterSpacing: -0.6,
        color: ink,
      );

  static TextStyle customerViewAllLink() => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: const Color(0xFF006B2C),
      );

  static TextStyle heroBadgeLime() => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 15 / 10,
        letterSpacing: 2,
        color: const Color(0xFF7FFC97),
      );

  static TextStyle heroHeadlineWhite() => GoogleFonts.manrope(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 38 / 30,
        color: Colors.white,
      );

  static TextStyle heroShopNow() => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 16 / 12,
        color: Colors.white,
      );

  static TextStyle categoryNameFigma(Color green) => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 28 / 18,
        color: green,
      );

  static TextStyle categorySubtitleFigma() => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        letterSpacing: 0.3,
        color: const Color(0xFF64748B),
      );

  static TextStyle productOverline() => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 15 / 10,
        letterSpacing: 1,
        color: const Color(0xFF64748B),
      );

  static TextStyle productTitleFigma(Color ink) => GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 28 / 18,
        color: ink,
      );

  static TextStyle productMetaFigma() => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: const Color(0xFF5D5D4E),
      );

  static TextStyle productPriceFigma(Color green) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 28 / 20,
        color: green,
      );
}
