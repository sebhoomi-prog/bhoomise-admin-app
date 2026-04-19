import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/session/app_role.dart';
import '../../../../../core/theme/design_tokens.dart';

/// Three-way role: customer · vendor (partner shell) · platform admin.
class FigmaLoginRoleSegmentThree extends StatelessWidget {
  const FigmaLoginRoleSegmentThree({
    super.key,
    required this.track,
    required this.brand,
    required this.textMuted,
    required this.customerLabel,
    required this.vendorLabel,
    required this.adminLabel,
    required this.role,
    required this.onChanged,
  });

  final Color track;
  final Color brand;
  final Color textMuted;
  final String customerLabel;
  final String vendorLabel;
  final String adminLabel;
  final AppRole role;
  final ValueChanged<AppRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FigmaSegChip(
              label: customerLabel,
              selected: role == AppRole.customer,
              brand: brand,
              textMuted: textMuted,
              fontSize: 12,
              onTap: () => onChanged(AppRole.customer),
            ),
          ),
          Expanded(
            child: _FigmaSegChip(
              label: vendorLabel,
              selected: role == AppRole.partner,
              brand: brand,
              textMuted: textMuted,
              fontSize: 12,
              onTap: () => onChanged(AppRole.partner),
            ),
          ),
          Expanded(
            child: _FigmaSegChip(
              label: adminLabel,
              selected: role == AppRole.admin,
              brand: brand,
              textMuted: textMuted,
              fontSize: 12,
              onTap: () => onChanged(AppRole.admin),
            ),
          ),
        ],
      ),
    );
  }
}

/// Role toggle — Figma segmented control on login (`9:675`).
class FigmaLoginRoleSegment extends StatelessWidget {
  const FigmaLoginRoleSegment({
    super.key,
    required this.track,
    required this.brand,
    required this.textMuted,
    required this.customerLabel,
    required this.businessLabel,
    required this.isCustomer,
    required this.onChanged,
  });

  final Color track;
  final Color brand;
  final Color textMuted;
  final String customerLabel;
  final String businessLabel;
  final bool isCustomer;
  final void Function(bool customer) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FigmaSegChip(
              label: customerLabel,
              selected: isCustomer,
              brand: brand,
              textMuted: textMuted,
              fontSize: 14,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _FigmaSegChip(
              label: businessLabel,
              selected: !isCustomer,
              brand: brand,
              textMuted: textMuted,
              fontSize: 14,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaSegChip extends StatelessWidget {
  const _FigmaSegChip({
    required this.label,
    required this.selected,
    required this.brand,
    required this.textMuted,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color brand;
  final Color textMuted;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            vertical: fontSize <= 12 ? 10 : 12,
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? Border.all(
                    color:
                        DesignTokens.figmaAccentLime.withValues(alpha: 0.9),
                    width: 1.5,
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              height: 1.2,
              color: selected ? brand : textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
