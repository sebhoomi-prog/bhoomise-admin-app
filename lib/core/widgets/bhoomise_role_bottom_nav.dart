import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/design_tokens.dart';

/// Frosted bottom bar — Figma Customer Home: mint active pill, slate inactive.
///
/// Set [partnerFigmaStyle] for **Cultivator Console** vendor nav: solid green
/// active pill (`#00873A`), warm inactive ink (`#5D5D4E`), stronger top radius.
class BhoomiseRoleBottomNav extends StatelessWidget {
  const BhoomiseRoleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.partnerFigmaStyle = false,
    /// List Your Harvest vendor nav: stronger blur, slate inactive ink, mint pill + dark green labels.
    this.vendorHarvestMintNav = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BhoomiseBottomNavItem> items;
  final bool partnerFigmaStyle;
  final bool vendorHarvestMintNav;

  static const _active = DesignTokens.figmaDeliverGreen;
  static const _inactive = DesignTokens.figmaNavInactive;
  static const _partnerActiveGreen = DesignTokens.figmaHeroCtaGreenAlt;
  static const _partnerInactive = Color(0xFF5D5D4E);
  static const _harvestInactive = Color(0xFF71717A);
  static const _harvestActivePill = Color(0xFFDCFCE7);
  static const _harvestActiveInk = Color(0xFF14532D);

  @override
  Widget build(BuildContext context) {
    final topRadius = partnerFigmaStyle ? 48.0 : 24.0;
    final blur = vendorHarvestMintNav ? 20.0 : 12.0;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: partnerFigmaStyle
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.7),
            border: partnerFigmaStyle
                ? Border(
                    top: BorderSide(
                      color: const Color(0xFFE2E8F0).withValues(alpha: 0.15),
                    ),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: partnerFigmaStyle
                    ? const Color(0xFF121C2A).withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: partnerFigmaStyle ? 32 : 30,
                offset: Offset(0, partnerFigmaStyle ? -12 : -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: partnerFigmaStyle
                  ? const EdgeInsets.fromLTRB(12, 11, 12, 24)
                  : const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(
                children: List.generate(items.length, (i) {
                  final it = items[i];
                  /// \`currentIndex == -1\` → no active tab (e.g. vendor Profile stack).
                  final selected = currentIndex >= 0 && i == currentIndex;
                  final usePartner = partnerFigmaStyle;
                  final harvestMint = usePartner && vendorHarvestMintNav;
                  // Partner: icon inverts on the green pill. Customer: icon glyph stays one
                  // steady color — selection reads from pill + label only (professional tab bars).
                  final labelFg = harvestMint
                      ? (selected ? _harvestActiveInk : _harvestInactive)
                      : usePartner
                          ? (selected ? Colors.white : _partnerInactive)
                          : (selected ? _active : _inactive);
                  final iconFg = harvestMint
                      ? (selected ? _harvestActiveInk : _harvestInactive)
                      : usePartner
                          ? (selected ? Colors.white : _partnerInactive)
                          : _inactive;
                  final pillBg = harvestMint
                      ? (selected ? _harvestActivePill : Colors.transparent)
                      : usePartner
                          ? (selected ? _partnerActiveGreen : Colors.transparent)
                          : (selected
                              ? DesignTokens.figmaNavActiveMint
                              : Colors.transparent);
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(9999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: pillBg,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Badge(
                              isLabelVisible:
                                  (it.badgeCount ?? 0) > 0 && !usePartner,
                              label: Text(
                                '${it.badgeCount ?? 0}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: _active,
                              child: Icon(it.icon, size: 18, color: iconFg),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              harvestMint ? it.label : it.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: harvestMint ? 11 : 10,
                                fontWeight:
                                    harvestMint ? FontWeight.w500 : FontWeight.w700,
                                height: harvestMint ? 16 / 11 : 15 / 10,
                                letterSpacing: harvestMint ? 0.275 : 1,
                                color: labelFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BhoomiseBottomNavItem {
  const BhoomiseBottomNavItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final String label;

  /// Total units in cart for this tab (e.g. bag tab). Omit when zero.
  final int? badgeCount;
}
