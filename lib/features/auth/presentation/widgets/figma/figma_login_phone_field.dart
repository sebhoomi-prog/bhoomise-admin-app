import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/design_tokens.dart';

/// Phone row with dial code — Figma login (`9:675`).
class FigmaLoginPhoneField extends StatelessWidget {
  const FigmaLoginPhoneField({
    super.key,
    required this.dialCode,
    required this.onDialChanged,
    required this.controller,
    required this.placeholder,
    required this.borderColor,
    required this.brand,
  });

  final String dialCode;
  final ValueChanged<String> onDialChanged;
  final TextEditingController controller;
  final String placeholder;
  final Color borderColor;
  final Color brand;

  static final _placeholderColor =
      const Color(0xFF707975).withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: DesignTokens.figmaSearchBarFill.withValues(alpha: 0.95),
        ),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: borderColor.withValues(alpha: 0.3)),
              ),
            ),
            padding: const EdgeInsets.only(left: 5, right: 9),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: dialCode,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: brand,
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: brand,
                ),
                items: const [
                  DropdownMenuItem(value: '+1', child: Text('+1')),
                  DropdownMenuItem(value: '+91', child: Text('+91')),
                ],
                onChanged: (v) {
                  if (v != null) onDialChanged(v);
                },
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: brand,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: _placeholderColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              ),
              validator: (v) {
                final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (d.length != 10) return 'Enter a valid 10-digit number';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
